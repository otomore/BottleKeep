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
            // CloudKit同期の設定
            if let description = container.persistentStoreDescriptions.first {
                // iCloud同期を有効化
                // CloudKitコンテナIDは自動的に "iCloud.$(CFBundleIdentifier)" が使用されます

                // 履歴トラッキングを有効化（CloudKit同期に必要）
                description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)

                // リモート変更通知を有効化
                description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            }
        }

        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                print("⚠️ Core Data load error: \(error), \(error.userInfo)")
                print("⚠️ Working with local storage only.")
                // エラーが発生してもアプリは続行（クラッシュさせない）
            } else {
                print("✅ Core Data loaded successfully")
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