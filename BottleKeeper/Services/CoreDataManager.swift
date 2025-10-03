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

                print("📱 CloudKit Container ID: \(containerIdentifier)")

                // 履歴トラッキングを有効化（CloudKit同期に必要）
                description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)

                // リモート変更通知を有効化
                description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            }
        }

        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                print("⚠️ Core Data load error: \(error), \(error.userInfo)")
                print("⚠️ Error domain: \(error.domain)")
                print("⚠️ Error code: \(error.code)")
                print("⚠️ Working with local storage only.")
                // エラーが発生してもアプリは続行（クラッシュさせない）
            } else {
                print("✅ Core Data loaded successfully")
                print("✅ Store URL: \(storeDescription.url?.absoluteString ?? "unknown")")
                print("✅ CloudKit options: \(storeDescription.cloudKitContainerOptions != nil ? "Enabled" : "Disabled")")
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
        CKContainer(identifier: "iCloud.com.bottlekeep.whiskey").accountStatus { status, error in
            if let error = error {
                print("⚠️ iCloud account check error: \(error.localizedDescription)")
                self.iCloudAvailable = false
                return
            }

            switch status {
            case .available:
                print("✅ iCloud account is available")
                self.iCloudAvailable = true
            case .noAccount:
                print("⚠️ No iCloud account configured")
                self.iCloudAvailable = false
            case .restricted:
                print("⚠️ iCloud account is restricted")
                self.iCloudAvailable = false
            case .couldNotDetermine:
                print("⚠️ Could not determine iCloud account status")
                self.iCloudAvailable = false
            case .temporarilyUnavailable:
                print("⚠️ iCloud account is temporarily unavailable")
                self.iCloudAvailable = false
            @unknown default:
                print("⚠️ Unknown iCloud account status")
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

        print("☁️ CloudKit Event: \(event.type)")

        if let error = event.error {
            print("❌ CloudKit sync error: \(error.localizedDescription)")
            print("❌ Error domain: \((error as NSError).domain)")
            print("❌ Error code: \((error as NSError).code)")
        } else {
            switch event.type {
            case .setup:
                print("🔧 CloudKit setup completed")
            case .import:
                print("⬇️ CloudKit import completed")
            case .export:
                print("⬆️ CloudKit export completed")
            @unknown default:
                print("❓ Unknown CloudKit event type")
            }
        }
    }

    // iCloud同期が利用可能かどうか
    var isCloudSyncAvailable: Bool {
        return iCloudAvailable
    }

    func save() {
        let context = container.viewContext

        if context.hasChanges {
            do {
                try context.save()
                print("💾 Core Data saved successfully")
                if iCloudAvailable {
                    print("☁️ iCloud sync will begin automatically")
                }
            } catch {
                let nsError = error as NSError
                print("⚠️ Core Data save error: \(nsError), \(nsError.userInfo)")
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