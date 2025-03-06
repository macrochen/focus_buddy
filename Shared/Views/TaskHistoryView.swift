import SwiftUI
import CoreData
import Foundation

struct TaskHistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedDate = Date()
    @FetchRequest private var tasks: FetchedResults<FocusTask>
    @State private var showTimeline = true  // 添加这行，控制时间线
    
    init() {
        // 只显示已完成的任务
        let predicate = NSPredicate(format: "status == %@ OR status == %@ OR status == %@",
            "已完成",
            "已中断",
            "进行中"
        )
        
        _tasks = FetchRequest<FocusTask>(
            entity: FocusTask.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \FocusTask.date, ascending: false)],
            predicate: predicate,
            animation: .default
        )
    }
    
    
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
                        TaskTimesPieChart(tasks: tasks)
                    }
                    
                    // 添加时间线视图
                    Section(header: 
                        HStack {
                            Text("时间线")
                            Spacer()
                            Toggle("", isOn: $showTimeline)
                                .labelsHidden()
                        }
                    ) {
                        if showTimeline {
                            TaskTimelineView(tasks: tasks)
                                .frame(height: CGFloat(tasks.count) * 120 + 100)
                                .padding(.vertical)
                        }
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

    // 新增时间线视图
    struct TaskTimelineView: View {
        let tasks: [FocusTask]
        
        // 计算当天的开始和结束时间
        private var dayStartTime: Date {
            let filteredTasks = tasks.filter { $0.startTime != nil }
            if let earliestTask = filteredTasks.min(by: { ($0.startTime ?? Date()) < ($1.startTime ?? Date()) }) {
                // 只显示最早任务前30分钟
                return Calendar.current.date(byAdding: .minute, value: -30, to: earliestTask.startTime ?? Date()) ?? Date()
            }
            return Calendar.current.startOfDay(for: Date())
        }
        
        private var dayEndTime: Date {
            let filteredTasks = tasks.filter { $0.endTime != nil }
            if let latestTask = filteredTasks.max(by: { ($0.endTime ?? Date()) < ($1.endTime ?? Date()) }) {
                // 只显示最晚任务后30分钟
                return Calendar.current.date(byAdding: .minute, value: 30, to: latestTask.endTime ?? Date()) ?? Date()
            }
            return Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        }
        
        // 计算总时间跨度（秒）
        private var totalTimeSpan: TimeInterval {
            return dayEndTime.timeIntervalSince(dayStartTime)
        }
        
        // 将时间转换为相对位置（0-1）
        private func relativePosition(for time: Date) -> CGFloat {
            let timeInterval = time.timeIntervalSince(dayStartTime)
            return CGFloat(timeInterval / totalTimeSpan)
        }
        
        var body: some View {
            GeometryReader { geometry in
                ZStack(alignment: .top) {
                    // 绘制时间轴线（居中）
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                        .frame(height: geometry.size.height)
                    
                    // 绘制时间刻度
                    let hourInterval = Calendar.current.dateComponents([.minute], from: dayStartTime, to: dayEndTime).minute ?? 0 > 180 ? 1 : 0.5
                    ForEach(Array(stride(from: 0, to: 24, by: hourInterval)), id: \.self) { hourFloat in
                        let hour = Int(hourFloat)
                        let minute = hourFloat.truncatingRemainder(dividingBy: 1) * 60
                        if let hourDate = Calendar.current.date(bySettingHour: hour, minute: Int(minute), second: 0, of: dayStartTime) {
                            if hourDate >= dayStartTime && hourDate <= dayEndTime {
                                HStack {
                                    Text(formatHourMinute(hour: hour, minute: Int(minute)))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.5))
                                        .frame(width: 8, height: 1)
                                }
                                .position(
                                    x: geometry.size.width / 2,
                                    y: geometry.size.height * relativePosition(for: hourDate)
                                )
                            }
                        }
                    }
                    
                    // 绘制任务块（交错展示）
                    let sortedTasks = tasks.filter { $0.startTime != nil }
                        .sorted(by: { ($0.startTime ?? Date()) < ($1.startTime ?? Date()) })
                    
                    ForEach(Array(sortedTasks.enumerated()), id: \.element.id) { index, task in
                        if let startTime = task.startTime {
                            let endTime = task.endTime ?? Date()
                            let yStart = geometry.size.height * relativePosition(for: startTime)
                            let yEnd = geometry.size.height * relativePosition(for: endTime)
                            let height = max(yEnd - yStart, 40) // 最小高度
                            
                            // 交错展示（奇数在左，偶数在右）
                            let isLeft = index % 2 == 0
                            
                            // 绘制任务执行区间
                            RoundedRectangle(cornerRadius: 2)
                                .fill(alternateColor(index, task.status ?? "").opacity(0.3))
                                .frame(width: 6)
                                .frame(height: max(yEnd - yStart, 6))
                                .position(x: geometry.size.width / 2, y: (yStart + yEnd) / 2)
                            
                            // 添加中断标记点
                            if let sessions = task.focusSessions as? Set<FocusSession>,
                               let session = sessions.first,
                               let interruptions = session.interruptions as? Set<Interruption>,
                               !interruptions.isEmpty {
                                ForEach(Array(interruptions), id: \.self) { interruption in
                                    if let interruptTime = interruption.startTime {
                                        let yInterrupt = geometry.size.height * relativePosition(for: interruptTime)
                                        Circle()
                                            .fill(Color.red)
                                            .frame(width: 10, height: 10)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white, lineWidth: 1)
                                            )
                                            .position(x: geometry.size.width / 2, y: yInterrupt)
                                    }
                                }
                            }
                            
                            HStack(alignment: .top, spacing: 10) {
                                if !isLeft {
                                    Spacer()
                                }
                                
                                // 任务信息卡片
                                ScrollView {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(task.title ?? "")
                                            .font(.headline)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .lineLimit(nil)
                                        
                                        Text("用时: \(task.actualTime)分钟")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                    }
                                }
                                .padding(8)
                                .background(alternateColor(index, task.status ?? "").opacity(0.1))
                                .cornerRadius(8)
                                // 增加卡片宽度，减小与时间线的距离
                                .frame(maxWidth: geometry.size.width * 0.45, maxHeight: 55)
                                
                                if isLeft {
                                    Spacer()
                                }
                            }
                            .position(
                                // 减小卡片与时间线的距离
                                x: geometry.size.width / 2 + (isLeft ? -geometry.size.width * 0.05 : geometry.size.width * 0.05),
                                y: (yStart + yEnd) / 2
                            )
                            
                            // 连接线
                            Path { path in
                                let startX = geometry.size.width / 2
                                // 减小连接线的长度，让卡片更靠近时间线
                                let endX = geometry.size.width / 2 + (isLeft ? -geometry.size.width * 0.05 : geometry.size.width * 0.05)
                                path.move(to: CGPoint(x: startX, y: (yStart + yEnd) / 2))
                                path.addLine(to: CGPoint(x: endX, y: (yStart + yEnd) / 2))
                            }
                            .stroke(alternateColor(index, task.status ?? ""), lineWidth: 1)
                            
                            // 时间点标记（起点和终点）
                            Circle()
                                .fill(alternateColor(index, task.status ?? ""))
                                .frame(width: 8, height: 8)
                                .position(x: geometry.size.width / 2, y: yStart)
                            
                            Circle()
                                .fill(alternateColor(index, task.status ?? ""))
                                .frame(width: 8, height: 8)
                                .position(x: geometry.size.width / 2, y: yEnd)
                        }
                    }
                }
            }
        }

        // 为相邻任务生成交替颜色
        private func alternateColor(_ index: Int, _ status: String) -> Color {
            // 定义一组明显不同的颜色
            let taskColors: [Color] = [
                .blue,
                .green,
                .orange,
                .purple,
                .pink,
                .teal
            ]
            
            // 直接根据索引选择颜色，确保相邻任务颜色不同
            return taskColors[index % taskColors.count]
        }
        
        private func formatTime(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: date)
        }
        
        private func formatHourMinute(hour: Int, minute: Int) -> String {
            return String(format: "%d:%02d", hour, minute)
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
    
    private func tasksForDate(_ date: Date) -> [FocusTask]? {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        
        let request = FocusTask.fetchRequest()
        // 同时过滤日期和状态
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@ AND (status == %@ OR status == %@ OR status == %@)", 
            start as NSDate, 
            end as NSDate,
            "已完成",
            "已中断",
            "进行中"
        )
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
            if let session = task.focusSessions?.allObjects.first as? FocusSession,
                let interruptions = session.interruptions as? Set<Interruption>,  // Fix the casting here
                !interruptions.isEmpty {
                    allInterruptions.append(contentsOf: interruptions)
            }
        }
        return allInterruptions
    }
    
    private func totalDuration(_ interruptions: [Interruption]) -> Int {
        interruptions.reduce(0) { $0 + Int($1.duration / 60) }
    }
}
