import Foundation
import CoreData
import UniformTypeIdentifiers

/// データのエクスポート・インポートを管理するサービス
class DataExportImportManager: ObservableObject {

    static let shared = DataExportImportManager()

    private let coreDataManager: CoreDataManager
    private let bottleRepository: BottleRepositoryProtocol
    private let wishlistRepository: WishlistRepositoryProtocol

    private init() {
        self.coreDataManager = CoreDataManager.shared
        self.bottleRepository = BottleRepository()
        self.wishlistRepository = WishlistRepository()
    }

    // MARK: - Export Functions

    /// ボトルデータをCSV形式でエクスポート
    func exportBottlesToCSV() async throws -> URL {
        let bottles = try await bottleRepository.fetchAllBottles()
        let csvData = generateBottleCSV(bottles: bottles)

        let fileName = "bottles_export_\(dateFormatter.string(from: Date())).csv"
        let url = try saveToDocuments(data: csvData, fileName: fileName)

        return url
    }

    /// ウィッシュリストをCSV形式でエクスポート
    func exportWishlistToCSV() async throws -> URL {
        let items = try await wishlistRepository.fetchAllWishlistItems()
        let csvData = generateWishlistCSV(items: items)

        let fileName = "wishlist_export_\(dateFormatter.string(from: Date())).csv"
        let url = try saveToDocuments(data: csvData, fileName: fileName)

        return url
    }

    /// 全データをJSON形式でエクスポート
    func exportAllDataToJSON() async throws -> URL {
        let bottles = try await bottleRepository.fetchAllBottles()
        let wishlistItems = try await wishlistRepository.fetchAllWishlistItems()

        let exportData = ExportData(
            bottles: bottles.map { BottleExportModel(from: $0) },
            wishlistItems: wishlistItems.map { WishlistItemExportModel(from: $0) },
            exportDate: Date(),
            version: "1.0"
        )

        let jsonData = try JSONEncoder().encode(exportData)
        let fileName = "bottlekeep_backup_\(dateFormatter.string(from: Date())).json"
        let url = try saveToDocuments(data: jsonData, fileName: fileName)

        return url
    }

    // MARK: - Import Functions

    /// CSV形式でボトルデータをインポート
    func importBottlesFromCSV(url: URL) async throws -> ImportResult {
        let csvContent = try String(contentsOf: url)
        let bottles = try parseBottleCSV(csvContent: csvContent)

        var successCount = 0
        var errorCount = 0
        var errors: [String] = []

        for bottleData in bottles {
            do {
                _ = try await createBottleFromImport(data: bottleData)
                successCount += 1
            } catch {
                errorCount += 1
                errors.append("行\(bottleData.lineNumber): \(error.localizedDescription)")
            }
        }

        return ImportResult(
            successCount: successCount,
            errorCount: errorCount,
            errors: errors
        )
    }

    /// JSON形式で全データをインポート
    func importDataFromJSON(url: URL) async throws -> ImportResult {
        let jsonData = try Data(contentsOf: url)
        let exportData = try JSONDecoder().decode(ExportData.self, from: jsonData)

        var successCount = 0
        var errorCount = 0
        var errors: [String] = []

        // ボトルデータのインポート
        for bottleData in exportData.bottles {
            do {
                _ = try await createBottleFromExportModel(model: bottleData)
                successCount += 1
            } catch {
                errorCount += 1
                errors.append("ボトル \(bottleData.name): \(error.localizedDescription)")
            }
        }

        // ウィッシュリストデータのインポート
        for wishlistData in exportData.wishlistItems {
            do {
                _ = try await createWishlistItemFromExportModel(model: wishlistData)
                successCount += 1
            } catch {
                errorCount += 1
                errors.append("ウィッシュリスト \(wishlistData.name): \(error.localizedDescription)")
            }
        }

        return ImportResult(
            successCount: successCount,
            errorCount: errorCount,
            errors: errors
        )
    }

