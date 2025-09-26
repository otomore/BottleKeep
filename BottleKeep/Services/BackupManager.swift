import Foundation
import CloudKit

/// バックアップ・復元を管理するサービス
class BackupManager: ObservableObject {

    static let shared = BackupManager()

    private let dataExportImportManager = DataExportImportManager.shared
    private let fileManager = FileManager.default

    private init() {}

    // MARK: - Backup Types

    enum BackupDestination {
        case iCloudDrive
        case localDocuments
        case files // iOS Files app
    }

    enum BackupType {
        case full
        case bottlesOnly
        case wishlistOnly
        case photos
    }

    // MARK: - Backup Operations

    /// 自動バックアップを作成
    func createAutomaticBackup() async throws -> URL {
        let backupData = try await gatherBackupData()
        let fileName = "auto_backup_\(dateFormatter.string(from: Date())).backup"

        return try await saveBackupData(backupData, fileName: fileName, destination: .iCloudDrive)
    }

    /// 手動バックアップを作成
    func createManualBackup(type: BackupType, destination: BackupDestination) async throws -> URL {
        let backupData: BackupData
        let fileName: String

        switch type {
        case .full:
            backupData = try await gatherBackupData()
            fileName = "full_backup_\(dateFormatter.string(from: Date())).backup"
        case .bottlesOnly:
            backupData = try await gatherBottlesBackup()
            fileName = "bottles_backup_\(dateFormatter.string(from: Date())).backup"
        case .wishlistOnly:
            backupData = try await gatherWishlistBackup()
            fileName = "wishlist_backup_\(dateFormatter.string(from: Date())).backup"
        case .photos:
            backupData = try await gatherPhotosBackup()
            fileName = "photos_backup_\(dateFormatter.string(from: Date())).backup"
        }

        return try await saveBackupData(backupData, fileName: fileName, destination: destination)
    }

    /// バックアップから復元
    func restoreFromBackup(url: URL) async throws -> RestoreResult {
        let backupData = try await loadBackupData(from: url)

        var restoredItems = 0
        var errors: [String] = []

        // ボトルデータの復元
        for bottleData in backupData.bottles {
            do {
                _ = try await createBottleFromBackup(data: bottleData)
                restoredItems += 1
            } catch {
                errors.append("ボトル '\(bottleData.name)': \(error.localizedDescription)")
            }
        }

        // ウィッシュリストデータの復元
        for wishlistData in backupData.wishlistItems {
            do {
                _ = try await createWishlistItemFromBackup(data: wishlistData)
                restoredItems += 1
            } catch {
                errors.append("ウィッシュリスト '\(wishlistData.name)': \(error.localizedDescription)")
            }
        }

        // 写真データの復元
        for photoData in backupData.photos {
            do {
                try await restorePhoto(data: photoData)
                restoredItems += 1
            } catch {
                errors.append("写真 '\(photoData.fileName)': \(error.localizedDescription)")
            }
        }

        return RestoreResult(
            restoredItems: restoredItems,
            errors: errors,
            backupInfo: backupData.metadata
        )
    }

    /// 利用可能なバックアップファイルを取得
    func getAvailableBackups(from destination: BackupDestination) async throws -> [BackupInfo] {
        let backupDirectory = try getBackupDirectory(for: destination)

        guard fileManager.fileExists(atPath: backupDirectory.path) else {
            return []
        }

        let backupFiles = try fileManager.contentsOfDirectory(at: backupDirectory,
                                                            includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey])
            .filter { $0.pathExtension == "backup" }

        var backupInfos: [BackupInfo] = []

        for fileURL in backupFiles {
            do {
                let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
                let modificationDate = attributes[.modificationDate] as? Date ?? Date()
                let fileSize = attributes[.size] as? Int64 ?? 0

                // バックアップファイルのメタデータを読み取り
                let backupData = try await loadBackupData(from: fileURL)

                backupInfos.append(BackupInfo(
                    url: fileURL,
                    name: fileURL.lastPathComponent,
                    createdDate: backupData.metadata.createdDate,
                    modificationDate: modificationDate,
                    fileSize: fileSize,
                    itemCount: backupData.metadata.totalItems,
                    backupType: determineBackupType(from: backupData)
                ))
            } catch {
                // エラーのあるバックアップファイルはスキップ
                continue
            }
        }

