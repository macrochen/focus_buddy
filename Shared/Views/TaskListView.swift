import SwiftUI
import CoreData

struct TaskListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest private var tasks: FetchedResults<FocusTask>
    
    @State private var showingAddTask = false
    @State private var isEditing = false
    @State private var taskToDelete: FocusTask?
    @State private var showingDeleteAlert = false
    
    init() {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        // 添加状态条件：只显示未完成和进行中的任务
        let predicate = NSPredicate(format: "date >= %@ AND date < %@ AND (status == nil OR status == %@ OR status == %@)", 
            today as NSDate, 
            tomorrow as NSDate,
            "未开始",
            "进行中"
        )
        
        _tasks = FetchRequest<FocusTask>(
            entity: FocusTask.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \FocusTask.createdAt, ascending: false)],
            predicate: predicate,
            animation: .default
        )
    }

    var body: some View {
        let _ = print("当前任务数量: \(tasks.count)") 

        List {
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
        }
        .environment(\.editMode, .constant(isEditing ? .active : .inactive))
        
        .navigationTitle("任务列表")
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                NavigationLink(destination: TaskHistoryView()) {
                    Image(systemName: "clock.arrow.circlepath")
                }
                // NavigationLink(destination: StatsView()) {
                //     Image(systemName: "chart.line.uptrend.xyaxis")
                // }
                // NavigationLink(destination: InterruptionStatsView()) {
                //     Image(systemName: "chart.bar.fill")
                // }
                if !tasks.isEmpty {
                    Button(isEditing ? "完成" : "编辑") {
                        isEditing.toggle()
                    }
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddTask = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddTask) {
            NavigationView {
                AddTaskView()
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
            TaskListView()
                .environment(\.managedObjectContext, FocusBuddyPersistence.preview.container.viewContext)
        }
    }
}
