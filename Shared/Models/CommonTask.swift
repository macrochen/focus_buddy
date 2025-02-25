import Foundation

struct CommonTask: Identifiable {
    let id = UUID()
    let title: String
    let estimatedTime: Int
}

class CommonTaskStore {
    static let shared = CommonTaskStore()
    
    let commonTasks: [CommonTask] = [
        CommonTask(title: "数学作业", estimatedTime: 45),
        CommonTask(title: "语文作业", estimatedTime: 30),
        CommonTask(title: "英语作业", estimatedTime: 30),
        CommonTask(title: "物理作业", estimatedTime: 40),
        CommonTask(title: "化学作业", estimatedTime: 35),
        CommonTask(title: "预习", estimatedTime: 25),
        CommonTask(title: "复习", estimatedTime: 20),
    ]
}