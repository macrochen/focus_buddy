import SwiftUI
import CoreData

struct TimerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var timerManager: TimerManager
    @State private var showingExitAlert = false
    private let task: FocusTask
    @State private var showingInterruptionView = false
    @State private var showingCompletionAlert = false  // 添加在其他 @State 变量旁边
    
    init(task: FocusTask) {
        self.task = task
        let context = FocusBuddyPersistence.shared.container.viewContext
        _timerManager = StateObject(wrappedValue: TimerManager(task: task, context: context))
    }
    
    private var estimatedEndTime: String {
        guard let startTime = timerManager.startTime else { return "未开始" }
        let endTime = startTime.addingTimeInterval(TimeInterval(task.estimatedTime * 60))
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: endTime)
    }
    
    var body: some View {
        VStack(spacing: 30) {
            Text(task.title ?? "")
                .font(.title)
                .padding()
            
            Text("\(task.estimatedTime)分钟")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 10) {
                Text(timerManager.formatTime())
                    .font(.system(size: 60, weight: .bold, design: .rounded))
                    .frame(height: 100)
                    .foregroundColor(timerManager.isOvertime ? .red : .primary)  // 超时显示红色
                
                if timerManager.isOvertime {
                    Text("已超出预计时间")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                Text("预计完成时间: \(estimatedEndTime)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            
            HStack(spacing: 30) {
                Button(action: {
                    if timerManager.isRunning {
                        // 如果计时器正在运行，显示中断记录界面
                        showingInterruptionView = true
                    } else if timerManager.currentSession == nil {
                        // 如果没有会话，先启动计时器创建会话
                        timerManager.start(totalMinutes: task.estimatedTime)
                    } else {
                        // 如果已有会话且计时器暂停，恢复计时
                        timerManager.resume()
                    }
                }) {
                    Image(systemName: timerManager.isRunning ? "pause.circle.fill" : "play.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.blue)
                }
                
                Button(action: {
                    // 完成任务时的处理
                    timerManager.stop()
                    task.status = "已完成"
                    task.date = Date()  // 记录完成时间
                    try? viewContext.save()
                    showingCompletionAlert = true
                }) {
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.green)
                }
            }
            
            // 显示当前任务的中断记录列表
            if let currentSession = timerManager.currentSession,
               let interruptions = currentSession.interruptions?.allObjects as? [Interruption],
               !interruptions.isEmpty {
                VStack(spacing: 8) {
                    Text("本次中断记录")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // 按时间倒序显示所有中断记录
                    ForEach(interruptions.sorted { ($0.startTime ?? Date()) > ($1.startTime ?? Date()) }, id: \.id) { interruption in
                        HStack {
                            Text(interruption.reason ?? "未知原因")
                            Spacer()
                            if interruption.duration > 0 {
                                Text("\(Int(interruption.duration / 60))分钟")
                            } else {
                                Text("进行中")
                                    .foregroundColor(.blue)
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
            }
        }
        .sheet(isPresented: $showingInterruptionView) {
            if let currentSession = timerManager.currentSession {
                InterruptionView(session: currentSession, onDismiss: { confirmed in
                    if confirmed {
                        timerManager.pause()
                    }
                    showingInterruptionView = false
                })
            }
        }
        
        .navigationTitle("专注计时")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(timerManager.isRunning || timerManager.elapsedTime > 0)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Group {
                    if timerManager.isRunning || timerManager.elapsedTime > 0 {  // 修改这行
                        Button("返回") {
                            showingExitAlert = true
                        }
                    }
                }
            }
        }
        .alert("确认返回", isPresented: $showingExitAlert) {
            Button("取消", role: .cancel) { }
            Button("返回", role: .destructive) {
                timerManager.stop()  // 修改这行，从 pause 改为 stop
                // 更新任务状态为已中断
                task.status = "已中断"
                try? viewContext.save()
                dismiss()
            }
        } message: {
            Text("任务正在进行中，返回将终止该任务，下次将重新开始计时！")
        }
        .alert("太棒了！", isPresented: $showingCompletionAlert) {
            Button("耶！") {
                dismiss()
            }
        } message: {
            Text(completionMessages.randomElement() ?? "恭喜完成任务！")
        }
    }
}

private let completionMessages = [
        "哇！你绝对是学习小达人！💪",
        "又完成一项任务，你真是太厉害了！🌟",
        "继续保持，你就是最强王者！👑",
        "这波操作很秀啊！学习达人就是你！✨",
        "太强了！这个任务被你轻松拿下！🎯",
        "学习小超人，继续冲呀！🚀",
        "这么快就完成了，你是最棒的！🏆",
        "又完成一项挑战，你真是太厉害了！🎉"
    ]
