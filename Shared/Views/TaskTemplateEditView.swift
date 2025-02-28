import SwiftUI
import CoreData

struct TaskTemplateEditView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let template: TaskTemplate?
    
    @State private var title: String = ""
    @State private var estimatedTime: Int32 = 25
    
    @FocusState private var isFocused: Bool
    
    init(template: TaskTemplate? = nil) {
        self.template = template
        _title = State(initialValue: template?.title ?? "")
        _estimatedTime = State(initialValue: template?.estimatedTime ?? 25)
    }
    
    var body: some View {
        Form {
            Section {
                TextField("任务名称", text: $title)
                    .focused($isFocused)
                
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
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isFocused = true
            }
        }
        .navigationTitle(template == nil ? "新增常用任务" : "编辑任务")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("取消") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("保存") {
                    saveTemplate()
                }
                .disabled(title.isEmpty)
            }
        }
    }
    
    private func saveTemplate() {
        let templateToSave = template ?? TaskTemplate(context: viewContext)
        templateToSave.title = title
        templateToSave.estimatedTime = estimatedTime
        templateToSave.createdAt = template?.createdAt ?? Date()
        
        if template == nil {
            // 新模板，设置排序顺序为最后
            let fetchRequest: NSFetchRequest<TaskTemplate> = TaskTemplate.fetchRequest()
            let count = (try? viewContext.count(for: fetchRequest)) ?? 0
            templateToSave.order = Int32(count)
        }
        
        try? viewContext.save()
        dismiss()
    }
}