        return backupInfos.sorted { $0.createdDate > $1.createdDate }
    }

    /// バックアップファイルを削除
    func deleteBackup(info: BackupInfo) throws {
        try fileManager.removeItem(at: info.url)
    }

    // MARK: - Automatic Backup

    /// 自動バックアップの設定を確認
    func shouldCreateAutomaticBackup() -> Bool {
        let lastBackupDate = UserDefaults.standard.object(forKey: "lastAutomaticBackup") as? Date
        let backupInterval: TimeInterval = 7 * 24 * 60 * 60 // 7日間

        guard let lastDate = lastBackupDate else { return true }
        return Date().timeIntervalSince(lastDate) > backupInterval
    }

    /// 自動バックアップの実行
    func performAutomaticBackupIfNeeded() async {
        guard shouldCreateAutomaticBackup() else { return }

        do {
            _ = try await createAutomaticBackup()
            UserDefaults.standard.set(Date(), forKey: "lastAutomaticBackup")
        } catch {
            print("自動バックアップに失敗: \(error)")
        }
    }

    // MARK: - Private Methods

    private func gatherBackupData() async throws -> BackupData {
        let bottles = try await dataExportImportManager.bottleRepository.fetchAllBottles()
        let wishlistItems = try await dataExportImportManager.wishlistRepository.fetchAllWishlistItems()
        let photos = try await gatherPhotoData()

        return BackupData(
            bottles: bottles.map { BottleBackupData(from: $0) },
            wishlistItems: wishlistItems.map { WishlistItemBackupData(from: $0) },
            photos: photos,
            metadata: BackupMetadata(
                createdDate: Date(),
                version: "1.0",
                appVersion: "1.0.0",
                totalItems: bottles.count + wishlistItems.count + photos.count
            )
        )
    }

    private func gatherBottlesBackup() async throws -> BackupData {
        let bottles = try await dataExportImportManager.bottleRepository.fetchAllBottles()

        return BackupData(
            bottles: bottles.map { BottleBackupData(from: $0) },
            wishlistItems: [],
            photos: [],
            metadata: BackupMetadata(
                createdDate: Date(),
                version: "1.0",
                appVersion: "1.0.0",
                totalItems: bottles.count
            )
        )
    }

    private func gatherWishlistBackup() async throws -> BackupData {
        let wishlistItems = try await dataExportImportManager.wishlistRepository.fetchAllWishlistItems()

        return BackupData(
            bottles: [],
            wishlistItems: wishlistItems.map { WishlistItemBackupData(from: $0) },
            photos: [],
            metadata: BackupMetadata(
                createdDate: Date(),
                version: "1.0",
                appVersion: "1.0.0",
                totalItems: wishlistItems.count
            )
        )
    }

    private func gatherPhotosBackup() async throws -> BackupData {
        let photos = try await gatherPhotoData()

        return BackupData(
            bottles: [],
            wishlistItems: [],
            photos: photos,
            metadata: BackupMetadata(
                createdDate: Date(),
                version: "1.0",
                appVersion: "1.0.0",
                totalItems: photos.count
            )
        )
    }

    private func gatherPhotoData() async throws -> [PhotoBackupData] {
        // PhotoManagerから写真データを取得する実装
        // 実際の実装では写真ファイルをBase64エンコードするなど
        return [] // 簡略化
    }

    private func saveBackupData(_ backupData: BackupData, fileName: String, destination: BackupDestination) async throws -> URL {
        let jsonData = try JSONEncoder().encode(backupData)
        let backupDirectory = try getBackupDirectory(for: destination)

        // ディレクトリが存在しない場合は作成
        try fileManager.createDirectory(at: backupDirectory, withIntermediateDirectories: true)

        let fileURL = backupDirectory.appendingPathComponent(fileName)
        try jsonData.write(to: fileURL)

        return fileURL
    }

    private func loadBackupData(from url: URL) async throws -> BackupData {
        let jsonData = try Data(contentsOf: url)
        return try JSONDecoder().decode(BackupData.self, from: jsonData)
    }

    private func getBackupDirectory(for destination: BackupDestination) throws -> URL {
        switch destination {
        case .iCloudDrive:
            guard let iCloudURL = fileManager.url(forUbiquityContainerIdentifier: nil) else {
                throw BackupError.iCloudUnavailable
            }
            return iCloudURL.appendingPathComponent("Documents/BottleKeepBackups")

        case .localDocuments:
            let documentsURL = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            return documentsURL.appendingPathComponent("BottleKeepBackups")

        case .files:
            let documentsURL = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            return documentsURL.appendingPathComponent("BottleKeepBackups")
        }
    }

    private func createBottleFromBackup(data: BottleBackupData) async throws -> Bottle {
        let repository = dataExportImportManager.bottleRepository
        let bottle = try await repository.createBottle(name: data.name, distillery: data.distillery)

        // バックアップデータから復元
        bottle.region = data.region
        bottle.type = data.type
        bottle.abv = data.abv
        bottle.volume = data.volume
        bottle.remainingVolume = data.remainingVolume
        bottle.vintage = data.vintage
        bottle.purchasePrice = data.purchasePrice.map { NSDecimalNumber(decimal: $0) }
        bottle.purchaseDate = data.purchaseDate
        bottle.shop = data.shop
        bottle.openedDate = data.openedDate
        bottle.rating = data.rating
        bottle.notes = data.notes

        try await repository.saveBottle(bottle)
        return bottle
    }

    private func createWishlistItemFromBackup(data: WishlistItemBackupData) async throws -> WishlistItem {
        let repository = dataExportImportManager.wishlistRepository
        let item = try await repository.createWishlistItem(name: data.name, distillery: data.distillery)

        // バックアップデータから復元
        item.region = data.region
        item.type = data.type
        item.vintage = data.vintage
        item.estimatedPrice = data.estimatedPrice.map { NSDecimalNumber(decimal: $0) }
        item.priority = data.priority
        item.notes = data.notes

        try await repository.saveWishlistItem(item)
        return item
    }

    private func restorePhoto(data: PhotoBackupData) async throws {
        // 写真の復元処理
        // 実際の実装では写真ファイルをデコードして保存
    }

    private func determineBackupType(from backupData: BackupData) -> BackupType {
        let hasBottles = !backupData.bottles.isEmpty
        let hasWishlist = !backupData.wishlistItems.isEmpty
        let hasPhotos = !backupData.photos.isEmpty

        if hasBottles && hasWishlist && hasPhotos {
            return .full
        } else if hasBottles && !hasWishlist {
            return .bottlesOnly
        } else if !hasBottles && hasWishlist {
            return .wishlistOnly
        } else if hasPhotos {
            return .photos
        } else {
            return .full
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter
    }
}

