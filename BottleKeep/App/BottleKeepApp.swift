import SwiftUI
import CoreData

@main
struct BottleKeepApp: App {
    // Core Data Stack
    let persistenceController = CoreDataManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.context)
                .environmentObject(DIContainer())
        }
    }
}