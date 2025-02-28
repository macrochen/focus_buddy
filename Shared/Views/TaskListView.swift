import SwiftUI
import CoreData

struct TaskListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FocusTask.order, ascending: true)],  // 添加排序
        animation: .default)
    private var tasks: FetchedResults<FocusTask>
    @State private var editMode: EditMode = .inactive
    @State private var showingAddTask = false
    @State private var isEditing = false
    @State private var taskToDelete: FocusTask?
    @State private var showingDeleteAlert = false
    
    init(selectedDate: Date) {
        // 获取选中日期的开始和结束时间
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        // 根据日期过滤任务，并且只显示未完成和进行中的任务
        let predicate = NSPredicate(format: "date >= %@ AND date < %@ AND (status == nil OR status == %@ OR status == %@)", 
            startOfDay as NSDate, 
            endOfDay as NSDate,
            "未开始",
            "进行中"
        )
        
        _tasks = FetchRequest(
            entity: FocusTask.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \FocusTask.createdAt, ascending: false)],
            predicate: predicate,
            animation: .default
        )
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
