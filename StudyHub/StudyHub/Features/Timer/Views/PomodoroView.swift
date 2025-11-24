import SwiftUI
import Combine

// MARK: - Pomodoro Timer View
struct PomodoroView: View {
    @StateObject private var timerViewModel = PomodoroTimerViewModel()
    @StateObject private var taskViewModel = TaskViewModel()
    @State private var showingTaskSelector = false
    @State private var selectedTask: StudyTask?
    
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
                        if let task = selectedTask {
                            currentTaskSection(task: task)
                        }
                        
                        // Quick Task Selector
                        quickTaskSelectorSection
                        
                        // Session History
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
                    Button("Settings") {
                        // Timer settings
                    }
                    .foregroundColor(.cyan)
                }
            }
        }
        .sheet(isPresented: $showingTaskSelector) {
            TaskSelectorView(
                tasks: getIncompleteTasks(),  // ← FIXED: Use function instead of property
                selectedTask: $selectedTask
            )
        }
        .onReceive(timerViewModel.$sessionCompleted) { completed in
            if completed {
                // Handle session completion
                if let task = selectedTask {
                    // Add study session to task statistics
                    recordStudySession(for: task)
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    private func getIncompleteTasks() -> [StudyTask] {
        return taskViewModel.tasks.filter { !$0.isCompleted }  // ← FIXED: Get incomplete tasks
    }
}

// MARK: - Timer Sections
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
            taskScrollView
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
                    isSelected: selectedTask == nil
                ) {
                    selectedTask = nil
                }
                
                // Recent tasks - get first 3 incomplete tasks
                ForEach(Array(getIncompleteTasks().prefix(3)), id: \.id) { task in
                    QuickTaskCard(
                        title: task.title,
                        subtitle: task.subject,
                        icon: "checkmark.circle",
                        color: task.priority.color,
                        isSelected: selectedTask?.id == task.id
                    ) {
                        selectedTask = task
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    var sessionHistorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sessionHistoryHeader
            sessionProgressBar
            sessionsList
        }
        .padding(20)
        .background(cardBackground)
    }
    
    var sessionHistoryHeader: some View {
        HStack {
            Text("Today's Sessions")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Spacer()
            
            Text("\(timerViewModel.todaySessions)/6")
                .font(.subheadline)
                .foregroundColor(.cyan)
                .fontWeight(.semibold)
        }
    }
    
    var sessionProgressBar: some View {
        ProgressView(value: Double(timerViewModel.todaySessions), total: 6.0)
            .progressViewStyle(LinearProgressViewStyle(tint: .cyan))
            .scaleEffect(y: 2)
    }
    
    var sessionsList: some View {
        LazyVStack(spacing: 8) {
            ForEach(Array(timerViewModel.recentSessions.prefix(3)), id: \.id) { session in
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
    
    func recordStudySession(for task: StudyTask) {
        // Record study session for the task
        // This would integrate with your TaskViewModel
        print("Recording study session for task: \(task.title)")
    }
}

// MARK: - Supporting Views
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
        HStack {
            Circle()
                .fill(session.type.color)
                .frame(width: 8, height: 8)
            
            Text(session.type.rawValue.capitalized)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Text(session.startTime, style: .time)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
    }
}

#Preview {
    PomodoroView()
}
