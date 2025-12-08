import SwiftUI
import Combine

// MARK: - Firebase-Enhanced Pomodoro Timer View
struct PomodoroView: View {
    @StateObject private var timerViewModel = PomodoroTimerViewModel()
    @StateObject private var taskViewModel = TaskViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingTaskSelector = false
    @State private var showingSessionHistory = false
    
    var body: some View {
        NavigationView {
            ZStack {
                enhancedBackground
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Timer Header
                        timerHeaderSection
                        
                        // Main Timer Circle
                        mainTimerSection
                        
                        // Controls Section
                        timerControlsSection
                        
                        // Current Task Section
                        if let task = timerViewModel.selectedTask {
                            currentTaskSection(task: task)
                        }
                        
                        // Quick Task Selector (Real Firebase Tasks)
                        quickTaskSelectorSection
                        
                        // Today's Statistics (Real Firebase Data)
                        todayStatisticsSection
                        
                        // Session History (Real Firebase Data)
                        sessionHistorySection
                        
                        Spacer(minLength: 50)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Focus Timer")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("History") {
                        showingSessionHistory = true
                    }
                    .foregroundColor(.cyan)
                }
            }
        }
        .sheet(isPresented: $showingTaskSelector) {
            TaskSelectorView(
                tasks: getIncompleteTasks(),
                selectedTask: Binding(
                    get: { timerViewModel.selectedTask },
                    set: { timerViewModel.setSelectedTask($0) }
                )
            )
        }
        .sheet(isPresented: $showingSessionHistory) {
            SessionHistoryView(sessions: timerViewModel.recentSessions)
        }
        .onReceive(timerViewModel.$sessionCompleted) { completed in
            if completed {
                // Session completed - Firebase automatically saves
                if let task = timerViewModel.selectedTask {
                    print("📚 Completed focus session for task: \(task.title)")
                }
            }
        }
        .onReceive(taskViewModel.$tasks) { tasks in
            // Update timer with real Firebase tasks
            timerViewModel.loadAvailableTasks(tasks)
        }
        .onAppear {
            // Connect to real task data
            timerViewModel.loadAvailableTasks(getIncompleteTasks())
        }
        .onChange(of: authViewModel.isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                timerViewModel.refreshForNewUser()
            } else {
                timerViewModel.clearSessionsForSignOut()
            }
        }
    }
    
    // MARK: - Helper Functions
    private func getIncompleteTasks() -> [StudyTask] {
        return taskViewModel.tasks.filter { !$0.isCompleted }
    }
}

// MARK: - Timer Sections (Enhanced with Firebase Data)
private extension PomodoroView {
    
