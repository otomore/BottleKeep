import Foundation
import CoreData

extension WishlistItem {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<WishlistItem> {
        return NSFetchRequest<WishlistItem>(entityName: "WishlistItem")
    }

    @NSManaged public var budget: NSDecimalNumber?
    @NSManaged public var createdAt: Date?
    @NSManaged public var distillery: String?
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var notes: String?
    @NSManaged public var priority: Int16
    @NSManaged public var targetPrice: NSDecimalNumber?
    @NSManaged public var updatedAt: Date?
}

extension WishlistItem : Identifiable {
    public var wrappedName: String {
        name ?? "名称未設定"
    }

    public var wrappedDistillery: String {
        distillery ?? "不明"
    }

    public var wrappedNotes: String {
        notes ?? ""
    }

    public var priorityLevel: String {
        switch priority {
        case 5:
            return "最高"
        case 4:
            return "高"
        case 3:
            return "中"
        case 2:
            return "低"
        case 1:
            return "最低"
        default:
            return "未設定"
        }
    }
}