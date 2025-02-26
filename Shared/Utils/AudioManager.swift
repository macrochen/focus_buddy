import AVFoundation
import SwiftUI

class AudioManager {
    static let shared = AudioManager()
    private var synthesizer = AVSpeechSynthesizer()
    
    private init() {}
    
    func speak(_ text: String) {
        guard UserDefaults.standard.bool(forKey: "enableVoicePrompt") else { return }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        utterance.rate = 0.5
        utterance.volume = 0.8
        
        synthesizer.speak(utterance)
    }
}