    var timerHeaderSection: some View {
        VStack(spacing: 12) {
            Text(timerViewModel.currentPhase.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(timerViewModel.currentPhase.subtitle)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                
            // Show selected task if any
            if let task = timerViewModel.selectedTask {
                HStack(spacing: 8) {
                    Image(systemName: "target")
                        .foregroundColor(.cyan)
                        .font(.caption)
                    
                    Text("Focusing on: \(task.title)")
                        .font(.caption)
                        .foregroundColor(.cyan)
                        .lineLimit(1)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(.cyan.opacity(0.2))
                .cornerRadius(12)
            }
        }
        .padding(.vertical, 20)
    }
    
    var mainTimerSection: some View {
        let backgroundCircle = Circle()
            .stroke(
                LinearGradient(
                    colors: [.white.opacity(0.2), .white.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 8
            )
            .frame(width: 280, height: 280)
        
        let progressCircle = Circle()
            .trim(from: 0, to: timerViewModel.progress)
            .stroke(
                LinearGradient(
                    colors: timerViewModel.currentPhase.colors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                style: StrokeStyle(lineWidth: 12, lineCap: .round)
            )
            .frame(width: 280, height: 280)
            .rotationEffect(.degrees(-90))
            .animation(.easeInOut(duration: 0.3), value: timerViewModel.progress)
        
        let timerContent = VStack(spacing: 16) {
            // Time Display
            Text(timerViewModel.timeDisplay)
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            
            // Phase Indicator
            phaseIndicator
        }
        
        return ZStack {
            backgroundCircle
            progressCircle
            timerContent
        }
        .padding(20)
        .background(timerBackground)
    }
    
    var phaseIndicator: some View {
        HStack(spacing: 8) {
            Image(systemName: timerViewModel.currentPhase.icon)
                .foregroundColor(timerViewModel.currentPhase.colors.first ?? .white)
                .font(.title3)
            
            Text(timerViewModel.currentPhase.rawValue.capitalized)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(phaseIndicatorBackground)
    }
    
    var phaseIndicatorBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.black.opacity(0.3))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(timerViewModel.currentPhase.colors.first?.opacity(0.5) ?? .clear, lineWidth: 1)
            )
    }
    
    var timerBackground: some View {
        RoundedRectangle(cornerRadius: 30)
            .fill(.black.opacity(0.2))
            .overlay(
                RoundedRectangle(cornerRadius: 30)
                    .stroke(.white.opacity(0.1), lineWidth: 1)
            )
    }
    
    var timerControlsSection: some View {
        HStack(spacing: 20) {
            // Reset Button
            ControlButton(
                icon: "arrow.clockwise",
                title: "Reset",
                color: .orange,
                isSecondary: true
            ) {
                timerViewModel.reset()
            }
            
            // Main Action Button
            ControlButton(
                icon: timerViewModel.isRunning ? "pause.fill" : "play.fill",
                title: timerViewModel.isRunning ? "Pause" : "Start",
                color: timerViewModel.currentPhase.colors.first ?? .green,
                isSecondary: false
            ) {
                if timerViewModel.isRunning {
                    timerViewModel.pause()
                } else {
                    timerViewModel.start()
                }
            }
            
            // Skip Button
            ControlButton(
                icon: "forward.end.fill",
                title: "Skip",
                color: .purple,
                isSecondary: true
            ) {
                timerViewModel.skip()
            }
        }
        .padding(.horizontal, 20)
    }
    
    func currentTaskSection(task: StudyTask) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Current Task")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Change") {
                    showingTaskSelector = true
                }
                .foregroundColor(.cyan)
                .fontWeight(.semibold)
            }
            
            TaskRowCompact(task: task)
        }
        .padding(20)
        .background(cardBackground)
    }
    
    var quickTaskSelectorSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader
            
            if timerViewModel.isLoadingSessions {
                // Loading state
                HStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .cyan))
                        .scaleEffect(0.8)
                    Text("Loading tasks...")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
            } else {
                taskScrollView
            }
        }
        .padding(.vertical, 20)
        .background(cardBackground)
    }
    
    var sectionHeader: some View {
        HStack {
            Text("Quick Start")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Spacer()
            
            Button("View All") {
                showingTaskSelector = true
            }
            .foregroundColor(.cyan)
            .fontWeight(.semibold)
        }
        .padding(.horizontal, 20)
    }
    
    var taskScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Focus without task
                QuickTaskCard(
                    title: "Free Focus",
                    subtitle: "No specific task",
                    icon: "brain.head.profile",
                    color: .purple,
                    isSelected: timerViewModel.selectedTask == nil
                ) {
                    timerViewModel.setSelectedTask(nil)
                }
                
                // Real Firebase tasks (first 3 incomplete)
                ForEach(Array(getIncompleteTasks().prefix(3)), id: \.id) { task in
                    QuickTaskCard(
                        title: task.title,
                        subtitle: task.subject,
                        icon: "checkmark.circle",
                        color: task.priority.color,
                        isSelected: timerViewModel.selectedTask?.id == task.id
                    ) {
                        timerViewModel.setSelectedTask(task)
                    }
                }
                
                // Show message if no tasks
                if getIncompleteTasks().isEmpty {
                    VStack(spacing: 8) {
                        Text("No tasks available")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text("Add tasks in the Tasks tab")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .frame(width: 120)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.black.opacity(0.3))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - NEW: Today's Statistics Section
    var todayStatisticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Today's Progress")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                if timerViewModel.isLoadingSessions {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .cyan))
                        .scaleEffect(0.8)
                } else {
                    Text("\(Int(timerViewModel.todayFocusTime) / 60)m focused")
                        .font(.caption)
                        .foregroundColor(.cyan)
                        .fontWeight(.semibold)
                }
            }
            
            HStack(spacing: 20) {
                StatCard(
                    title: "Sessions",
                    value: "\(timerViewModel.todaySessions)",
                    icon: "timer",
                    color: .orange
                )
                
                StatCard(
                    title: "Focus Time",
                    value: "\(Int(timerViewModel.todayFocusTime) / 60)m",
                    icon: "clock.fill",
                    color: .cyan
                )
                
                StatCard(
                    title: "Completion",
                    value: String(format: "%.0f%%", timerViewModel.sessionStatistics.completionRate * 100),
                    icon: "checkmark.circle.fill",
                    color: .green
                )
            }
        }
        .padding(20)
        .background(cardBackground)
    }
    
    var sessionHistorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sessionHistoryHeader
            
            if timerViewModel.recentSessions.isEmpty {
                Text("No sessions yet. Start your first focus session!")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 20)
            } else {
                sessionsList
            }
        }
        .padding(20)
        .background(cardBackground)
    }
    
    var sessionHistoryHeader: some View {
        HStack {
            Text("Recent Sessions")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Spacer()
            
            Button("View All") {
                showingSessionHistory = true
            }
            .foregroundColor(.cyan)
            .fontWeight(.semibold)
        }
    }
    
    var sessionsList: some View {
        LazyVStack(spacing: 8) {
            ForEach(Array(timerViewModel.recentSessions.prefix(5)), id: \.id) { session in
                SessionHistoryRow(session: session)
            }
        }
    }
    
    var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.black.opacity(0.4))
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
    }
    
    var enhancedBackground: some View {
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
    }
}

