import SwiftUI
import CoreData

@main
struct FocusBuddyApp: App {
    let persistenceController = FocusBuddyPersistence.shared
    
    init() {
        // 检查是否是首次安装
        if !UserDefaults.standard.bool(forKey: "hasLaunchedBefore") {
            clearAllData()
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        }
        
        // 检查并更新异常退出时的任务状态
        checkAndUpdateInProgressTasks()
    }
    
    private func clearAllData() {
        let context = persistenceController.container.viewContext
        let entities = ["FocusTask", "FocusSession", "Interruption"]
        
        for entityName in entities {
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try persistenceController.container.persistentStoreCoordinator.execute(deleteRequest, with: context)
            } catch {
                print("清理\(entityName)数据失败：\(error)")
            }
        }
        
        try? context.save()
    }
    
    private func checkAndUpdateInProgressTasks() {
        let context = persistenceController.container.viewContext
        let request = FocusTask.fetchRequest()
        request.predicate = NSPredicate(format: "status == %@", "进行中")
        
        if let inProgressTasks = try? context.fetch(request) {
            for task in inProgressTasks {
                task.status = "已中断"
                task.date = Date()  // 记录中断时间
            }
            try? context.save()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}