    // MARK: - Private Helper Methods

    private func generateBottleCSV(bottles: [Bottle]) -> Data {
        var csvContent = "名前,蒸留所,地域,タイプ,ABV,容量,残量,ヴィンテージ,購入価格,購入日,購入店,開栓日,評価,メモ,作成日,更新日\n"

        for bottle in bottles {
            let row = [
                bottle.name,
                bottle.distillery,
                bottle.region ?? "",
                bottle.type ?? "",
                "\(bottle.abv)",
                "\(bottle.volume)",
                "\(bottle.remainingVolume)",
                bottle.vintage > 0 ? "\(bottle.vintage)" : "",
                bottle.purchasePrice?.stringValue ?? "",
                bottle.purchaseDate?.ISO8601Format() ?? "",
                bottle.shop ?? "",
                bottle.openedDate?.ISO8601Format() ?? "",
                bottle.rating > 0 ? "\(bottle.rating)" : "",
                bottle.notes ?? "",
                bottle.createdAt.ISO8601Format(),
                bottle.updatedAt.ISO8601Format()
            ].map { csvEscape($0) }.joined(separator: ",")

            csvContent += row + "\n"
        }

        return csvContent.data(using: .utf8) ?? Data()
    }

    private func generateWishlistCSV(items: [WishlistItem]) -> Data {
        var csvContent = "名前,蒸留所,地域,タイプ,ヴィンテージ,推定価格,優先度,メモ,作成日,更新日\n"

        for item in items {
            let row = [
                item.name,
                item.distillery,
                item.region ?? "",
                item.type ?? "",
                item.vintage > 0 ? "\(item.vintage)" : "",
                item.estimatedPrice?.stringValue ?? "",
                "\(item.priority)",
                item.notes ?? "",
                item.createdAt.ISO8601Format(),
                item.updatedAt.ISO8601Format()
            ].map { csvEscape($0) }.joined(separator: ",")

            csvContent += row + "\n"
        }

        return csvContent.data(using: .utf8) ?? Data()
    }

    private func parseBottleCSV(csvContent: String) throws -> [BottleImportData] {
        let lines = csvContent.components(separatedBy: .newlines)
        guard lines.count > 1 else {
            throw DataImportError.invalidFormat("CSVファイルが空です")
        }

        var bottles: [BottleImportData] = []

        for (index, line) in lines.dropFirst().enumerated() {
            if line.trimmingCharacters(in: .whitespaces).isEmpty { continue }

            let fields = parseCSVLine(line: line)
            guard fields.count >= 16 else {
                throw DataImportError.invalidFormat("行\(index + 2): フィールド数が不正です")
            }

            bottles.append(BottleImportData(
                lineNumber: index + 2,
                name: fields[0],
                distillery: fields[1],
                region: fields[2].isEmpty ? nil : fields[2],
                type: fields[3].isEmpty ? nil : fields[3],
                abv: Double(fields[4]) ?? 0.0,
                volume: Int32(fields[5]) ?? 0,
                remainingVolume: Int32(fields[6]) ?? 0,
                vintage: Int32(fields[7]) ?? 0,
                purchasePrice: fields[8].isEmpty ? nil : NSDecimalNumber(string: fields[8]),
                purchaseDate: ISO8601DateFormatter().date(from: fields[9]),
                shop: fields[10].isEmpty ? nil : fields[10],
                openedDate: ISO8601DateFormatter().date(from: fields[11]),
                rating: Int16(fields[12]) ?? 0,
                notes: fields[13].isEmpty ? nil : fields[13]
            ))
        }

        return bottles
    }

    private func parseCSVLine(line: String) -> [String] {
        var fields: [String] = []
        var currentField = ""
        var inQuotes = false
        var i = line.startIndex

        while i < line.endIndex {
            let char = line[i]

            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                fields.append(currentField)
                currentField = ""
            } else {
                currentField.append(char)
            }

            i = line.index(after: i)
        }

