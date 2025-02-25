import CoreData

struct FocusBuddyPersistence {
    static let shared = FocusBuddyPersistence()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "FocusBuddy")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("无法加载Core Data: \(error.localizedDescription)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    static var preview: FocusBuddyPersistence = {
        let result = FocusBuddyPersistence(inMemory: true)
        let viewContext = result.container.viewContext
        
        // 添加示例数据
        let sampleTask = FocusTask(context: viewContext)
        sampleTask.id = UUID()
        sampleTask.title = "示例任务"
        sampleTask.taskDescription = "这是一个示例任务"
        sampleTask.estimatedTime = 25
        sampleTask.createdAt = Date()
        sampleTask.status = "pending"
        
        do {
            try viewContext.save()
        } catch {
            let error = error as NSError
            fatalError("无法创建预览数据: \(error)")
        }
        
        return result
    }()
}