// MARK: - Supporting Views (Enhanced)
struct ControlButton: View {
    let icon: String
    let title: String
    let color: Color
    let isSecondary: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                buttonCircle
                buttonTitle
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var buttonCircle: some View {
        ZStack {
            Circle()
                .fill(isSecondary ? color.opacity(0.2) : color)
                .frame(width: 60, height: 60)
                .overlay(
                    Circle()
                        .stroke(color, lineWidth: isSecondary ? 2 : 0)
                )
            
            Image(systemName: icon)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(isSecondary ? color : .white)
        }
    }
    
    private var buttonTitle: some View {
        Text(title)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
    }
}



struct TaskRowCompact: View {
    let task: StudyTask
    
    var body: some View {
        HStack(spacing: 12) {
            priorityIndicator
            taskInfo
            Spacer()
        }
        .padding(16)
        .background(taskRowBackground)
    }
    
    private var priorityIndicator: some View {
        Circle()
            .fill(task.priority.color)
            .frame(width: 12, height: 12)
    }
    
    private var taskInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(task.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .lineLimit(1)
            
            taskDetails
        }
    }
    
    private var taskDetails: some View {
        HStack(spacing: 8) {
            Text(task.subject)
                .font(.caption)
                .foregroundColor(.cyan)
            
            Text("Due \(task.dueDate, style: .relative)")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    private var taskRowBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.black.opacity(0.3))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(task.priority.color.opacity(0.3), lineWidth: 1)
            )
    }
}

struct QuickTaskCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                cardIcon
                cardText
            }
            .frame(width: 100)
            .padding(.vertical, 16)
            .background(cardBackground)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var cardIcon: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Circle()
                        .stroke(color, lineWidth: isSelected ? 3 : 1)
                )
            
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .fontWeight(.semibold)
        }
    }
    
    private var cardText: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(1)
        }
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(isSelected ? color.opacity(0.1) : .black.opacity(0.3))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color : .white.opacity(0.2), lineWidth: 1)
            )
    }
}

struct SessionHistoryRow: View {
    let session: StudySession
    
    var body: some View {
        HStack(spacing: 12) {
            // Session type indicator
            ZStack {
                Circle()
                    .fill(session.type.color.opacity(0.2))
                    .frame(width: 24, height: 24)
                
                Image(systemName: session.type.icon)
                    .font(.caption)
                    .foregroundColor(session.type.color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(session.type.title)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    if !session.completedSuccessfully {
                        Text("(Skipped)")
                            .font(.caption2)
                            .foregroundColor(.orange.opacity(0.8))
                    }
                }
                
                if let taskTitle = session.taskTitle {
                    Text(taskTitle)
                        .font(.caption2)
                        .foregroundColor(.cyan.opacity(0.8))
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(session.displayDuration)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(session.startTime, style: .time)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Session History View
struct SessionHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    let sessions: [StudySession]
    
    var body: some View {
        NavigationView {
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
                
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(sessions, id: \.id) { session in
                            SessionDetailRow(session: session)
                        }
                        
                        if sessions.isEmpty {
                            Text("No sessions yet")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.top, 40)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Session History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

struct SessionDetailRow: View {
    let session: StudySession
    
    var body: some View {
        HStack(spacing: 16) {
            // Session type with completion status
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(session.type.color.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: session.completedSuccessfully ? session.type.icon : "xmark")
                        .font(.title3)
                        .foregroundColor(session.completedSuccessfully ? session.type.color : .orange)
                }
                
                Text(session.type.title)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(session.displayDuration)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    if !session.completedSuccessfully {
                        Text("(Incomplete)")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                if let taskTitle = session.taskTitle {
                    Text("Task: \(taskTitle)")
                        .font(.caption)
                        .foregroundColor(.cyan)
                }
                
                Text("\(session.startTime, formatter: DateFormatter.sessionFormatter)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.black.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    PomodoroView()
        .environmentObject(AuthViewModel())
}
