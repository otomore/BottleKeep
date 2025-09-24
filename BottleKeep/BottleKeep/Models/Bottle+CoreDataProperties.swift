import Foundation
import CoreData

extension Bottle {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Bottle> {
        return NSFetchRequest<Bottle>(entityName: "Bottle")
    }

    // MARK: - Core Properties
    @NSManaged public var id: UUID
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date

    // MARK: - Basic Information
    @NSManaged public var name: String
    @NSManaged public var distillery: String
    @NSManaged public var region: String?
    @NSManaged public var type: String?
    @NSManaged public var abv: Double
    @NSManaged public var volume: Int32
    @NSManaged public var vintage: Int32

    // MARK: - Purchase Information
    @NSManaged public var purchaseDate: Date?
    @NSManaged public var purchasePrice: NSDecimalNumber?
    @NSManaged public var shop: String?

    // MARK: - Tasting Information
    @NSManaged public var openedDate: Date?
    @NSManaged public var remainingVolume: Int32
    @NSManaged public var rating: Int16
    @NSManaged public var notes: String?

    // MARK: - Relations
    @NSManaged public var photos: NSSet?

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

// MARK: - Identifiable
extension Bottle: Identifiable {

}

// MARK: - Convenience Initializers
extension Bottle {

    /// 基本情報でボトルを作成
    convenience init(
        context: NSManagedObjectContext,
        name: String,
        distillery: String,
        region: String? = nil,
        type: String? = nil,
        abv: Double = 0,
        volume: Int32 = 0
    ) {
        self.init(context: context)
        self.name = name
        self.distillery = distillery
        self.region = region
        self.type = type
        self.abv = abv
        self.volume = volume
        self.remainingVolume = volume
    }

    /// テスト用のボトル作成
    static func createTestBottle(
        context: NSManagedObjectContext,
        name: String = "テストボトル",
        distillery: String = "テスト蒸留所"
    ) -> Bottle {
        return Bottle(
            context: context,
            name: name,
            distillery: distillery,
            region: "テスト地域",
            type: "シングルモルト",
            abv: 43.0,
            volume: 700
        )
    }
}