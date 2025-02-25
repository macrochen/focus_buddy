import SwiftUI
import CoreData
import Foundation

struct TaskHistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedDate = Date()
    
    var body: some View {
        List {
            DatePicker("选择日期", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .environment(\.locale, Locale(identifier: "zh_CN"))
                .environment(\.calendar, Calendar(identifier: .gregorian))
            
            if let tasks = tasksForDate(selectedDate) {
                if !tasks.isEmpty {
                    Section {
                        DailySummaryView(tasks: tasks)
                    }
                    
                    Section {
                        ForEach(tasks) { task in
                            TaskHistoryRow(task: task)
                        }
                    }
                } else {
                    Text("当天没有任务记录")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
            }
        }
        .navigationTitle("历史记录")
    }
    
    private func tasksForDate(_ date: Date) -> [FocusTask]? {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        
        let request = FocusTask.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", start as NSDate, end as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \FocusTask.startTime, ascending: true)]
        
        return try? viewContext.fetch(request)
    }
}

struct TaskHistoryRow: View {
    let task: FocusTask
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 任务标题和状态
            HStack {
                Text(task.title ?? "")
                    .font(.headline)
                Spacer()
                Text(task.status ?? "未知")
                    .foregroundColor(statusColor(task.status ?? ""))
            }
            
            // 时间信息
            if let startTime = task.startTime {
                HStack {
                    Text("开始：\(formatTime(startTime))")
                    Spacer()
                    if let endTime = task.endTime {
                        Text("结束：\(formatTime(endTime))")
                    }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            
            // 时长信息
            HStack {
                Text("计划时长：\(task.estimatedTime)分钟")
                Spacer()
                Text("实际用时：\(task.actualTime)分钟")
            }
            .font(.subheadline)
            
            // 添加中断记录显示
            if let sessions = task.focusSessions as? Set<FocusSession> {
                ForEach(Array(sessions), id: \.self) { session in
                    if let interruptions = session.interruptions as? Set<Interruption>,
                       !interruptions.isEmpty {
                        Divider()
                        VStack(alignment: .leading, spacing: 4) {
                            Text("中断记录")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            ForEach(Array(interruptions).sorted(by: { ($0.startTime ?? Date()) < ($1.startTime ?? Date()) }), id: \.id) { interruption in
                                HStack {
                                    Text(interruption.reason ?? "未知原因")
                                    if let note = interruption.note, !note.isEmpty {
                                        Text("(\(note))")
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    if let start = interruption.startTime {
                                        Text("\(formatTime(start))")
                                        Text("(\(Int(interruption.duration / 60))分钟)")
                                    }
                                }
                                .font(.caption)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func statusColor(_ status: String) -> Color {
        switch status {
        case "已完成":
            return .green
        case "已中断":
            return .red
        case "进行中":
            return .blue
        default:
            return .secondary
        }
    }
}

struct InterruptionRow: View {
    let interruption: Interruption
    
    var body: some View {
        HStack {
            Text(interruption.reason ?? "")
            Spacer()
            if let start = interruption.startTime,
               let end = interruption.endTime {
                Text("\(formatDuration(end.timeIntervalSince(start)))")
                    .foregroundColor(.secondary)
            }
        }
        .font(.subheadline)
        .foregroundColor(.secondary)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        return "\(minutes)分钟"
    }
}
struct DailySummaryView: View {
    let tasks: [FocusTask]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("每日统计")
                .font(.headline)
                .padding(.bottom, 4)
            
            // 任务统计
            HStack {
                Text("总任务数：\(tasks.count)")
                Spacer()
                Text("已完成：\(tasks.filter { $0.status == "已完成" }.count)")
            }
            .font(.subheadline)
            
            // 时间统计
            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("计划总时长")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(totalEstimatedTime)分钟")
                        .font(.headline)
                }
                
                Divider()
                
                VStack(alignment: .leading) {
                    Text("实际总用时")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(totalActualTime)分钟")
                        .font(.headline)
                }
            }
            .padding(.vertical, 4)
            .font(.subheadline)
            
            // 中断统计
            let interruptions = getAllInterruptions()
            if !interruptions.isEmpty {
                Text("中断统计：")
                    .font(.subheadline)
                ForEach(Array(Dictionary(grouping: interruptions, by: { $0.reason ?? "未知" })
                    .sorted(by: { $0.value.count > $1.value.count })), id: \.key) { reason, items in
                    HStack {
                        Text("\(reason)")
                        Spacer()
                        Text("\(items.count)次")
                        Text("(\(totalDuration(items))分钟)")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    private var totalEstimatedTime: Int {
        tasks.reduce(0) { $0 + Int($1.estimatedTime) }
    }
    
    private var totalActualTime: Int {
        tasks.reduce(0) { $0 + Int($1.actualTime) }
    }
    
    private func getAllInterruptions() -> [Interruption] {
        var allInterruptions: [Interruption] = []
        for task in tasks {
            if let interruptions = task.interruptions as? Set<Interruption> {
                allInterruptions.append(contentsOf: interruptions)
            }
        }
        return allInterruptions
    }
    
    private func totalDuration(_ interruptions: [Interruption]) -> Int {
        interruptions.reduce(0) { $0 + Int($1.duration / 60) }
    }
}
