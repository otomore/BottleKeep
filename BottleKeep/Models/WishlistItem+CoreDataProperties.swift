import Foundation
import CoreData

extension WishlistItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WishlistItem> {
        return NSFetchRequest<WishlistItem>(entityName: "WishlistItem")
    }

    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var distillery: String
    @NSManaged public var region: String?
    @NSManaged public var type: String?
    @NSManaged public var vintage: Int32
    @NSManaged public var estimatedPrice: NSDecimalNumber?
    @NSManaged public var priority: Int16
    @NSManaged public var notes: String?
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date

}

// MARK: - Identifiable

extension WishlistItem: Identifiable {

}