import CoreData
import Foundation
import CloudKit

class CoreDataManager {
    static let shared = CoreDataManager()
    static let preview: CoreDataManager = {
        let manager = CoreDataManager(inMemory: true)
        let viewContext = manager.container.viewContext

        // プレビュー用のサンプルデータを作成
        for i in 0..<5 {
            let newBottle = NSEntityDescription.insertNewObject(forEntityName: "Bottle", into: viewContext) as! NSManagedObject
            newBottle.setValue(UUID(), forKey: "id")
            newBottle.setValue("サンプルウイスキー \(i + 1)", forKey: "name")
            newBottle.setValue("サンプル蒸留所", forKey: "distillery")
            newBottle.setValue(40.0 + Double(i), forKey: "abv")
            newBottle.setValue(700, forKey: "volume")
            newBottle.setValue(Int32(700 - (i * 100)), forKey: "remainingVolume")
            newBottle.setValue(Date(), forKey: "purchaseDate")
            newBottle.setValue(Date(), forKey: "createdAt")
            newBottle.setValue(Date(), forKey: "updatedAt")
        }

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return manager
    }()

    let container: NSPersistentCloudKitContainer
    private var iCloudAvailable = false
    private let logger = CloudKitLogger.shared

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "BottleKeeper")

        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // iCloudアカウント状態を確認
            checkiCloudAccountStatus()

            // CloudKit同期の設定
            if let description = container.persistentStoreDescriptions.first {
                // CloudKitコンテナIDを明示的に設定
                let containerIdentifier = "iCloud.com.bottlekeep.whiskey"
                let options = NSPersistentCloudKitContainerOptions(containerIdentifier: containerIdentifier)
                description.cloudKitContainerOptions = options

                logger.log("CloudKit Container ID: \(containerIdentifier)", level: .debug)

                // 履歴トラッキングを有効化（CloudKit同期に必要）
                description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)

                // リモート変更通知を有効化
                description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            }
        }

        container.loadPersistentStores { [weak self] (storeDescription, error) in
            if let error = error as NSError? {
                self?.logger.log("Core Data load error: \(error.localizedDescription)", level: .error)
                self?.logger.log("Error domain: \(error.domain)", level: .error)
                self?.logger.log("Error code: \(error.code)", level: .error)
                self?.logger.log("Working with local storage only", level: .warning)
                // エラーが発生してもアプリは続行（クラッシュさせない）
            } else {
                self?.logger.log("Core Data loaded successfully", level: .success)
                self?.logger.log("Store URL: \(storeDescription.url?.absoluteString ?? "unknown")", level: .debug)
                self?.logger.log("CloudKit options: \(storeDescription.cloudKitContainerOptions != nil ? "Enabled" : "Disabled")", level: .debug)
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        // CloudKit同期イベントを監視
        if !inMemory {
            setupCloudKitNotifications()
        }
    }

    // iCloudアカウント状態を確認
    private func checkiCloudAccountStatus() {
        CKContainer(identifier: "iCloud.com.bottlekeep.whiskey").accountStatus { [weak self] status, error in
            guard let self = self else { return }

            if let error = error {
                self.logger.log("iCloud account check error: \(error.localizedDescription)", level: .error)
                self.iCloudAvailable = false
                return
            }

            switch status {
            case .available:
                self.logger.log("iCloud account is available", level: .success)
                self.iCloudAvailable = true
            case .noAccount:
                self.logger.log("No iCloud account configured", level: .warning)
                self.iCloudAvailable = false
            case .restricted:
                self.logger.log("iCloud account is restricted", level: .warning)
                self.iCloudAvailable = false
            case .couldNotDetermine:
                self.logger.log("Could not determine iCloud account status", level: .warning)
                self.iCloudAvailable = false
            case .temporarilyUnavailable:
                self.logger.log("iCloud account is temporarily unavailable", level: .warning)
                self.iCloudAvailable = false
            @unknown default:
                self.logger.log("Unknown iCloud account status", level: .warning)
                self.iCloudAvailable = false
            }
        }
    }

    // CloudKit同期イベントの監視を設定
    private func setupCloudKitNotifications() {
        // CloudKit同期イベントを監視
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCloudKitEvent(_:)),
            name: NSPersistentCloudKitContainer.eventChangedNotification,
            object: container
        )
    }

    @objc private func handleCloudKitEvent(_ notification: Notification) {
        guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                as? NSPersistentCloudKitContainer.Event else {
            return
        }

        logger.log("CloudKit Event: \(event.type)", level: .cloudKit)

        if let error = event.error {
            logger.log("CloudKit sync error: \(error.localizedDescription)", level: .error)
            logger.log("Error domain: \((error as NSError).domain)", level: .error)
            logger.log("Error code: \((error as NSError).code)", level: .error)
        } else {
            switch event.type {
            case .setup:
                logger.log("CloudKit setup completed", level: .cloudKit)
            case .import:
                logger.log("CloudKit import completed", level: .cloudKit)
            case .export:
                logger.log("CloudKit export completed", level: .cloudKit)
            @unknown default:
                logger.log("Unknown CloudKit event type", level: .cloudKit)
            }
        }
    }

    // iCloud同期が利用可能かどうか
    var isCloudSyncAvailable: Bool {
        return iCloudAvailable
    }

    // CloudKitスキーマを初期化（初回セットアップ時のみ実行）
    func initializeCloudKitSchema() throws {
        logger.log("Initializing CloudKit schema...", level: .debug)
        do {
            try container.initializeCloudKitSchema(options: [])
            logger.log("CloudKit schema initialized successfully", level: .success)
            UserDefaults.standard.set(true, forKey: "cloudKitSchemaInitialized")
            UserDefaults.standard.set(Date(), forKey: "cloudKitSchemaInitializedDate")
        } catch {
            logger.log("Failed to initialize CloudKit schema: \(error.localizedDescription)", level: .error)
            throw error
        }
    }

    // CloudKitスキーマが初期化済みかどうか
    var isCloudKitSchemaInitialized: Bool {
        return UserDefaults.standard.bool(forKey: "cloudKitSchemaInitialized")
    }

    // CloudKitスキーマの初期化日時
    var cloudKitSchemaInitializedDate: Date? {
        return UserDefaults.standard.object(forKey: "cloudKitSchemaInitializedDate") as? Date
    }

    func save() {
        let context = container.viewContext

        if context.hasChanges {
            do {
                try context.save()
                logger.log("Core Data saved successfully", level: .success)
                if iCloudAvailable {
                    logger.log("iCloud sync will begin automatically", level: .cloudKit)
                }
            } catch {
                let nsError = error as NSError
                logger.log("Core Data save error: \(nsError.localizedDescription)", level: .error)
                // エラーが発生してもアプリは続行（クラッシュさせない）
                // ユーザーデータの損失を防ぐため、次回の保存を試みる
            }
        }
    }

    func delete(_ object: NSManagedObject) {
        container.viewContext.delete(object)
        save()
    }
}