        fields.append(currentField)
        return fields
    }

    private func createBottleFromImport(data: BottleImportData) async throws -> Bottle {
        guard !data.name.isEmpty && !data.distillery.isEmpty else {
            throw DataImportError.invalidData("名前と蒸留所名は必須です")
        }

        let bottle = try await bottleRepository.createBottle(name: data.name, distillery: data.distillery)

        bottle.region = data.region
        bottle.type = data.type
        bottle.abv = data.abv
        bottle.volume = data.volume
        bottle.remainingVolume = data.remainingVolume
        bottle.vintage = data.vintage
        bottle.purchasePrice = data.purchasePrice
        bottle.purchaseDate = data.purchaseDate
        bottle.shop = data.shop
        bottle.openedDate = data.openedDate
        bottle.rating = data.rating
        bottle.notes = data.notes

        try await bottleRepository.saveBottle(bottle)
        return bottle
    }

    private func createBottleFromExportModel(model: BottleExportModel) async throws -> Bottle {
        let bottle = try await bottleRepository.createBottle(name: model.name, distillery: model.distillery)

        bottle.region = model.region
        bottle.type = model.type
        bottle.abv = model.abv
        bottle.volume = model.volume
        bottle.remainingVolume = model.remainingVolume
        bottle.vintage = model.vintage
        bottle.purchasePrice = model.purchasePrice.map { NSDecimalNumber(decimal: $0) }
        bottle.purchaseDate = model.purchaseDate
        bottle.shop = model.shop
        bottle.openedDate = model.openedDate
        bottle.rating = model.rating
        bottle.notes = model.notes

        try await bottleRepository.saveBottle(bottle)
        return bottle
    }

    private func createWishlistItemFromExportModel(model: WishlistItemExportModel) async throws -> WishlistItem {
        let item = try await wishlistRepository.createWishlistItem(name: model.name, distillery: model.distillery)

        item.region = model.region
        item.type = model.type
        item.vintage = model.vintage
        item.estimatedPrice = model.estimatedPrice.map { NSDecimalNumber(decimal: $0) }
        item.priority = model.priority
        item.notes = model.notes

        try await wishlistRepository.saveWishlistItem(item)
        return item
    }

    private func csvEscape(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return field
    }

    private func saveToDocuments(data: Data, fileName: String) throws -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(fileName)
        try data.write(to: fileURL)
        return fileURL
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter
    }
}

// MARK: - Supporting Types

struct ImportResult {
    let successCount: Int
    let errorCount: Int
    let errors: [String]

    var isSuccess: Bool {
        return errorCount == 0
    }

    var summary: String {
        if isSuccess {
            return "\(successCount)件のデータを正常にインポートしました"
        } else {
            return "\(successCount)件成功、\(errorCount)件失敗"
        }
    }
}

struct ExportData: Codable {
    let bottles: [BottleExportModel]
    let wishlistItems: [WishlistItemExportModel]
    let exportDate: Date
    let version: String
}

struct BottleExportModel: Codable {
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

struct WishlistItemExportModel: Codable {
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

struct BottleImportData {
    let lineNumber: Int
    let name: String
    let distillery: String
    let region: String?
    let type: String?
    let abv: Double
    let volume: Int32
    let remainingVolume: Int32
    let vintage: Int32
    let purchasePrice: NSDecimalNumber?
    let purchaseDate: Date?
    let shop: String?
    let openedDate: Date?
    let rating: Int16
    let notes: String?
}

enum DataImportError: LocalizedError {
    case invalidFormat(String)
    case invalidData(String)
    case fileNotFound

    var errorDescription: String? {
        switch self {
        case .invalidFormat(let message):
            return "形式エラー: \(message)"
        case .invalidData(let message):
            return "データエラー: \(message)"
        case .fileNotFound:
            return "ファイルが見つかりません"
        }
    }
}