import Foundation
import SwiftUI
import Combine
import UserNotifications

// MARK: - Pomodoro Timer ViewModel
class PomodoroTimerViewModel: ObservableObject {
    @Published var timeRemaining: TimeInterval = 1500 // 25 minutes
    @Published var isRunning = false
    @Published var currentPhase: PomodoroPhase = .focus
    @Published var sessionCompleted = false
    @Published var todaySessions = 0
    @Published var recentSessions: [StudySession] = []
    
    private var timer: Timer?
    private var totalTime: TimeInterval = 1500
    private let notificationManager = NotificationManager.shared  // ← FIXED: Use shared instance
    
    var progress: CGFloat {
        guard totalTime > 0 else { return 0 }
        return CGFloat(1.0 - (timeRemaining / totalTime))
    }
    
    var timeDisplay: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    init() {
        setupNotifications()
        loadTodaySessions()
        loadRecentSessions()
    }
    
    // MARK: - Timer Controls
    func start() {
        guard !isRunning else { return }
        
        isRunning = true
        sessionCompleted = false
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            DispatchQueue.main.async {
                self.tick()
            }
        }
        
        // Schedule notification for when timer completes
        scheduleCompletionNotification()
    }
    
    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        
        // Cancel scheduled notification
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["timer_completion"])
    }
    
    func reset() {
        pause()
        timeRemaining = currentPhase.duration
        totalTime = currentPhase.duration
        sessionCompleted = false
    }
    
    func skip() {
        pause()
        completeSession()
        advancePhase()
    }
    
    private func tick() {
        timeRemaining -= 1
        
        if timeRemaining <= 0 {
            completeSession()
        }
    }
    
    private func completeSession() {
        pause()
        sessionCompleted = true
        
        // Record session
        let session = StudySession(
            type: currentPhase,
            duration: totalTime,
            startTime: Date(),
            completedSuccessfully: timeRemaining <= 0
        )
        
        recentSessions.insert(session, at: 0)
        
        if currentPhase == .focus {
            todaySessions += 1
        }
        
        // Send completion notification
        sendCompletionNotification()
        
        // Auto-advance to next phase
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.advancePhase()
        }
    }
    
    private func advancePhase() {
        switch currentPhase {
        case .focus:
            // After 4 focus sessions, take long break
            currentPhase = todaySessions % 4 == 0 ? .longBreak : .shortBreak
        case .shortBreak, .longBreak:
            currentPhase = .focus
        }
        
        timeRemaining = currentPhase.duration
        totalTime = currentPhase.duration
        sessionCompleted = false
    }
    
    // MARK: - Notifications
    private func setupNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else {
                print("Notification permission denied")
            }
        }
    }
    
    private func scheduleCompletionNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Timer Complete!"
        content.body = currentPhase.completionMessage
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeRemaining, repeats: false)
        let request = UNNotificationRequest(identifier: "timer_completion", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func sendCompletionNotification() {
        // This handles the case when app is in foreground
        let content = UNMutableNotificationContent()
        content.title = "Session Complete!"
        content.body = currentPhase.completionMessage
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(identifier: "session_complete_\(Date().timeIntervalSince1970)", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Data Persistence
    private func loadTodaySessions() {
        let today = Calendar.current.startOfDay(for: Date())
        if let lastSessionDate = UserDefaults.standard.object(forKey: "lastSessionDate") as? Date,
           Calendar.current.isDate(lastSessionDate, inSameDayAs: today) {
            todaySessions = UserDefaults.standard.integer(forKey: "todaySessions")
        } else {
            todaySessions = 0
            UserDefaults.standard.set(today, forKey: "lastSessionDate")
            UserDefaults.standard.set(0, forKey: "todaySessions")
        }
    }
    
    private func loadRecentSessions() {
        // Mock data for now - in real app, load from persistent storage
        recentSessions = [
            StudySession(type: .focus, duration: 1500, startTime: Date().addingTimeInterval(-3600), completedSuccessfully: true),
            StudySession(type: .shortBreak, duration: 300, startTime: Date().addingTimeInterval(-7200), completedSuccessfully: true),
            StudySession(type: .focus, duration: 1500, startTime: Date().addingTimeInterval(-10800), completedSuccessfully: false)
        ]
    }
    
    private func saveTodaySessions() {
        UserDefaults.standard.set(todaySessions, forKey: "todaySessions")
    }
}

// MARK: - Pomodoro Phase Enum
enum PomodoroPhase: String, CaseIterable, Codable {  // ← ADDED: Codable
    case focus = "focus"
    case shortBreak = "short break"
    case longBreak = "long break"
    
    var duration: TimeInterval {
        switch self {
        case .focus:
            return 1500 // 25 minutes
        case .shortBreak:
            return 300  // 5 minutes
        case .longBreak:
            return 900  // 15 minutes
        }
    }
    
    var title: String {
        switch self {
        case .focus:
            return "Focus Time"
        case .shortBreak:
            return "Short Break"
        case .longBreak:
            return "Long Break"
        }
    }
    
    var subtitle: String {
        switch self {
        case .focus:
            return "Time to concentrate and get work done"
        case .shortBreak:
            return "Take a quick breather"
        case .longBreak:
            return "Relax and recharge"
        }
    }
    
    var icon: String {
        switch self {
        case .focus:
            return "brain.head.profile"
        case .shortBreak:
            return "cup.and.saucer.fill"
        case .longBreak:
            return "figure.walk"
        }
    }
    
    var colors: [Color] {
        switch self {
        case .focus:
            return [.red, .orange]
        case .shortBreak:
            return [.green, .mint]
        case .longBreak:
            return [.blue, .cyan]
        }
    }
    
    // ← ADDED: Missing color property
    var color: Color {
        return colors.first ?? .blue
    }
    
    var completionMessage: String {
        switch self {
        case .focus:
            return "Great job! Time for a break."
        case .shortBreak:
            return "Break's over. Ready to focus?"
        case .longBreak:
            return "Long break complete. Let's get back to work!"
        }
    }
}

// MARK: - Study Session Model
struct StudySession: Identifiable, Codable {  // ← FIXED: Added Codable
    let id = UUID()
    let type: PomodoroPhase
    let duration: TimeInterval
    let startTime: Date
    let completedSuccessfully: Bool
    
    var endTime: Date {
        startTime.addingTimeInterval(duration)
    }
    
    var displayDuration: String {
        let minutes = Int(duration) / 60
        return "\(minutes) min"
    }
}

// MARK: - Notification Manager
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()  // ← FIXED: Made public shared instance
    
    init() {}  // ← FIXED: Made public init
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("Notification permission granted")
                } else if let error = error {
                    print("Notification permission error: \(error)")
                }
            }
        }
    }
    
    func scheduleTimerNotification(title: String, body: String, timeInterval: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

// MARK: - Task Selector View
struct TaskSelectorView: View {
    let tasks: [StudyTask]
    @Binding var selectedTask: StudyTask?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                mainContent
            }
            .navigationTitle("Select Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
    
    private var backgroundGradient: some View {
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
    
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                freeSessionOption
                taskList
                Spacer(minLength: 50)
            }
            .padding(20)
        }
    }
    
    private var freeSessionOption: some View {
        TaskSelectorRow(
            title: "Free Focus Session",
            subtitle: "Study without a specific task",
            icon: "brain.head.profile",
            color: .purple,
            isSelected: selectedTask == nil
        ) {
            selectedTask = nil
            dismiss()
        }
    }
    
    private var taskList: some View {
        ForEach(tasks, id: \.id) { task in
            TaskSelectorRow(
                title: task.title,
                subtitle: "\(task.subject) • Due \(task.dueDate)",
                icon: "checkmark.circle",
                color: task.priority.color,
                isSelected: selectedTask?.id == task.id
            ) {
                selectedTask = task
                dismiss()
            }
        }
    }
}

struct TaskSelectorRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
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
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(color)
                        .fontWeight(.semibold)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? color.opacity(0.1) : .black.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? color : .white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    let sampleTasks = [
        StudyTask(title: "Math Assignment", description: "", dueDate: Date(), priority: .high, subject: "Mathematics"),
        StudyTask(title: "Physics Lab", description: "", dueDate: Date(), priority: .medium, subject: "Physics")
    ]
    
    return TaskSelectorView(tasks: sampleTasks, selectedTask: .constant(nil))
}
