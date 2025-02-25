import SwiftUI
import CoreData

struct StatsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FocusSession.startTime, ascending: false)],
        animation: .default)
    private var sessions: FetchedResults<FocusSession>
    
    private var totalFocusTime: TimeInterval {
        sessions.reduce(0) { $0 + TimeInterval($1.actualDuration) }
    }
    
    private var dailySessions: [Date: [FocusSession]] {
        Dictionary(grouping: sessions) { session in
            Calendar.current.startOfDay(for: session.startTime ?? Date())
        }
    }
    
    private var taskCompletion: (completed: Int, total: Int) {
        let tasks = (try? viewContext.fetch(FocusTask.fetchRequest())) ?? []
        let completed = tasks.filter { $0.status == "已完成" }.count
        return (completed, tasks.count)
    }
    
    var body: some View {
        List {
            Section("总体统计") {
                HStack {
                    Text("专注总时长")
                    Spacer()
                    Text("\(Int(totalFocusTime / 60))分钟")
                }
                
                HStack {
                    Text("专注次数")
                    Spacer()
                    Text("\(sessions.count)次")
                }
                
                HStack {
                    Text("平均专注时长")
                    Spacer()
                    Text("\(sessions.isEmpty ? 0 : Int(totalFocusTime / Double(sessions.count) / 60))分钟")
                }
                
                HStack {
                    Text("任务完成率")
                    Spacer()
                    Text("\(taskCompletion.total == 0 ? 0 : Int(Double(taskCompletion.completed) / Double(taskCompletion.total) * 100))%")
                }
            }
            
            Section("任务状态") {
                HStack {
                    Text("已完成任务")
                    Spacer()
                    Text("\(taskCompletion.completed)个")
                }
                
                HStack {
                    Text("总任务数")
                    Spacer()
                    Text("\(taskCompletion.total)个")
                }
            }
            
            Section("每日专注") {
                ForEach(dailySessions.sorted(by: { $0.key > $1.key }), id: \.key) { date, sessions in
                    HStack {
                        Text(formatDate(date))
                        Spacer()
                        Text("\(Int(sessions.reduce(0) { $0 + TimeInterval($1.actualDuration) } / 60))分钟")
                    }
                }
            }
            
            Section("可视化统计") {
                // 任务完成进度条
                VStack(alignment: .leading, spacing: 8) {
                    Text("任务完成情况")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 20)
                            
                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: taskCompletion.total == 0 ? 0 : 
                                       geometry.size.width * CGFloat(taskCompletion.completed) / CGFloat(taskCompletion.total),
                                       height: 20)
                        }
                        .cornerRadius(10)
                    }
                    .frame(height: 20)
                }
                .padding(.vertical, 8)
                
                // 每日专注时间柱状图
                VStack(alignment: .leading, spacing: 8) {
                    Text("近7天专注时间")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(alignment: .bottom, spacing: 4) {
                        ForEach(Array(dailySessions.sorted(by: { $0.key > $1.key }).prefix(7).reversed()), id: \.key) { date, sessions in
                            let minutes = Int(sessions.reduce(0) { $0 + TimeInterval($1.actualDuration) } / 60)
                            VStack {
                                Text("\(minutes)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Rectangle()
                                    .fill(Color.blue)
                                    .frame(width: 20, height: CGFloat(minutes))
                                Text(formatShortDate(date))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(height: 150)
                }
                .padding(.vertical, 8)
            }
            
            // 在 Section("可视化统计") 中添加
            VStack(alignment: .leading, spacing: 8) {
                Text("近7天任务完成趋势")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(weeklyCompletion, id: \.date) { stat in
                        VStack {
                            Text("\(stat.completed)/\(stat.total)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            ZStack(alignment: .bottom) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 30, height: 100)
                                Rectangle()
                                    .fill(Color.green)
                                    .frame(width: 30, height: stat.total == 0 ? 0 : CGFloat(stat.completed) / CGFloat(stat.total) * 100)
                            }
                            .cornerRadius(6)
                            Text(formatShortDate(stat.date))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(height: 150)
            }
            .padding(.vertical, 8)
        }
        .navigationTitle("专注统计")
    }
            
    private var weeklyCompletion: [(date: Date, completed: Int, total: Int)] {
        let calendar = Calendar.current
        let today = Date()
        let weekDates = (0..<7).map { day in
            calendar.date(byAdding: .day, value: -day, to: today)!
        }.reversed()
        
        let tasks = (try? viewContext.fetch(FocusTask.fetchRequest())) ?? []
        
        return weekDates.map { date in
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            let dayTasks = tasks.filter {
                guard let taskDate = $0.createdAt else { return false }
                return taskDate >= dayStart && taskDate < dayEnd
            }
            
            let completed = dayTasks.filter { $0.status == "已完成" }.count
            return (date: date, completed: completed, total: dayTasks.count)
        }
    }
            
    // 添加新的日期格式化方法
    private func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"
        return formatter.string(from: date)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd"
        return formatter.string(from: date)
    }
}