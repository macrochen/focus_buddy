import SwiftUI
import CoreData

struct TaskTemplateListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TaskTemplate.order, ascending: true)],
        animation: .default)
    private var templates: FetchedResults<TaskTemplate>
    
    @State private var showingAddTemplate = false
    @State private var isEditing = false
    @State private var showingEditTemplate = false
    @State private var templateToEdit: TaskTemplate?
    
    var body: some View {
        List {
            ForEach(templates, id: \.objectID) { template in
                HStack {
                    Text(template.title ?? "")
                    Spacer()
                    Text("\(template.estimatedTime)分钟")
                        .foregroundColor(.secondary)
                }
                .swipeActions(edge: .leading) {
                    Button {
                        showingEditTemplate = true
                        templateToEdit = template
                    } label: {
                        Label("编辑", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
            }
            .onMove { source, destination in
                var items = templates.map { $0 }
                items.move(fromOffsets: source, toOffset: destination)
                // 更新排序
                for (index, item) in items.enumerated() {
                    item.order = Int32(index)
                }
                try? viewContext.save()
            }
            .onDelete { indexSet in
                indexSet.map { templates[$0] }.forEach(viewContext.delete)
                try? viewContext.save()
            }
        }
        .navigationTitle("常用任务")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                EditButton()
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddTemplate = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddTemplate) {
            NavigationView {
                TaskTemplateEditView()
            }
        }
        .sheet(isPresented: $showingEditTemplate) {
            NavigationView {
                TaskTemplateEditView(template: templateToEdit)
            }
        }
    }
}