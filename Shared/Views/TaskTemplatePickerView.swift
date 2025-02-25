import SwiftUI
import CoreData

struct TaskTemplatePickerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TaskTemplate.order, ascending: true)],
        animation: .default)
    private var templates: FetchedResults<TaskTemplate>
    
    @State private var showingAddTemplate = false
    var onSelect: ((String, Int32) -> Void)?
    @State private var editMode: EditMode = .inactive
    
    @State private var selectedTemplate: TaskTemplate?  // 添加这行
    
    var body: some View {
        NavigationView {
            List {
                if templates.isEmpty {
                    Text("暂无常用任务")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(templates, id: \.objectID) { template in
                        if editMode == .inactive {
                            Button(action: {
                                onSelect?(template.title ?? "", template.estimatedTime)
                                dismiss()
                            }) {
                                HStack {
                                    Text(template.title ?? "")
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text("\(template.estimatedTime)分钟")
                                        .foregroundColor(.secondary)
                                }
                            }
                        } else {
                            HStack {
                                Text(template.title ?? "")
                                Spacer()
                                Text("\(template.estimatedTime)分钟")
                                    .foregroundColor(.secondary)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedTemplate = template
                            }
                        }
                    }
                    .onDelete(perform: deleteTemplates)
                    .onMove(perform: moveTemplates)
                }
            }
            .navigationTitle("选择常用任务")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if editMode == .inactive {
                        Button("取消") {
                            dismiss()
                        }
                    } else {
                        EditButton()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if editMode == .inactive {
                        Button(action: { showingAddTemplate = true }) {
                            Image(systemName: "plus")
                        }
                    } else {
                        Button("完成") {
                            editMode = .inactive
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    if editMode == .inactive {
                        Button("编辑") {
                            editMode = .active
                        }
                    }
                }
            }
            .environment(\.editMode, $editMode)
        }
        .sheet(isPresented: $showingAddTemplate) {
            NavigationView {
                TaskTemplateEditView()
            }
        }
        .sheet(item: $selectedTemplate) { template in
            NavigationView {
                TaskTemplateEditView(template: template)
            }
        }
    }
    
    private func deleteTemplates(at offsets: IndexSet) {
        for index in offsets {
            viewContext.delete(templates[index])
        }
        try? viewContext.save()
    }
    
    private func moveTemplates(from source: IndexSet, to destination: Int) {
        var revisedItems: [TaskTemplate] = templates.map{ $0 }
        revisedItems.move(fromOffsets: source, toOffset: destination)
        
        for (index, item) in revisedItems.enumerated() {
            item.order = Int32(index)
        }
        
        try? viewContext.save()
    }
}