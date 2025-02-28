import SwiftUI

struct TaskTimesPieChart: View {
    let tasks: [FocusTask]

    private func colorForIndex(_ index: Int) -> Color {
        let colors: [Color] = [
            .blue, .yellow, .green, .orange, .purple, .pink,
            .red, .cyan, .indigo, .mint, .teal, .brown
        ]
        return colors[index % colors.count]
    }
    
    private var pieSlices: [PieSlice] {
        // 只使用有实际用时的任务
        let validTasks = tasks.filter { $0.actualTime > 0 }
        
        // 按标题分组并合并时间
        let groupedTasks = Dictionary(grouping: validTasks) { $0.title ?? "" }
        let mergedTasks = groupedTasks.map { (title, tasks) -> (String, Double) in
            let totalTime = tasks.reduce(0.0) { $0 + Double($1.actualTime) }
            return (title, totalTime)
        }
        
        let total = mergedTasks.reduce(0.0) { $0 + $1.1 }
        
        guard total > 0 else { return [] }
        
        return mergedTasks.map { title, value in
            let percentage = value / total
            return PieSlice(
                title: title,
                value: value,
                percentage: percentage
            )
        }.sorted { $0.value > $1.value }
    }
    
    var body: some View {
        VStack {
            Text("任务时间占比")
                .font(.headline)
                .padding(.bottom, 4)
            
            GeometryReader { geometry in
                let radius = min(geometry.size.width, geometry.size.height) / 2
                ZStack {
                    ForEach(0..<pieSlices.count, id: \.self) { index in
                        let slice = pieSlices[index]
                        PieSliceView(
                            startAngle: startAngle(at: index),
                            endAngle: endAngle(at: index),
                            radius: radius,
                            title: slice.title,
                            percentage: slice.percentage,
                            pieSlices: pieSlices
                        )
                    }
                }
                .frame(width: radius * 2, height: radius * 2)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
            .frame(height: 200)
            
            // 图例
            VStack(alignment: .leading, spacing: 4) {
                ForEach(pieSlices, id: \.title) { slice in
                    HStack {
                        Circle()
                            .fill(colorForIndex(pieSlices.firstIndex(where: { $0.title == slice.title }) ?? 0))
                            .frame(width: 10, height: 10)
                        Text(slice.title)
                            .font(.caption)
                        Text("(\(Int(slice.value))分钟)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.1f%%", slice.percentage * 100))
                            .font(.caption)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func startAngle(at index: Int) -> Double {
        let precedingRatios = pieSlices[..<index].map { $0.percentage }
        let startRatio = precedingRatios.reduce(0, +)
        return startRatio * 360
    }
    
    private func endAngle(at index: Int) -> Double {
        startAngle(at: index) + (pieSlices[index].percentage * 360)
    }
}

struct PieSlice: Identifiable {
    let id = UUID()
    let title: String
    let value: Double
    let percentage: Double
}

struct PieSliceView: View {
    let startAngle: Double
    let endAngle: Double
    let radius: CGFloat
    let title: String
    let percentage: Double
    let pieSlices: [PieSlice]
    
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: radius, y: radius))
            path.addArc(center: CGPoint(x: radius, y: radius),
                       radius: radius,
                       startAngle: Angle(degrees: startAngle - 90),
                       endAngle: Angle(degrees: endAngle - 90),
                       clockwise: false)
            path.closeSubpath()
        }
        .fill(colorForIndex(pieSlices.firstIndex(where: { $0.title == title }) ?? 0))
    }

    private func colorForIndex(_ index: Int) -> Color {
        let colors: [Color] = [
            .blue, .yellow, .green, .orange, .purple, .pink,
            .red, .cyan, .indigo, .mint, .teal, .brown
        ]
        return colors[index % colors.count]
    }
}