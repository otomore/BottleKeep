import Foundation
import CoreData
import CloudKit
import os.log

/// Core Data スタックとCloudKit統合を管理するシングルトンクラス
class CoreDataManager: ObservableObject {

    static let shared = CoreDataManager()

    private let logger = Logger(subsystem: "com.bottlekeep.app", category: "CoreData")

    // MARK: - Core Data Stack

    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "BottleKeep")

        // CloudKit設定
        let description = container.persistentStoreDescriptions.first!
        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: "iCloud.com.bottlekeep.app"
        )

        // リモート通知設定
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                self.logger.error("Core Data error: \(error), \(error.userInfo)")
                fatalError("Core Data error: \(error), \(error.userInfo)")
            }

            self.logger.info("Core Data store loaded successfully")
        }

        // 自動マージ設定
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        return container
    }()

    /// メインコンテキスト（UI用）
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    /// バックグラウンドコンテキストを作成
    func newBackgroundContext() -> NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }

    // MARK: - Save Operations

    /// メインコンテキストを保存
    func save() {
        let context = persistentContainer.viewContext

        if context.hasChanges {
            do {
                try context.save()
                logger.info("Context saved successfully")
            } catch {
                logger.error("Save error: \(error)")
                let nsError = error as NSError
                fatalError("Save error: \(nsError), \(nsError.userInfo)")
            }
        }
    }

    /// バックグラウンドコンテキストで操作を実行
    func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async rethrows -> T {
        return try await withCheckedThrowingContinuation { continuation in
            let context = newBackgroundContext()
            context.perform {
                do {
                    let result = try block(context)
                    try context.save()
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - CloudKit Operations

    /// CloudKit同期状態の確認
    func checkCloudKitAccountStatus() async -> CKAccountStatus {
        let container = CKContainer(identifier: "iCloud.com.bottlekeep.app")
        do {
            let status = try await container.accountStatus()
            logger.info("CloudKit account status: \(status.rawValue)")
            return status
        } catch {
            logger.error("CloudKit account status error: \(error)")
            return .couldNotDetermine
        }
    }

    /// 手動同期の実行
    func initiateCloudKitSync() async {
        do {
            try await persistentContainer.initializeCloudKitSchema()
            logger.info("CloudKit sync initiated")
        } catch {
            logger.error("CloudKit sync error: \(error)")
        }
    }

    // MARK: - Data Reset

    /// 全データを削除（開発・テスト用）
    func resetAllData() {
        let context = persistentContainer.viewContext

        // 全エンティティを削除
        let entityNames = ["Bottle", "BottlePhoto"]

        for entityName in entityNames {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

            do {
                try context.execute(deleteRequest)
                logger.info("Deleted all \(entityName) entities")
            } catch {
                logger.error("Delete error for \(entityName): \(error)")
            }
        }

        save()
    }

    // MARK: - Initialization

    private init() {
        // 通知の設定
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(contextDidChange),
            name: .NSManagedObjectContextDidSave,
            object: nil
        )
    }

    @objc private func contextDidChange(_ notification: Notification) {
        // UI更新の通知
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - CloudKit Extensions

extension CKAccountStatus {
    var description: String {
        switch self {
        case .couldNotDetermine:
            return "Could not determine"
        case .available:
            return "Available"
        case .restricted:
            return "Restricted"
        case .noAccount:
            return "No account"
        case .temporarilyUnavailable:
            return "Temporarily unavailable"
        @unknown default:
            return "Unknown"
        }
    }
}