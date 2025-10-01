import CoreData
import Foundation

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

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "BottleKeeper")

        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // CloudKit同期の設定（オプショナル）
            if let description = container.persistentStoreDescriptions.first {
                // CloudKitコンテナオプション（iCloudが利用可能な場合のみ有効）
                description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                    containerIdentifier: "iCloud.com.bottlekeep.whiskey"
                )

                // 履歴トラッキングとリモート変更通知を有効化
                description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
                description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            }
        }

        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                print("⚠️ Core Data load error: \(error), \(error.userInfo)")
                // CloudKit同期エラーの場合、詳細をログに出力
                if let cloudKitError = error.userInfo["NSUnderlyingError"] as? NSError {
                    print("⚠️ CloudKit error: \(cloudKitError)")
                    print("⚠️ CloudKit sync is disabled. App will work with local storage only.")
                }
                // CloudKitエラーでもアプリは続行（ローカルストレージとして動作）
                // 致命的なストレージエラーの場合のみクラッシュ
                if error.domain == NSCocoaErrorDomain && error.code == NSPersistentStoreIncompatibleVersionHashError {
                    fatalError("Unresolved persistent store error \(error), \(error.userInfo)")
                }
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    func save() {
        let context = container.viewContext

        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    func delete(_ object: NSManagedObject) {
        container.viewContext.delete(object)
        save()
    }
}