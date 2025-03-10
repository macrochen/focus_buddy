import WidgetKit
import SwiftUI
import CoreData
import AppIntents

struct TimerEntry: TimelineEntry {
    let date: Date
    let taskTitle: String
    let elapsedTime: Int
    let totalTime: Int
}

struct NoConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "专注计时"
    static var description: LocalizedStringResource = "显示当前专注任务的进度"
    
    func perform() async throws -> some IntentResult {
        return .result()
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> TimerEntry {
        TimerEntry(date: Date(), taskTitle: "专注任务", elapsedTime: 0, totalTime: 25)
    }

    func getSnapshot(in context: Context, completion: @escaping (TimerEntry) -> ()) {
        let entry = TimerEntry(date: Date(), taskTitle: "阅读", elapsedTime: 15, totalTime: 25)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TimerEntry>) -> ()) {
        let shared = UserDefaults(suiteName: "group.com.macrochen.focusbuddy")
        let taskTitle = shared?.string(forKey: "currentTaskTitle") ?? "无任务"
        let startTime = shared?.object(forKey: "taskStartTime") as? Date
        let totalTime = shared?.integer(forKey: "taskTotalTime") ?? 0
        
        var entries: [TimerEntry] = []
        let currentDate = Date()
        
        if let startTime = startTime {
            let elapsedTime = Int(currentDate.timeIntervalSince(startTime) / 60)
            let entry = TimerEntry(
                date: currentDate,
                taskTitle: taskTitle,
                elapsedTime: elapsedTime,
                totalTime: totalTime
            )
            entries.append(entry)
        } else {
            entries.append(TimerEntry(
                date: currentDate,
                taskTitle: "无进行中的任务",
                elapsedTime: 0,
                totalTime: 0
            ))
        }
        
        let timeline = Timeline(entries: entries, policy: .after(Date().addingTimeInterval(60)))
        completion(timeline)
    }
}

struct FocusBuddyWidgetEntryView : View {
    var entry: Provider.Entry
    
    var body: some View {
        VStack(spacing: 8) {
            Text(entry.taskTitle)
                .font(.headline)
                .lineLimit(1)
            
            if entry.totalTime > 0 {
                Text("\(entry.elapsedTime)/\(entry.totalTime)分钟")
                    .font(.system(.title2, design: .rounded))
                    .bold()
                
                ProgressView(value: Double(entry.elapsedTime), total: Double(entry.totalTime))
                    .progressViewStyle(.linear)
                    .tint(.blue)
            } else {
                Text("暂无进行中的任务")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground)) // 替换 containerBackground
    }
}

struct FocusBuddyWidget: Widget {
    let kind: String = "FocusBuddyWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            FocusBuddyWidgetEntryView(entry: entry)
                .background(Color(UIColor.systemBackground))
        }
        .configurationDisplayName("专注计时")
        .description("显示当前专注任务的进度")
        .supportedFamilies([.systemSmall, .systemMedium]) // 添加对中尺寸的支持
    }
}

// 修改预览代码
struct FocusBuddyWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // 小尺寸预览
            FocusBuddyWidgetEntryView(entry: TimerEntry(
                date: Date(),
                taskTitle: "阅读",
                elapsedTime: 15,
                totalTime: 25
            ))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("小尺寸")
            
            // 中尺寸预览
            FocusBuddyWidgetEntryView(entry: TimerEntry(
                date: Date(),
                taskTitle: "阅读",
                elapsedTime: 15,
                totalTime: 25
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("中尺寸")
        }
    }
}
