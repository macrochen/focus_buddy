import Foundation
import Combine
import CoreData
import SwiftUI

class TimerManager: ObservableObject {
    @Published var isRunning = false
    @Published var elapsedTime: Int = 0
    @Published var isOvertime = false
    var startTime: Date?
    var timer: Timer?
    var currentSession: FocusSession?
    private let task: FocusTask
    private let context: NSManagedObjectContext
    
    init(task: FocusTask, context: NSManagedObjectContext) {
        self.task = task
        self.context = context
    }
    
    private func createNewSession() {
        // 检查是否已有未完成的会话
        let fetchRequest: NSFetchRequest<FocusSession> = FocusSession.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "task == %@ AND endTime == nil", task)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \FocusSession.startTime, ascending: false)]
        fetchRequest.fetchLimit = 1
        
        do {
            let existingSessions = try context.fetch(fetchRequest)
            if let existingSession = existingSessions.first {
                // 如果有未完成的会话，使用它
                currentSession = existingSession
            } else {
                // 创建新会话
                let session = FocusSession(context: context)
                session.startTime = Date()
                session.task = task
                currentSession = session
                try context.save()
            }
        } catch {
            print("Error fetching or creating session: \(error)")
        }
    }
    
    private var hasPlayedHalfwayPrompt = false
    private var hasPlayedNearEndPrompt = false
    
    // 移除 @AppStorage，改用 UserDefaults
    private var enableVoicePrompt: Bool {
        UserDefaults.standard.bool(forKey: "enableVoicePrompt")
    }
    
    func start(totalMinutes: Int32) {
        if timer == nil {
            startTime = Date()
            task.startTime = Date() 
            try? context.save()
            createNewSession()
        }
        
        isRunning = true
        hasPlayedHalfwayPrompt = false
        hasPlayedNearEndPrompt = false
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.elapsedTime += 1
            
            // 检查是否到达一半时间
            let halfwayPoint = Int(totalMinutes * 60) / 2
            if self.elapsedTime == halfwayPoint && !self.hasPlayedHalfwayPrompt {
                AudioManager.shared.speak("时间已经过一半啦，继续加油！")
                self.hasPlayedHalfwayPrompt = true
            }
            
            // 检查是否接近结束（还剩2分钟或一半时间）
            let remainingSeconds = Int(totalMinutes * 60) - self.elapsedTime
            let warningPoint = min(120, Int(totalMinutes * 60) / 4)  // 取2分钟或总时长1/4的较小值
            if remainingSeconds == warningPoint && !self.hasPlayedNearEndPrompt && totalMinutes > 1 {
                if totalMinutes <= 2 {
                    AudioManager.shared.speak("还剩30秒，即将完成！")
                } else {
                    AudioManager.shared.speak("还剩\(warningPoint/60)分钟，即将完成！")
                }
                self.hasPlayedNearEndPrompt = true
            }
            
            // 检查是否超时
            if self.elapsedTime >= Int(totalMinutes * 60) {
                self.isOvertime = true
                // 不停止计时器，继续记录时间
            }
        }
    }
    
    func formatTime() -> String {
        let minutes = elapsedTime / 60
        let seconds = elapsedTime % 60
        let prefix = isOvertime ? "+" : ""  // 超时显示加号
        return String(format: "\(prefix)%02d:%02d", minutes, seconds)
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        
        // 更新任务的实际用时
        if let startTime = startTime {
            task.actualTime = Int32(Date().timeIntervalSince(startTime) / 60)
            task.endTime = Date()
            try? context.save()
        }
    }
    
    func pause() {
        // 确保计时器被完全停止
        timer?.invalidate()
        timer = nil
        isRunning = false
        
        // 记录当前已经过去的时间，但不结束任务
        if let startTime = startTime {
            let currentElapsed = Int32(Date().timeIntervalSince(startTime) / 60)
            task.actualTime = currentElapsed
            try? context.save()
        }
    }
    
    func resume() {
        // 先处理未完成的中断记录
        if let currentSession = currentSession,
           let interruptions = currentSession.interruptions?.allObjects as? [Interruption],
           let lastInterruption = interruptions.last,
           lastInterruption.duration == 0 {
            // 记录中断结束时间和持续时间
            let endTime = Date()
            lastInterruption.endTime = endTime
            lastInterruption.duration = Int32(endTime.timeIntervalSince(lastInterruption.startTime ?? endTime))
            try? context.save()
        }
        
        // 恢复计时，继续从暂停的地方开始
        if timer == nil {  // 确保没有活动的计时器
            isRunning = true
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                self.elapsedTime += 1
                
                // 检查是否超时
                if self.elapsedTime >= Int(self.task.estimatedTime * 60) {
                    self.isOvertime = true
                }
            }
        }
    }
}
