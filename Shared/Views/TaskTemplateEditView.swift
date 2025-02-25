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
                    Text("预计时间：\(estimatedTime)分钟")
                    Spacer()
                    Stepper("", value: $estimatedTime, in: 1...120)
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