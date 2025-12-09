import Foundation
import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

// MARK: - Real Firebase-Connected User Statistics ViewModel
@MainActor
class UserStatsViewModel: ObservableObject {
    // MARK: - Published Statistics
    @Published var tasksCompleted = 0
    @Published var studySessions = 0
    @Published var totalHours: Double = 0.0
    @Published var streakDays = 0
    @Published var thisWeekSessions = 0
    @Published var thisMonthHours: Double = 0.0
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    // MARK: - Detailed Statistics
    @Published var focusSessions = 0
    @Published var totalBreakTime: Double = 0.0
    @Published var averageSessionLength: Double = 0.0
    @Published var completionRate: Double = 0.0
    @Published var longestSessionMinutes = 0
    @Published var mostProductiveDay = ""
    @Published var currentStreak = 0
    
    // MARK: - Raw Data
    @Published var allSessions: [StudySession] = []
    @Published var completedTasks: [StudyTask] = []
    
    private let firestore = Firestore.firestore()
    private let auth = Auth.auth()
    private var sessionsListener: ListenerRegistration?
    private var tasksListener: ListenerRegistration?
    
    deinit {
        sessionsListener?.remove()
        tasksListener?.remove()
    }
    
    // MARK: - Start Listening to Firebase Data
    func startListening(userId: String) {
        setupSessionsListener(userId: userId)
        setupTasksListener(userId: userId)
    }
    
    func stopListening() {
        sessionsListener?.remove()
        tasksListener?.remove()
        sessionsListener = nil
        tasksListener = nil
    }
    
    // MARK: - Firebase Sessions Listener
    private func setupSessionsListener(userId: String) {
        isLoading = true
        
        sessionsListener = firestore
            .collection("users")
            .document(userId)
            .collection("sessions")
            .order(by: "startTime", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                Task {
                    await MainActor.run {
                        self?.handleSessionsUpdate(snapshot: snapshot, error: error)
                    }
                }
            }
    }
    
