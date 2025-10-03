import CoreData
import Foundation
import CloudKit

class CoreDataManager: ObservableObject {
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

    // シンプルなロギング機能
    @Published private(set) var logs: [String] = []
    private let maxLogs = 100

    private func log(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let logMessage = "[\(timestamp)] \(message)"
        DispatchQueue.main.async {
            self.logs.insert(logMessage, at: 0)
            if self.logs.count > self.maxLogs {
                self.logs.removeLast()
            }
            print(logMessage)
        }
    }

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

                log("CloudKit Container ID: \(containerIdentifier)")

                // 履歴トラッキングを有効化（CloudKit同期に必要）
                description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)

                // リモート変更通知を有効化
                description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            }
        }

        container.loadPersistentStores { [weak self] (storeDescription, error) in
            if let error = error as NSError? {
                self?.log("Core Data load error: \(error.localizedDescription)")
                self?.log("Error domain: \(error.domain)")
                self?.log("Error code: \(error.code)")
                self?.log("Working with local storage only")
                // エラーが発生してもアプリは続行（クラッシュさせない）
            } else {
                self?.log("Core Data loaded successfully")
                self?.log("Store URL: \(storeDescription.url?.absoluteString ?? "unknown")")
                self?.log("CloudKit options: \(storeDescription.cloudKitContainerOptions != nil ? "Enabled" : "Disabled")")
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
                self.log("iCloud account check error: \(error.localizedDescription)")
                self.iCloudAvailable = false
                return
            }

            switch status {
            case .available:
                self.log("iCloud account is available")
                self.iCloudAvailable = true
            case .noAccount:
                self.log("No iCloud account configured")
                self.iCloudAvailable = false
            case .restricted:
                self.log("iCloud account is restricted")
                self.iCloudAvailable = false
            case .couldNotDetermine:
                self.log("Could not determine iCloud account status")
                self.iCloudAvailable = false
            case .temporarilyUnavailable:
                self.log("iCloud account is temporarily unavailable")
                self.iCloudAvailable = false
            @unknown default:
                self.log("Unknown iCloud account status")
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

        log("CloudKit Event: \(event.type)")

        if let error = event.error {
            log("CloudKit sync error: \(error.localizedDescription)")
            log("Error domain: \((error as NSError).domain)")
            log("Error code: \((error as NSError).code)")
        } else {
            switch event.type {
            case .setup:
                log("CloudKit setup completed")
            case .import:
                log("CloudKit import completed")
            case .export:
                log("CloudKit export completed")
            @unknown default:
                log("Unknown CloudKit event type")
            }
        }
    }

    // iCloud同期が利用可能かどうか
    var isCloudSyncAvailable: Bool {
        return iCloudAvailable
    }

    // CloudKitスキーマを初期化（初回セットアップ時のみ実行）
    func initializeCloudKitSchema() throws {
        log("Initializing CloudKit schema...")
        do {
            try container.initializeCloudKitSchema(options: [])
            log("CloudKit schema initialized successfully")
            UserDefaults.standard.set(true, forKey: "cloudKitSchemaInitialized")
            UserDefaults.standard.set(Date(), forKey: "cloudKitSchemaInitializedDate")
        } catch {
            log("Failed to initialize CloudKit schema: \(error.localizedDescription)")
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
                log("Core Data saved successfully")
                if iCloudAvailable {
                    log("iCloud sync will begin automatically")
                }
            } catch {
                let nsError = error as NSError
                log("Core Data save error: \(nsError.localizedDescription)")
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