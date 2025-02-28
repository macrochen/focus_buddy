import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedDate = Date()
    @State private var showingAddTask = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 日期选择器
                DateSelectorView(selectedDate: $selectedDate)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                
                // 任务列表
                TaskListView(selectedDate: selectedDate)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: TaskHistoryView()) {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundColor(.blue)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("专注伙伴")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: { showingAddTask = true }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                        
                        NavigationLink(destination: SettingsView()) {
                            Image(systemName: "gear")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                NavigationView {
                    AddTaskView(selectedDate: selectedDate)
                }
            }
        }
    }
}

// 日期选择器视图
struct DateSelectorView: View {
    @Binding var selectedDate: Date
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(-2...7, id: \.self) { offset in
                        let date = Calendar.current.date(byAdding: .day, value: offset, to: Date()) ?? Date()
                        DateCell(date: date, isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate))
                            .onTapGesture {
                                withAnimation {
                                    selectedDate = date
                                }
                            }
                            .id(offset)
                    }
                }
                .padding(.horizontal, 4)
            }
            .onAppear {
                proxy.scrollTo(0, anchor: .center)
            }
        }
    }
}

// 日期单元格视图
struct DateCell: View {
    let date: Date
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Text(dayOfWeek)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(dayNumber)
                .font(.system(size: 20, weight: .medium))
        }
        .frame(width: 45, height: 60)
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
        )
    }
    
    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}