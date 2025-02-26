import SwiftUI

struct InterruptionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedReason: String = InterruptionReason.rest.rawValue  // 改为使用 String 类型
    @State private var note: String = ""
    let session: FocusSession
    let onDismiss: (Bool) -> Void  // 添加 confirmed 参数
    
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
        // 先检查是否有进行中的中断记录
        if let interruptions = session.interruptions?.allObjects as? [Interruption],
           let lastInterruption = interruptions.last,
           lastInterruption.duration == 0 {
            // 如果有未完成的中断，先结束它
            let endTime = Date()
            lastInterruption.endTime = endTime
            lastInterruption.duration = Int32(endTime.timeIntervalSince(lastInterruption.startTime ?? endTime))
        }
        
        // 创建新的中断记录
        let interruption = Interruption(context: viewContext)
        interruption.id = UUID()
        interruption.startTime = Date()
        interruption.reason = selectedReason  // 直接使用选中的字符串
        interruption.note = note
        interruption.session = session
        
        do {
            try viewContext.save()
            onDismiss(true)  // 确认中断
        } catch {
            print("Error saving interruption: \(error)")
        }
    }
    
    // 取消按钮动作
    private func cancel() {
        onDismiss(false)  // 取消中断
    }
}