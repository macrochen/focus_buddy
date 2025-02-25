import SwiftUI

struct InterruptionReasonSettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var newReason: String = ""
    @State private var customReasons: [String] = UserDefaults.standard.stringArray(forKey: "CustomInterruptionReasons") ?? []
    
    var body: some View {
        List {
            Section(header: Text("默认原因")) {
                ForEach(InterruptionReason.allCases, id: \.self) { reason in
                    Text(reason.rawValue)
                        .foregroundColor(.gray)
                }
            }
            
            Section(header: Text("自定义原因")) {
                ForEach(customReasons, id: \.self) { reason in
                    Text(reason)
                }
                .onDelete(perform: deleteReason)
                
                HStack {
                    TextField("添加新原因", text: $newReason)
                    Button(action: addNewReason) {
                        Image(systemName: "plus.circle.fill")
                    }
                    .disabled(newReason.isEmpty)
                }
            }
        }
        .navigationTitle("中断原因管理")
    }
    
    private func addNewReason() {
        guard !newReason.isEmpty else { return }
        var reasons = UserDefaults.standard.stringArray(forKey: "CustomInterruptionReasons") ?? []
        reasons.append(newReason)
        UserDefaults.standard.set(reasons, forKey: "CustomInterruptionReasons")
        customReasons = reasons  // 更新当前视图的数据
        newReason = ""
    }
    
    private func deleteReason(at offsets: IndexSet) {
        customReasons.remove(atOffsets: offsets)
        UserDefaults.standard.set(customReasons, forKey: "CustomInterruptionReasons")
    }
}