// MARK: - Supporting Types

struct BackupData: Codable {
    let bottles: [BottleBackupData]
    let wishlistItems: [WishlistItemBackupData]
    let photos: [PhotoBackupData]
    let metadata: BackupMetadata
}

struct BackupMetadata: Codable {
    let createdDate: Date
    let version: String
    let appVersion: String
    let totalItems: Int
}

struct BottleBackupData: Codable {
    let name: String
    let distillery: String
    let region: String?
    let type: String?
    let abv: Double
    let volume: Int32
    let remainingVolume: Int32
    let vintage: Int32
    let purchasePrice: Decimal?
    let purchaseDate: Date?
    let shop: String?
    let openedDate: Date?
    let rating: Int16
    let notes: String?
    let createdAt: Date
    let updatedAt: Date

    init(from bottle: Bottle) {
        self.name = bottle.name
        self.distillery = bottle.distillery
        self.region = bottle.region
        self.type = bottle.type
        self.abv = bottle.abv
        self.volume = bottle.volume
        self.remainingVolume = bottle.remainingVolume
        self.vintage = bottle.vintage
        self.purchasePrice = bottle.purchasePrice?.decimalValue
        self.purchaseDate = bottle.purchaseDate
        self.shop = bottle.shop
        self.openedDate = bottle.openedDate
        self.rating = bottle.rating
        self.notes = bottle.notes
        self.createdAt = bottle.createdAt
        self.updatedAt = bottle.updatedAt
    }
}

struct WishlistItemBackupData: Codable {
    let name: String
    let distillery: String
    let region: String?
    let type: String?
    let vintage: Int32
    let estimatedPrice: Decimal?
    let priority: Int16
    let notes: String?
    let createdAt: Date
    let updatedAt: Date

    init(from item: WishlistItem) {
        self.name = item.name
        self.distillery = item.distillery
        self.region = item.region
        self.type = item.type
        self.vintage = item.vintage
        self.estimatedPrice = item.estimatedPrice?.decimalValue
        self.priority = item.priority
        self.notes = item.notes
        self.createdAt = item.createdAt
        self.updatedAt = item.updatedAt
    }
}

struct PhotoBackupData: Codable {
    let fileName: String
    let imageData: String // Base64エンコードされた画像データ
    let isMain: Bool
    let createdDate: Date
}

struct BackupInfo {
    let url: URL
    let name: String
    let createdDate: Date
    let modificationDate: Date
    let fileSize: Int64
    let itemCount: Int
    let backupType: BackupManager.BackupType

    var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }

    var formattedCreatedDate: String {
        DateFormatter.localizedString(from: createdDate, dateStyle: .medium, timeStyle: .short)
    }
}

struct RestoreResult {
    let restoredItems: Int
    let errors: [String]
    let backupInfo: BackupMetadata

    var isSuccess: Bool {
        return errors.isEmpty
    }

    var summary: String {
        if isSuccess {
            return "\(restoredItems)件のアイテムを復元しました"
        } else {
            return "\(restoredItems)件復元、\(errors.count)件エラー"
        }
    }
}

enum BackupError: LocalizedError {
    case iCloudUnavailable
    case backupFailed(String)
    case restoreFailed(String)
    case invalidBackupFile

    var errorDescription: String? {
        switch self {
        case .iCloudUnavailable:
            return "iCloudが利用できません"
        case .backupFailed(let message):
            return "バックアップに失敗: \(message)"
        case .restoreFailed(let message):
            return "復元に失敗: \(message)"
        case .invalidBackupFile:
            return "無効なバックアップファイルです"
        }
    }
}