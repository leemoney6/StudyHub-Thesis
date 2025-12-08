import Foundation
import SwiftUI
import Combine
import UserNotifications
import FirebaseAuth
import FirebaseFirestore

// MARK: - Firebase-Enhanced Pomodoro Timer ViewModel
@MainActor
class PomodoroTimerViewModel: ObservableObject {
    // MARK: - Timer State (Same as before)
    @Published var timeRemaining: TimeInterval = 1500 // 25 minutes
    @Published var isRunning = false
    @Published var currentPhase: PomodoroPhase = .focus
    @Published var sessionCompleted = false
    
    // MARK: - Firebase Session Data (NEW)
    @Published var recentSessions: [StudySession] = []
    @Published var todaySessions = 0
    @Published var todayFocusTime: TimeInterval = 0 // in seconds
    @Published var sessionStatistics = SessionStatistics.empty
    @Published var isLoadingSessions = false
    @Published var sessionError = ""
    
    // MARK: - Task Integration (NEW)
    @Published var selectedTask: StudyTask?
    @Published var availableTasks: [StudyTask] = []
    
    private var timer: Timer?
    private var totalTime: TimeInterval = 1500
    private var currentSessionStartTime: Date?
    private let notificationManager = NotificationManager.shared
    
    // MARK: - Firebase Instances (NEW)
    private let firestore = Firestore.firestore()
    private let auth = Auth.auth()
    private var sessionsListener: ListenerRegistration?
    
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
        setupSessionsListener()
        loadTodayStatistics()
    }
    
    deinit {
        sessionsListener?.remove()
    }
    
    // MARK: - Firebase Session Listener (NEW)
    private func setupSessionsListener() {
        guard let currentUser = auth.currentUser else {
            print("⚠️ No authenticated user for timer sessions")
            return
        }
        
        isLoadingSessions = true
        
        sessionsListener = firestore
            .collection("users")
            .document(currentUser.uid)
            .collection("sessions")
            .order(by: "startTime", descending: true)
            .limit(to: 20) // Get latest 20 sessions
            .addSnapshotListener { [weak self] snapshot, error in
                Task {
                    await MainActor.run {
                        self?.handleSessionsUpdate(snapshot: snapshot, error: error)
                    }
                }
            }
    }
    
    private func handleSessionsUpdate(snapshot: QuerySnapshot?, error: Error?) {
        isLoadingSessions = false
        
        if let error = error {
            sessionError = "Failed to load sessions: \(error.localizedDescription)"
            print("❌ Session listener error: \(error)")
            return
        }
        
        guard let documents = snapshot?.documents else {
            recentSessions = []
            updateTodayStatistics()
            return
        }
        
        // Convert Firestore documents to StudySession objects
        let loadedSessions = documents.compactMap { document -> StudySession? in
            do {
                var session = try document.data(as: StudySession.self)
                session.id = UUID(uuidString: document.documentID) ?? UUID()
                return session
            } catch {
                print("❌ Error decoding session \(document.documentID): \(error)")
                return nil
            }
        }
        
        recentSessions = loadedSessions
        updateTodayStatistics()
        calculateSessionStatistics()
        
        print("✅ Loaded \(recentSessions.count) sessions from Firebase")
    }
    
    // MARK: - Timer Controls (Enhanced)
    func start() {
        guard !isRunning else { return }
        
        isRunning = true
        sessionCompleted = false
        currentSessionStartTime = Date()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            DispatchQueue.main.async {
                self.tick()
            }
        }
        
        scheduleCompletionNotification()
        print("🎯 Timer started: \(currentPhase.rawValue) - \(timeDisplay)")
    }
    
    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["timer_completion"])
        print("⏸️ Timer paused")
    }
    
    func reset() {
        pause()
        timeRemaining = currentPhase.duration
        totalTime = currentPhase.duration
        sessionCompleted = false
        currentSessionStartTime = nil
        print("🔄 Timer reset")
    }
    
    func skip() {
        pause()
        completeSession(completed: false) // Mark as skipped
        advancePhase()
        print("⏭️ Timer skipped to next phase")
    }
    
    private func tick() {
        timeRemaining -= 1
        
        if timeRemaining <= 0 {
            completeSession(completed: true)
        }
    }
    
    // MARK: - Session Completion (Enhanced with Firebase)
    private func completeSession(completed: Bool) {
        pause()
        sessionCompleted = true
        
        guard let startTime = currentSessionStartTime else {
            print("❌ No start time recorded for session")
            advancePhase()
            return
        }


        // Create session record
        let session = StudySession(
            type: currentPhase,
            duration: totalTime,
            startTime: startTime,
            completedSuccessfully: completed,
            taskId: selectedTask?.id.uuidString,
            taskTitle: selectedTask?.title
        )
        currentSessionStartTime = nil
        
        // Save to Firebase
        Task {
            await saveSession(session)
        }
        
        // Send completion notification
        sendCompletionNotification()
        
        // Auto-advance to next phase
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.advancePhase()
        }
        
        print("✅ Session completed: \(currentPhase.rawValue) - \(completed ? "Success" : "Skipped")")
    }
    
    private func advancePhase() {
        switch currentPhase {
        case .focus:
            // After focus session, check if it's time for long break (every 4 focus sessions)
            let focusSessionsToday = recentSessions.filter {
                $0.isToday && $0.type == .focus && $0.completedSuccessfully
            }.count
            currentPhase = (focusSessionsToday > 0 && focusSessionsToday % 4 == 0) ? .longBreak : .shortBreak
        case .shortBreak, .longBreak:
            currentPhase = .focus
        }
        
        timeRemaining = currentPhase.duration
        totalTime = currentPhase.duration
        sessionCompleted = false
        currentSessionStartTime = nil
        
        print("➡️ Advanced to \(currentPhase.rawValue)")
    }
    
    // MARK: - Firebase Session Operations (NEW)
    private func saveSession(_ session: StudySession) async {
        guard let currentUser = auth.currentUser else {
            print("❌ No authenticated user to save session")
            return
        }
        
        do {
            let data = try Firestore.Encoder().encode(session)
            
            try await firestore
                .collection("users")
                .document(currentUser.uid)
                .collection("sessions")
                .document(session.id.uuidString)
                .setData(data)
            
            print("✅ Session saved to Firebase: \(session.type.rawValue)")
            
            // Update task study time if linked
            if let taskId = session.taskId,
               session.type == .focus && session.completedSuccessfully {
                await updateTaskStudyTime(taskId: taskId, additionalTime: session.duration)
            }
            
        } catch {
            await MainActor.run {
                self.sessionError = "Failed to save session: \(error.localizedDescription)"
            }
            print("❌ Failed to save session: \(error)")
        }
    }
    
    private func updateTaskStudyTime(taskId: String, additionalTime: TimeInterval) async {
        // This could be used to track study time per task in the future
        // For now, just log it
        let minutes = Int(additionalTime) / 60
        print("📚 Added \(minutes) minutes to task \(taskId)")
    }
    
    // MARK: - Statistics Calculation (NEW)
    private func updateTodayStatistics() {
        let todayString = DateFormatter.dailyFormat.string(from: Date())
        let todaySessions = recentSessions.filter { $0.date == todayString }
        
        self.todaySessions = todaySessions.filter { $0.type == .focus && $0.completedSuccessfully }.count
        self.todayFocusTime = todaySessions
            .filter { $0.type == .focus && $0.completedSuccessfully }
            .reduce(0) { $0 + $1.duration }
        
        print("📊 Today: \(self.todaySessions) focus sessions, \(Int(todayFocusTime)/60) minutes")
    }
    
    private func calculateSessionStatistics() {
        guard !recentSessions.isEmpty else {
            sessionStatistics = SessionStatistics.empty
            return
        }
        
        let focusSessions = recentSessions.filter { $0.type == .focus }
        let completedFocus = focusSessions.filter { $0.completedSuccessfully }
        let totalFocusTime = completedFocus.reduce(0) { $0 + $1.duration }
        
        let completionRate = focusSessions.isEmpty ? 0.0 :
            Double(completedFocus.count) / Double(focusSessions.count)
        
        let averageLength = completedFocus.isEmpty ? 0.0 :
            totalFocusTime / Double(completedFocus.count)
        
        sessionStatistics = SessionStatistics(
            totalSessions: recentSessions.count,
            focusSessions: focusSessions.count,
            totalFocusTime: totalFocusTime,
            completionRate: completionRate,
            averageSessionLength: averageLength,
            longestStreak: calculateLongestStreak()
        )
    }
    
    private func calculateLongestStreak() -> Int {
        // Calculate longest streak of consecutive days with focus sessions
        let focusSessions = recentSessions.filter { $0.type == .focus && $0.completedSuccessfully }
        let dates = Set(focusSessions.map { $0.date }).sorted(by: >)
        
        var longestStreak = 0
        var currentStreak = 0
        var previousDate: Date?
        
        for dateString in dates {
            if let date = DateFormatter.dailyFormat.date(from: dateString) {
                if let prev = previousDate,
                   Calendar.current.dateInterval(of: .day, for: prev)?.end ==
                   Calendar.current.dateInterval(of: .day, for: date)?.start {
                    currentStreak += 1
                } else {
                    currentStreak = 1
                }
                longestStreak = max(longestStreak, currentStreak)
                previousDate = date
            }
        }
        
        return longestStreak
    }
    
    // MARK: - Task Integration (NEW)
    func setSelectedTask(_ task: StudyTask?) {
        selectedTask = task
        print("🎯 Selected task for focus: \(task?.title ?? "Free focus")")
    }
    
    func loadAvailableTasks(_ tasks: [StudyTask]) {
        // Filter incomplete tasks for timer selection
        availableTasks = tasks.filter { !$0.isCompleted }
        print("📋 Loaded \(availableTasks.count) available tasks for timer")
    }
    
    // MARK: - User Management (NEW)
    func refreshForNewUser() {
        sessionsListener?.remove()
        recentSessions = []
        todaySessions = 0
        todayFocusTime = 0
        sessionStatistics = SessionStatistics.empty
        selectedTask = nil
        availableTasks = []
        setupSessionsListener()
    }
    
    func clearSessionsForSignOut() {
        sessionsListener?.remove()
        recentSessions = []
        todaySessions = 0
        todayFocusTime = 0
        sessionStatistics = SessionStatistics.empty
        selectedTask = nil
        availableTasks = []
        pause() // Stop any running timer
    }
    
    // MARK: - Legacy Methods (Maintained for compatibility)
    private func loadTodayStatistics() {
        // This now handled by Firebase listener
        // Keeping method for backward compatibility
    }
    
    private func setupNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Notification permission granted")
            } else {
                print("❌ Notification permission denied")
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
        let content = UNMutableNotificationContent()
        content.title = "Session Complete!"
        content.body = currentPhase.completionMessage
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(
            identifier: "session_complete_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - Notification Manager (Same as before)
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    init() {}
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("✅ Notification permission granted")
                } else if let error = error {
                    print("❌ Notification permission error: \(error)")
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
                print("❌ Error scheduling notification: \(error)")
            }
        }
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
