import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()
    static let preview: CoreDataManager = {
        let manager = CoreDataManager(inMemory: true)
        let viewContext = manager.container.viewContext

        // プレビュー用のサンプルデータを作成
        for i in 0..<5 {
            let newBottle = Bottle(context: viewContext)
            newBottle.id = UUID()
            newBottle.name = "サンプルウイスキー \(i + 1)"
            newBottle.distillery = "サンプル蒸留所"
            newBottle.abv = 40.0 + Double(i)
            newBottle.volume = 700
            newBottle.remainingVolume = Int32(700 - (i * 100))
            newBottle.purchaseDate = Date()
            newBottle.createdAt = Date()
            newBottle.updatedAt = Date()
        }

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return manager
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "BottleKeeper")

        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }

        container.persistentStoreDescriptions.forEach { description in
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        }

        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
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