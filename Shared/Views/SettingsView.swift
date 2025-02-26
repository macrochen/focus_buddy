import SwiftUI

struct SettingsView: View {
    @State private var enableVoicePrompt = UserDefaults.standard.bool(forKey: "enableVoicePrompt")
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("提示设置")) {
                    Toggle("语音提示", isOn: Binding(
                        get: { enableVoicePrompt },
                        set: { newValue in
                            enableVoicePrompt = newValue
                            UserDefaults.standard.set(newValue, forKey: "enableVoicePrompt")
                        }
                    ))
                }
            }
            .navigationTitle("设置")
        }
    }
}
