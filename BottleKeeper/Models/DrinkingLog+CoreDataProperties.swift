import Foundation
import CoreData

extension DrinkingLog {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<DrinkingLog> {
        return NSFetchRequest<DrinkingLog>(entityName: "DrinkingLog")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var volume: Int32
    @NSManaged public var notes: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var bottle: Bottle?
}

extension DrinkingLog : Identifiable {
    public var wrappedNotes: String {
        notes ?? ""
    }

    public var wrappedDate: Date {
        date ?? Date()
    }
}
