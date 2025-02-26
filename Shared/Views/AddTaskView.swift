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
    
    // 添加一个用于验证输入的函数
    private func isValidNumber(_ string: String) -> Bool {
        let allowedCharacters = CharacterSet.decimalDigits
        return string.unicodeScalars.allSatisfy { allowedCharacters.contains($0) }
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
                        .onChange(of: estimatedTime) { newValue in
                            // 只允许输入数字
                            if !isValidNumber(newValue) {
                                estimatedTime = String(newValue.filter { $0.isNumber })
                            }
                            // 限制最大值为 480 分钟（8小时）
                            if let number = Int(estimatedTime), number > 480 {
                                estimatedTime = "480"
                            }
                        }
                        
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
        // 确保有有效的时间值
        if let time = Int32(estimatedTime), time > 0 {
            taskToSave.estimatedTime = time
        } else {
            taskToSave.estimatedTime = 25 // 默认25分钟
        }
        if !isEditing {
            taskToSave.createdAt = Date()
            taskToSave.id = UUID()  // 添加这行，为新任务生成 UUID
            taskToSave.status = "未开始"  // 设置初始状态
            taskToSave.date = Date()
        }
        
        do {
            try viewContext.save()
            DispatchQueue.main.async {
                showingAlert = true
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
