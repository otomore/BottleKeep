import Foundation
import CoreData

extension BottlePhoto {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<BottlePhoto> {
        return NSFetchRequest<BottlePhoto>(entityName: "BottlePhoto")
    }

    @NSManaged public var createdAt: Date?
    @NSManaged public var fileName: String?
    @NSManaged public var fileSize: Int64
    @NSManaged public var id: UUID?
    @NSManaged public var isMain: Bool
    @NSManaged public var bottle: Bottle?
}

extension BottlePhoto : Identifiable {
    public var wrappedFileName: String {
        fileName ?? "unknown.jpg"
    }
}