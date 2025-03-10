import SwiftUI
import CoreData

#if os(iOS) 
struct TaskListView: View {
    let selectedDate: Date
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest private var tasks: FetchedResults<FocusTask>
    @State private var editMode: EditMode = .inactive
    @State private var showingAddTask = false
    @State private var isEditing = false
    @State private var taskToDelete: FocusTask?
    @State private var showingDeleteAlert = false
    
    init(selectedDate: Date) {
        self.selectedDate = selectedDate
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: selectedDate)
        let endDate = calendar.date(byAdding: .day, value: 1, to: startDate)!
        
        // 恢复原有的过滤逻辑，包括任务状态的过滤
        _tasks = FetchRequest<FocusTask>(
            sortDescriptors: [NSSortDescriptor(keyPath: \FocusTask.order, ascending: true)],
            predicate: NSPredicate(
                format: "date >= %@ AND date < %@ AND (status == nil OR status == %@ OR status == %@)",
                startDate as NSDate,
                endDate as NSDate,
                "未开始",
                "进行中"
            )
        )
    }
    
    private func calculateEstimatedEndTime(for tasks: [FocusTask]) -> String {
        let totalMinutes = tasks.reduce(0) { $0 + Int($1.estimatedTime) }
        let endTime = Date().addingTimeInterval(Double(totalMinutes * 60))
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: endTime)
    }
    
    var body: some View {
        List {
            if tasks.isEmpty {
                Text("当前日期暂无任务")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(tasks, id: \.objectID) { task in
                    TaskRow(task: task)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                taskToDelete = task
                                showingDeleteAlert = true
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                }
                .onDelete(perform: deleteTasks)
                .onMove(perform: moveTasks)  // 添加这行
                
                // 添加预估完成时间按钮
                Section {
                    Button(action: {
                        let incompleteTasks = Array(tasks).filter { $0.status == nil || $0.status == "未开始" }
                        let endTime = calculateEstimatedEndTime(for: incompleteTasks)
                        
                        let alert = UIAlertController(
                            title: "预估完成时间",
                            message: "如果从现在开始连续完成所有未完成的任务，预计在今天 \(endTime) 完成",
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "好的", style: .default))
                        
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let viewController = windowScene.windows.first?.rootViewController {
                            viewController.present(alert, animated: true)
                        }
                    }) {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                            Text("预估完成时间")
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
        }
        .environment(\.editMode, .constant(isEditing ? .active : .inactive))
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                if !tasks.isEmpty {
                    Button(isEditing ? "完成" : "编辑") {
                        isEditing.toggle()
                    }
                }
            }
        }
        .alert(
            "确认删除",
            isPresented: $showingDeleteAlert,
            actions: {
                Button("取消", role: .cancel) {
                    taskToDelete = nil
                }
                Button("删除", role: .destructive) {
                    if let task = taskToDelete,
                       let index = tasks.firstIndex(of: task) {
                        deleteTasks(offsets: IndexSet(integer: index))
                    }
                    taskToDelete = nil
                }
            },
            message: {
                let title = taskToDelete?.title ?? ""
                Text("确定要删除任务" + title + "吗？此操作不可撤销。")
            }
        )
    }
    
    private func deleteTasks(offsets: IndexSet) {
        withAnimation {
            offsets.map { tasks[$0] }.forEach(viewContext.delete)
            try? viewContext.save()
        }
    }

    private func moveTasks(from source: IndexSet, to destination: Int) {
        // 获取所有任务
        var allTasks = tasks.map { $0 }
        // 执行移动
        allTasks.move(fromOffsets: source, toOffset: destination)
        // 更新每个任务的顺序
        for (index, task) in allTasks.enumerated() {
            task.order = Int16(index)
        }
        // 保存更改
        try? viewContext.save()
    }
}

struct TaskRow: View {
    @Environment(\.managedObjectContext) private var viewContext  // 添加这行
    let task: FocusTask
    @State private var showingEditTask = false
    
    var body: some View {
        NavigationLink(destination: TimerView(task: task)) {
            VStack(alignment: .leading) {
                Text(task.title ?? "")
                    .font(.headline)
                Text("\(task.estimatedTime)分钟")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .swipeActions(edge: .leading) {
            Button {
                showingEditTask = true
            } label: {
                Label("编辑", systemImage: "pencil")
            }
            .tint(.blue)
        }
        .sheet(isPresented: $showingEditTask) {
            NavigationView {
                AddTaskView(task: task)
            }
        }
        .onChange(of: showingEditTask) { isShowing in
            if !isShowing {
                task.managedObjectContext?.refresh(task, mergeChanges: true)
            }
        }
    }
}

struct TaskListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TaskListView(selectedDate: Date())  // Add the selectedDate parameter
                .environment(\.managedObjectContext, FocusBuddyPersistence.preview.container.viewContext)
        }
    }
}

#endif