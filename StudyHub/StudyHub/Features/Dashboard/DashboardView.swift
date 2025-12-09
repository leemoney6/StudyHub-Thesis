import SwiftUI
import Combine

struct DashboardView: View {
    @Binding var selectedTab: AppTab
    
    @State private var currentTime = Date()
    @State private var breathingAnimation = false
    
    @StateObject private var timerViewModel = PomodoroTimerViewModel()
    @StateObject private var taskViewModel = TaskViewModel()
    
    var body: some View {
        GeometryReader { _ in
            ZStack {
                enhancedBackground
                
                ScrollView {
                    VStack(spacing: 24) {
                        welcomeHeader
                        progressSection
                        quickActionsSection
                        recentActivitySection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
        }
        .onAppear {
            startTimeUpdates()
        }
    }
    
    // MARK: - Time updates
    private func startTimeUpdates() {
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            currentTime = Date()
        }
        breathingAnimation = true
    }
    

}

// MARK: - Dashboard Components
private extension DashboardView {
    
    // MARK: Welcome header
    var welcomeHeader: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(greeting)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("Ready to achieve your study goals?")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                GIFView(gifName: "studyhub-brain-icon")
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    .scaleEffect(breathingAnimation ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(), value: breathingAnimation)
            }
            
            VStack(spacing: 4) {
                Text(currentTime, style: .time)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(currentTime, style: .date)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.08))
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial.opacity(0.8))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: currentTime)
        switch hour {
        case 0..<12: return "Good morning! ☀️"
        case 12..<17: return "Good afternoon! 🌤️"
        case 17..<21: return "Good evening! 🌅"
        default: return "Good night! 🌙"
        }
    }
    
    // MARK: Today's Progress (REAL DATA)
    var progressSection: some View {
        // Focus time
        let focusMinutes = Int(timerViewModel.todayFocusTime / 60)
        let focusHours = focusMinutes / 60
        let focusRemainderMinutes = focusMinutes % 60
        let focusLabel: String = focusHours > 0
            ? "\(focusHours)h \(focusRemainderMinutes)m"
            : "\(focusMinutes)m"
        
        // Tasks
        let totalTasks = taskViewModel.tasks.count
        let completedTasks = taskViewModel.tasks.filter { $0.isCompleted }.count
        let tasksLabel = totalTasks > 0 ? "\(completedTasks)/\(totalTasks)" : "0/0"
        
        // Sessions
        let sessionsLabel = "\(timerViewModel.todaySessions)"
        
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Today's Progress")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                if timerViewModel.isLoadingSessions {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .cyan))
                        .scaleEffect(0.8)
                }
            }
            
            HStack(spacing: 12) {
                StatCard(
                    title: "Study Time",
                    value: focusLabel,
                    icon: "clock.fill",
                    color: .orange
                )
                
                StatCard(
                    title: "Tasks",
                    value: tasksLabel,
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                StatCard(
                    title: "Sessions",
                    value: sessionsLabel,
                    icon: "timer",
                    color: .blue
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.08))
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial.opacity(0.8))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    // MARK: Quick Actions (Tab Switching)
    var quickActionsSection: some View {
        QuickActionsSection(selectedTab: $selectedTab)
    }
    
    // MARK: Recent Activity (REAL SESSIONS)
    var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            if timerViewModel.recentSessions.isEmpty && taskViewModel.tasks.isEmpty {
                Text("No recent activity yet. Start a focus session or add a task!")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.leading)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(timerViewModel.recentSessions.prefix(3)), id: \.id) { session in
                        activityRow(
                            sessionTitle(for: session),
                            time: session.displayDuration,
                            color: session.type.color,
                            timeAgo: timeAgoString(from: session.startTime)
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.08))
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial.opacity(0.8))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    func activityRow(_ title: String, time: String, color: Color, timeAgo: String) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color.opacity(0.3))
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .stroke(color, lineWidth: 2)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(time)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Text(timeAgo)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.vertical, 6)
    }
    
    // MARK: Helpers for Recent Activity
    private func sessionTitle(for session: StudySession) -> String {
        if let taskTitle = session.taskTitle, !taskTitle.isEmpty {
            return session.completedSuccessfully
                ? "Completed focus session for \(taskTitle)"
                : "Skipped focus session for \(taskTitle)"
        } else {
            switch session.type {
            case .focus:
                return session.completedSuccessfully ? "Completed focus session" : "Skipped focus session"
            case .shortBreak:
                return "Short break"
            case .longBreak:
                return "Long break"
            }
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.minute, .hour, .day]
        formatter.maximumUnitCount = 1
        
        let now = Date()
        if let diff = formatter.string(from: date, to: now) {
            return "\(diff) ago"
        } else {
            return "Just now"
        }
    }
    
    // MARK: Shared UI
    var enhancedBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.4),
                    Color.black,
                    Color.purple.opacity(0.3),
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            subtleShapes
        }
    }
    
    var subtleShapes: some View {
        ZStack {
            Circle()
                .fill(.blue.opacity(0.15))
                .frame(width: 200, height: 200)
                .offset(x: -80, y: -150)
                .blur(radius: 60)
            
            Circle()
                .fill(.purple.opacity(0.12))
                .frame(width: 150, height: 150)
                .offset(x: 120, y: 200)
                .blur(radius: 50)
            
            Circle()
                .fill(.blue.opacity(0.08))
                .frame(width: 100, height: 100)
                .offset(x: -120, y: 150)
                .blur(radius: 40)
        }
    }
}

// MARK: - Quick Actions Section
struct QuickActionsSection: View {
    @Binding var selectedTab: AppTab
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Start")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: columns, spacing: 12) {
                QuickActionButton(
                    title: "Start Focus Session",
                    icon: "timer",
                    gradient: [.orange, .red]
                ) {
                    selectedTab = .timer   // go to Focus tab
                }
                
                QuickActionButton(
                    title: "Add New Task",
                    icon: "plus.circle.fill",
                    gradient: [.green, .mint]
                ) {
                    selectedTab = .tasks   // go to Tasks tab
                }
                
                QuickActionButton(
                    title: "Join Study Group",
                    icon: "person.2.fill",
                    gradient: [.purple, .pink]
                ) {
                    selectedTab = .groups  // go to Groups tab
                }
                
                QuickActionButton(
                    title: "View Statistics",
                    icon: "chart.bar.fill",
                    gradient: [.blue, .cyan]
                ) {
                    selectedTab = .timer   // or another tab if you make a stats screen
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.08))
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial.opacity(0.8))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
 

}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let title: String
    let icon: String
    let gradient: [Color]
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: gradient.map { $0.opacity(0.3) },
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.white.opacity(0.15), lineWidth: 1)
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    // Use a constant binding just for preview
    DashboardView(selectedTab: .constant(.dashboard))
}
