import SwiftUI
import Foundation
import CoreData

struct AddTaskView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingAlert = false  
    @State private var showingDatePicker = false  // 新增状态变量
    
    private let dateFormatter: DateFormatter = {  // 新增日期格式化器
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()

    @State private var title = ""
    @State private var estimatedTime: Int32 = 25
    @State private var showingCommonTasks = false
    @State private var plannedDate: Date  // 新增计划日期
    
    private let task: FocusTask?
    private let isEditing: Bool
    
    init(task: FocusTask? = nil, selectedDate: Date = Date()) {  // 修改初始化方法
        self.task = task
        self.isEditing = task != nil
        _title = State(initialValue: task?.title ?? "")
        _estimatedTime = State(initialValue: task?.estimatedTime ?? 25) 
        _plannedDate = State(initialValue: task?.date ?? selectedDate)  // 初始化计划日期
    }
    
    // 添加一个用于验证输入的函数
    private func isValidNumber(_ string: String) -> Bool {
        let allowedCharacters = CharacterSet.decimalDigits
        return string.unicodeScalars.allSatisfy { allowedCharacters.contains($0) }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 添加日期选择器
                HStack {
                    Text("计划日期")
                    Spacer()
                    Button(action: { showingDatePicker = true }) {
                        Text(dateFormatter.string(from: plannedDate))
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                
                // 输入框部分
                HStack {
                    TextField("任务名称", text: $title)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.next)
                    
                    if !isEditing {
                        Button(action: { showingCommonTasks = true }) {
                            Image(systemName: "star")
                                .foregroundColor(.blue)
                                .frame(width: 44, height: 44)  // 增加点击区域
                                .contentShape(Rectangle())  // 确保整个区域可点击
                        }
                        .buttonStyle(PlainButtonStyle())  // 去除按钮默认样式
                        .help("选择常用任务") 
                    }
                    
                    if !title.isEmpty {
                        Button(action: { title = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal)

                HStack {
                    Text("预计时间")
                    Spacer()
                    HStack(spacing: 0) {
                        Picker("小时", selection: Binding(
                            get: { Int(estimatedTime) / 60 },
                            set: { newValue in
                                let minutes = Int(estimatedTime) % 60
                                estimatedTime = Int32(newValue * 60 + minutes)
                            }
                        )) {
                            ForEach(0...8, id: \.self) { hour in
                                Text("\(hour)小时").tag(hour)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 100)
                        .clipped()
                        
                        Picker("分钟", selection: Binding(
                            get: { Int(estimatedTime) % 60 },
                            set: { newValue in
                                let hours = Int(estimatedTime) / 60
                                estimatedTime = Int32(hours * 60 + newValue)
                            }
                        )) {
                            ForEach(0..<60, id: \.self) { minute in
                                Text("\(minute)分").tag(minute)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 100)
                        .clipped()
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
                    .disabled(title.isEmpty)
            }
        }
        .sheet(isPresented: $showingDatePicker) {
            NavigationView {
                DatePicker("选择日期", 
                          selection: $plannedDate,
                          displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
                    .environment(\.locale, Locale(identifier: "zh_CN"))  // 设置为中文
                    .navigationBarItems(
                        trailing: Button("完成") {
                            showingDatePicker = false
                        }
                    )
            }
        }
        .sheet(isPresented: $showingCommonTasks) {
            TaskTemplatePickerView { selectedTitle, selectedTime in
                self.title = selectedTitle
                self.estimatedTime = selectedTime
                showingCommonTasks = false
            }
        }
    }
    
    private func saveTask() {
        let taskToSave = task ?? FocusTask(context: viewContext)
        taskToSave.title = title
        taskToSave.estimatedTime = estimatedTime
        
        if !isEditing {
            taskToSave.createdAt = Date()
            taskToSave.id = UUID()  // 添加这行，为新任务生成 UUID
            taskToSave.status = "未开始"  // 设置初始状态
            taskToSave.date = Date()
        }
        taskToSave.date = plannedDate  // 保存计划日期
        
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
