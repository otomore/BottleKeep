import Foundation
import CoreData

extension Bottle {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Bottle> {
        return NSFetchRequest<Bottle>(entityName: "Bottle")
    }

    @NSManaged public var abv: Double
    @NSManaged public var createdAt: Date?
    @NSManaged public var distillery: String?
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var notes: String?
    @NSManaged public var openedDate: Date?
    @NSManaged public var purchaseDate: Date?
    @NSManaged public var purchasePrice: NSDecimalNumber?
    @NSManaged public var rating: Int16
    @NSManaged public var region: String?
    @NSManaged public var remainingVolume: Int32
    @NSManaged public var shop: String?
    @NSManaged public var type: String?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var vintage: Int32
    @NSManaged public var volume: Int32
    @NSManaged public var drinkingLogs: NSSet?
    @NSManaged public var photos: NSSet?
}

// MARK: - Generated accessors for drinkingLogs
extension Bottle {
    @objc(addDrinkingLogsObject:)
    @NSManaged public func addToDrinkingLogs(_ value: DrinkingLog)

    @objc(removeDrinkingLogsObject:)
    @NSManaged public func removeFromDrinkingLogs(_ value: DrinkingLog)

    @objc(addDrinkingLogs:)
    @NSManaged public func addToDrinkingLogs(_ values: NSSet)

    @objc(removeDrinkingLogs:)
    @NSManaged public func removeFromDrinkingLogs(_ values: NSSet)
}

// MARK: - Generated accessors for photos
extension Bottle {
    @objc(addPhotosObject:)
    @NSManaged public func addToPhotos(_ value: BottlePhoto)

    @objc(removePhotosObject:)
    @NSManaged public func removeFromPhotos(_ value: BottlePhoto)

    @objc(addPhotos:)
    @NSManaged public func addToPhotos(_ values: NSSet)

    @objc(removePhotos:)
    @NSManaged public func removeFromPhotos(_ values: NSSet)
}

extension Bottle : Identifiable {
    public var wrappedName: String {
        name ?? "名称未設定"
    }

    public var wrappedDistillery: String {
        distillery ?? "不明"
    }

    public var wrappedRegion: String {
        region ?? "不明"
    }

    public var wrappedType: String {
        type ?? "不明"
    }

    public var wrappedNotes: String {
        notes ?? ""
    }

    public var wrappedShop: String {
        shop ?? "不明"
    }

    public var remainingPercentage: Double {
        guard volume > 0 else { return 0 }
        return Double(remainingVolume) / Double(volume) * 100
    }

    public var isOpened: Bool {
        openedDate != nil
    }

    public var photosArray: [BottlePhoto] {
        let set = photos as? Set<BottlePhoto> ?? []
        return set.sorted {
            $0.createdAt ?? Date() < $1.createdAt ?? Date()
        }
    }

    public var drinkingLogsArray: [DrinkingLog] {
        let set = drinkingLogs as? Set<DrinkingLog> ?? []
        return set.sorted {
            ($0.date ?? Date()) > ($1.date ?? Date())
        }
    }
}