    private func handleSessionsUpdate(snapshot: QuerySnapshot?, error: Error?) {
        if let error = error {
            errorMessage = "Failed to load sessions: \(error.localizedDescription)"
            isLoading = false
            print("❌ Sessions listener error: \(error)")
            return
        }
        
        guard let documents = snapshot?.documents else {
            allSessions = []
            calculateSessionStatistics()
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
        
        allSessions = loadedSessions
        calculateSessionStatistics()
        
        print("✅ Loaded \(allSessions.count) sessions for statistics")
    }
    
    // MARK: - Firebase Tasks Listener
    private func setupTasksListener(userId: String) {
        tasksListener = firestore
            .collection("users")
            .document(userId)
            .collection("tasks")
            .whereField("isCompleted", isEqualTo: true)
            .addSnapshotListener { [weak self] snapshot, error in
                Task {
                    await MainActor.run {
                        self?.handleTasksUpdate(snapshot: snapshot, error: error)
                    }
                }
            }
    }
    
    private func handleTasksUpdate(snapshot: QuerySnapshot?, error: Error?) {
        if let error = error {
            print("❌ Tasks listener error: \(error)")
            return
        }
        
        guard let documents = snapshot?.documents else {
            completedTasks = []
            tasksCompleted = 0
            return
        }
        
        // Convert completed tasks
        let loadedTasks = documents.compactMap { document -> StudyTask? in
            do {
                var task = try document.data(as: StudyTask.self)
                task.id = UUID(uuidString: document.documentID) ?? UUID()
                return task
            } catch {
                print("❌ Error decoding completed task \(document.documentID): \(error)")
                return nil
            }
        }
        
        completedTasks = loadedTasks
        tasksCompleted = completedTasks.count
        
        print("✅ Loaded \(tasksCompleted) completed tasks for statistics")
        isLoading = false
    }
    
    // MARK: - Calculate Session Statistics
    private func calculateSessionStatistics() {
        guard !allSessions.isEmpty else {
            resetStatistics()
            isLoading = false
            return
        }
        
        let focusSessionsData = allSessions.filter { $0.type == .focus }
        let completedFocusSessions = focusSessionsData.filter { $0.completedSuccessfully }
        
        // Basic counts
        studySessions = completedFocusSessions.count
        focusSessions = focusSessionsData.count
        
        // Total study time (completed focus sessions only)
        let totalFocusTime = completedFocusSessions.reduce(0) { $0 + $1.duration }
        totalHours = totalFocusTime / 3600.0 // Convert seconds to hours
        
        // Break time
        let breakSessions = allSessions.filter { $0.type == .shortBreak || $0.type == .longBreak }
        let completedBreaks = breakSessions.filter { $0.completedSuccessfully }
        totalBreakTime = completedBreaks.reduce(0) { $0 + $1.duration } / 3600.0
        
        // Completion rate
        completionRate = focusSessionsData.isEmpty ? 0.0 :
            Double(completedFocusSessions.count) / Double(focusSessionsData.count)
        
        // Average session length
        averageSessionLength = completedFocusSessions.isEmpty ? 0.0 :
            totalFocusTime / Double(completedFocusSessions.count) / 60.0 // Convert to minutes
        
        // Longest session
        longestSessionMinutes = Int((completedFocusSessions.map { $0.duration }.max() ?? 0) / 60)
        
        // Calculate streaks and time-based statistics
        calculateStreakStatistics()
        calculateWeeklyMonthlyStats()
        
        print("📊 Statistics updated - Sessions: \(studySessions), Hours: \(String(format: "%.1f", totalHours)), Streak: \(streakDays)")
    }
    
    private func calculateStreakStatistics() {
        // Get unique days with focus sessions
        let focusSessionDates = allSessions
            .filter { $0.type == .focus && $0.completedSuccessfully }
            .map { $0.date }
            .unique()
            .sorted(by: >)
        
        guard !focusSessionDates.isEmpty else {
            streakDays = 0
            currentStreak = 0
            return
        }
        
        // Calculate current streak
        let today = DateFormatter.dailyFormat.string(from: Date())
        let yesterday = DateFormatter.dailyFormat.string(from: Date().addingTimeInterval(-86400))
        
        var currentStreakCount = 0
        var longestStreakCount = 0
        var tempStreakCount = 0
        var previousDate: Date?
        
        // Start checking from most recent date
        if focusSessionDates.first == today || focusSessionDates.first == yesterday {
            currentStreakCount = 1
        }
        
        // Calculate streaks
        for dateString in focusSessionDates {
            guard let date = DateFormatter.dailyFormat.date(from: dateString) else { continue }
            
            if let prev = previousDate {
                let daysDifference = Calendar.current.dateComponents([.day], from: date, to: prev).day ?? 0
                
                if daysDifference == 1 {
                    // Consecutive day
                    tempStreakCount += 1
                    if dateString == today || dateString == yesterday {
                        currentStreakCount = max(currentStreakCount, tempStreakCount)
                    }
                } else {
                    // Break in streak
                    longestStreakCount = max(longestStreakCount, tempStreakCount)
                    tempStreakCount = 1
                    if dateString == today || dateString == yesterday {
                        currentStreakCount = 1
                    }
                }
            } else {
                tempStreakCount = 1
            }
            
            previousDate = date
        }
        
        streakDays = max(longestStreakCount, tempStreakCount)
        currentStreak = currentStreakCount
        
        // Find most productive day
        let dayWithMostSessions = Dictionary(grouping: focusSessionDates) { $0 }
            .max(by: { $0.value.count < $1.value.count })?.key ?? ""
        
        if let date = DateFormatter.dailyFormat.date(from: dayWithMostSessions) {
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "EEEE"
            mostProductiveDay = dayFormatter.string(from: date)
        }
    }
    
    private func calculateWeeklyMonthlyStats() {
        let calendar = Calendar.current
        let now = Date()
        
        // This week's sessions
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        thisWeekSessions = allSessions.filter { session in
            guard let sessionDate = DateFormatter.dailyFormat.date(from: session.date) else { return false }
            return sessionDate >= weekAgo && session.type == .focus && session.completedSuccessfully
        }.count
        
        // This month's hours
        let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        let thisMonthSessions = allSessions.filter { session in
            guard let sessionDate = DateFormatter.dailyFormat.date(from: session.date) else { return false }
            return sessionDate >= monthAgo && session.type == .focus && session.completedSuccessfully
        }
        thisMonthHours = thisMonthSessions.reduce(0) { $0 + $1.duration } / 3600.0
    }
    
    private func resetStatistics() {
        studySessions = 0
        focusSessions = 0
        totalHours = 0.0
        totalBreakTime = 0.0
        averageSessionLength = 0.0
        completionRate = 0.0
        longestSessionMinutes = 0
        streakDays = 0
        currentStreak = 0
        thisWeekSessions = 0
        thisMonthHours = 0.0
        mostProductiveDay = ""
    }
    
    // MARK: - Manual Refresh
    func refreshStatistics() {
        guard let userId = auth.currentUser?.uid else {
            errorMessage = "No authenticated user"
            return
        }
        
        stopListening()
        startListening(userId: userId)
    }
}

// MARK: - Helper Extensions
extension Array where Element: Hashable {
    func unique() -> [Element] {
        var seen: Set<Element> = []
        return filter { seen.insert($0).inserted }
    }
}

// MARK: - Statistics Summary Helpers
extension UserStatsViewModel {
    var statisticsSummary: String {
        return """
        📊 Study Statistics:
        • Focus Sessions: \(studySessions)
        • Total Study Time: \(String(format: "%.1f", totalHours)) hours
        • Current Streak: \(currentStreak) days
        • Completion Rate: \(String(format: "%.0f", completionRate * 100))%
        • Average Session: \(String(format: "%.0f", averageSessionLength)) minutes
        """
    }
    
    var weeklyProgress: String {
        return "This week: \(thisWeekSessions) sessions"
    }
    
    var monthlyProgress: String {
        return "This month: \(String(format: "%.1f", thisMonthHours)) hours"
    }
}
