import Foundation
import CoreData

extension BottlePhoto {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BottlePhoto> {
        return NSFetchRequest<BottlePhoto>(entityName: "BottlePhoto")
    }

    @NSManaged public var id: UUID
    @NSManaged public var fileName: String
    @NSManaged public var isMain: Bool
    @NSManaged public var createdAt: Date
    @NSManaged public var bottle: Bottle?

}

// MARK: - Identifiable
extension BottlePhoto: Identifiable {

}