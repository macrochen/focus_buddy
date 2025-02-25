import SwiftUI

struct InterruptionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedReason: String = InterruptionReason.rest.rawValue  // 改为使用 String 类型
    @State private var note: String = ""
    let session: FocusSession
    let onDismiss: () -> Void
    
    private var allReasons: [String] {
        let defaultReasons = InterruptionReason.allCases.map { $0.rawValue }
        let customReasons = UserDefaults.standard.stringArray(forKey: "CustomInterruptionReasons") ?? []
        return defaultReasons + customReasons
    }
    
    var body: some View {
        NavigationView {
            Form {
                Picker("中断原因", selection: $selectedReason) {
                    ForEach(allReasons, id: \.self) { reason in
                        Text(reason).tag(reason)
                    }
                }
                
                TextField("备注（可选）", text: $note)
                
                NavigationLink("管理中断原因") {
                    InterruptionReasonSettingsView()
                }
            }
            .navigationTitle("记录中断")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { 
                        dismiss()  // 只需要关闭界面，恢复计时的逻辑由 sheet 的 onDismiss 处理
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("确定") { saveInterruption() }
                }
            }
        }
    }
    
    private func saveInterruption() {
        let interruption = Interruption(context: viewContext)
        interruption.id = UUID()
        interruption.startTime = Date()
        interruption.reason = selectedReason  // 直接使用选中的字符串
        interruption.note = note
        interruption.session = session
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error saving interruption: \(error)")
        }
    }
}