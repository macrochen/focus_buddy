import SwiftUI
import AudioToolbox

struct SettingsView: View {
    @State private var enableVoicePrompt = UserDefaults.standard.bool(forKey: "enableVoicePrompt")
    @State private var notificationType = UserDefaults.standard.string(forKey: "notificationType") ?? "sound"
    @State private var soundVolume: Double = {
        let volume = UserDefaults.standard.double(forKey: "soundVolume")
        return volume > 0 ? volume : 0.5
    }()
    @State private var enableVibration = UserDefaults.standard.bool(forKey: "enableVibration")
    
    var body: some View {
        Form {
            Section(header: Text("提示设置")) {
                Toggle("语音提示", isOn: Binding(
                    get: { enableVoicePrompt },
                    set: { newValue in
                        enableVoicePrompt = newValue
                        UserDefaults.standard.set(newValue, forKey: "enableVoicePrompt")
                    }
                ))
                
                Picker("提醒方式", selection: Binding(
                    get: { notificationType },
                    set: { newValue in
                        notificationType = newValue
                        UserDefaults.standard.set(newValue, forKey: "notificationType")
                    }
                )) {
                    Text("声音").tag("sound")
                    Text("震动").tag("vibration")
                    Text("声音和震动").tag("both")
                    Text("无").tag("none")
                }
                
                if notificationType == "sound" || notificationType == "both" {
                    VStack {
                        Text("提示音量: \(Int(soundVolume * 100))%")
                        Slider(value: Binding(
                            get: { soundVolume },
                            set: { newValue in
                                soundVolume = newValue
                                UserDefaults.standard.set(newValue, forKey: "soundVolume")
                                // 播放测试音效
                                playTestSound()
                            }
                        ), in: 0...1, step: 0.1)
                    }
                }
                
                if notificationType == "vibration" || notificationType == "both" {
                    Toggle("启用震动", isOn: Binding(
                        get: { enableVibration },
                        set: { newValue in
                            enableVibration = newValue
                            UserDefaults.standard.set(newValue, forKey: "enableVibration")
                            if newValue {
                                // 测试震动
                                playVibration()
                            }
                        }
                    ))
                }
            }
            
            Section {
                Button("测试提醒") {
                    testNotification()
                }
            }
        }
        .navigationTitle("设置")
    }
    
    private func playTestSound() {
        // 播放温和的提示音
        AudioServicesPlaySystemSound(1103) // 使用系统提示音
    }
    
    private func playVibration() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
    
    private func testNotification() {
        switch notificationType {
        case "sound":
            playTestSound()
        case "vibration":
            if enableVibration {
                playVibration()
            }
        case "both":
            playTestSound()
            if enableVibration {
                playVibration()
            }
        default:
            break
        }
    }
}