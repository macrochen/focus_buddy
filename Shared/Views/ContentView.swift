import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        NavigationView {
            TaskListView()
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        NavigationLink(destination: TaskHistoryView()) {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    ToolbarItem(placement: .principal) {
                        Text("专注伙伴")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack(spacing: 16) {
                            NavigationLink(destination: AddTaskView()) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                            }
                            
                            NavigationLink(destination: SettingsView()) {
                                Image(systemName: "gear")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .accentColor(.blue)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, FocusBuddyPersistence.preview.container.viewContext)
    }
}