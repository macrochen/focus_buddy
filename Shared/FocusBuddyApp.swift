import SwiftUI

@main
struct FocusBuddyApp: App {
    let persistenceController = FocusBuddyPersistence.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}