import SwiftUI
import CoreData

struct InterruptionStatsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Interruption.startTime, ascending: false)],
        animation: .default)
    private var interruptions: FetchedResults<Interruption>
    
    private var totalInterruptions: Int {
        interruptions.count
    }
    
    private var totalDuration: TimeInterval {
        interruptions.reduce(0) { $0 + TimeInterval($1.duration) } 
    }
    
    private var reasonDistribution: [String: Int] {
        Dictionary(grouping: interruptions, by: { $0.reason ?? "未知" })
            .mapValues { $0.count }
    }
    
    private var averageDuration: TimeInterval {
        guard !interruptions.isEmpty else { return 0 }
        return totalDuration / Double(interruptions.count)
    }
    
    private var dailyInterruptions: [Date: [Interruption]] {
        Dictionary(grouping: interruptions) { interruption in
            Calendar.current.startOfDay(for: interruption.startTime ?? Date())
        }
    }
    
    var body: some View {
        List {
            Section("总体统计") {
                HStack {
                    Text("中断总次数")
                    Spacer()
                    Text("\(totalInterruptions)次")
                }
                
                HStack {
                    Text("总中断时长")
                    Spacer()
                    Text("\(Int(totalDuration / 60))分钟")
                }
                
                HStack {
                    Text("平均中断时长")
                    Spacer()
                    Text("\(Int(averageDuration / 60))分钟")
                }
            }
            
            Section("每日中断") {
                ForEach(dailyInterruptions.sorted(by: { $0.key > $1.key }), id: \.key) { date, interruptions in
                    HStack {
                        Text(formatDate(date))
                        Spacer()
                        Text("\(interruptions.count)次")
                    }
                }
            }
            
            Section("中断原因分布") {
                ForEach(reasonDistribution.sorted(by: { $0.value > $1.value }), id: \.key) { reason, count in
                    HStack {
                        Text(reason)
                        Spacer()
                        Text("\(count)次")
                    }
                }
            }
        }
        .navigationTitle("中断统计")
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd"
        return formatter.string(from: date)
    }
}