import SwiftUI
import Foundation
import CoreData

struct AddTaskView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingAlert = false  // 添加这行
    
    @State private var title = ""
    @State private var estimatedTime = ""
    @State private var showingCommonTasks = false
    
    private let task: FocusTask?
    private let isEditing: Bool
    
    init(task: FocusTask? = nil) {
        self.task = task
        self.isEditing = task != nil
        _title = State(initialValue: task?.title ?? "")
        _estimatedTime = State(initialValue: task?.estimatedTime ?? 0 > 0 ? String(task?.estimatedTime ?? 0) : "")
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if !isEditing {
                    Button(action: { showingCommonTasks = true }) {
                        HStack {
                            Image(systemName: "star.fill")
                            Text("从常用任务中选择")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    Divider()
                        .padding(.horizontal)
                }
                
                // 输入框部分
                HStack {
                    TextField("任务名称", text: $title)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.next)
                    
                    if !title.isEmpty {
                        Button(action: { title = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal)
                
                HStack {
                    TextField("预计时间（分钟）", text: $estimatedTime)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                        .submitLabel(.done)
                        
                        if !estimatedTime.isEmpty {
                            Button(action: { estimatedTime = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .alert("添加成功", isPresented: $showingAlert) {
            Button("确定") {
                dismiss()  // 点击确定后返回
            }
        } message: {
            Text("任务「\(title)」已添加到列表中")  // 修改这行，使用中文书名号
        }
        .navigationTitle(isEditing ? "编辑任务" : "新建任务")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("取消") { dismiss() }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "保存" : "添加") { saveTask() }
                    .disabled(title.isEmpty || estimatedTime.isEmpty)
            }
        }
        .sheet(isPresented: $showingCommonTasks) {
             TaskTemplatePickerView { title, time in
                self.title = title
                self.estimatedTime = String(time)
            }
        }
    }
    
    private func saveTask() {
        let taskToSave = task ?? FocusTask(context: viewContext)
        taskToSave.title = title
        taskToSave.estimatedTime = Int32(estimatedTime) ?? 25
        if !isEditing {
            taskToSave.createdAt = Date()
            taskToSave.id = UUID()  // 添加这行，为新任务生成 UUID
            taskToSave.status = "未开始"  // 设置初始状态
            taskToSave.date = Date()
        }
        
        do {
            try viewContext.save()
            print("保存成功，准备显示 alert")  // 添加调试输出
            DispatchQueue.main.async {
                showingAlert = true
                print("alert 状态已设置为 true")  // 添加调试输出
            }
        } catch {
            print("Error saving task: \(error)")
        }
    }
}


struct AddTaskView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AddTaskView()
                .environment(\.managedObjectContext, FocusBuddyPersistence.preview.container.viewContext)
        }
    }
}
