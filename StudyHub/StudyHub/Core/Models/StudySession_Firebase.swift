import Foundation
import SwiftUI
import FirebaseFirestore

// MARK: - Firebase-Compatible Study Session Model
struct StudySession: Identifiable, Codable {
    var id = UUID()
    let type: PomodoroPhase
    let duration: TimeInterval // seconds (1500, 300, 900)
    let startTime: Date
    let endTime: Date
    let completedSuccessfully: Bool
    let taskId: String? // UUID string - links to specific task
    let taskTitle: String? // Cache task title for display
    let date: String // YYYY-MM-DD for daily grouping
    
    // Computed properties for display
    var displayDuration: String {
        let minutes = Int(duration) / 60
        return "\(minutes) min"
    }
    
    var isToday: Bool {
        let today = DateFormatter.dailyFormat.string(from: Date())
        return date == today
    }
    
    init(type: PomodoroPhase, duration: TimeInterval, startTime: Date, completedSuccessfully: Bool, taskId: String? = nil, taskTitle: String? = nil) {
        self.type = type
        self.duration = duration
        self.startTime = startTime
        self.endTime = startTime.addingTimeInterval(duration)
        self.completedSuccessfully = completedSuccessfully
        self.taskId = taskId
        self.taskTitle = taskTitle
        self.date = DateFormatter.dailyFormat.string(from: startTime)
    }
}

// MARK: - Firebase Codable Implementation
extension StudySession {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle ID as string from Firestore
        if let idString = try? container.decode(String.self, forKey: .id),
           let uuid = UUID(uuidString: idString) {
            self.id = uuid
        } else {
            self.id = UUID()
        }
        
        self.type = try container.decode(PomodoroPhase.self, forKey: .type)
        self.duration = try container.decode(TimeInterval.self, forKey: .duration)
        self.completedSuccessfully = try container.decode(Bool.self, forKey: .completedSuccessfully)
        self.taskId = try? container.decode(String.self, forKey: .taskId)
        self.taskTitle = try? container.decode(String.self, forKey: .taskTitle)
        self.date = try container.decode(String.self, forKey: .date)
        
        // Handle Firestore Timestamps
        if let timestamp = try? container.decode(Timestamp.self, forKey: .startTime) {
            self.startTime = timestamp.dateValue()
        } else {
            self.startTime = try container.decode(Date.self, forKey: .startTime)
        }
        
        if let timestamp = try? container.decode(Timestamp.self, forKey: .endTime) {
            self.endTime = timestamp.dateValue()
        } else {
            self.endTime = try container.decode(Date.self, forKey: .endTime)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id.uuidString, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(duration, forKey: .duration)
        try container.encode(Timestamp(date: startTime), forKey: .startTime)
        try container.encode(Timestamp(date: endTime), forKey: .endTime)
        try container.encode(completedSuccessfully, forKey: .completedSuccessfully)
        try container.encodeIfPresent(taskId, forKey: .taskId)
        try container.encodeIfPresent(taskTitle, forKey: .taskTitle)
        try container.encode(date, forKey: .date)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, type, duration, startTime, endTime, completedSuccessfully, taskId, taskTitle, date
    }
}

// MARK: - Date Formatter Extension
extension DateFormatter {
    static let dailyFormat: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static let sessionFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter
    }()
}

// MARK: - Session Statistics Helper
struct SessionStatistics {
    let totalSessions: Int
    let focusSessions: Int
    let totalFocusTime: TimeInterval // in seconds
    let completionRate: Double
    let averageSessionLength: TimeInterval
    let longestStreak: Int
    
    static let empty = SessionStatistics(
        totalSessions: 0,
        focusSessions: 0,
        totalFocusTime: 0,
        completionRate: 0.0,
        averageSessionLength: 0,
        longestStreak: 0
    )
}

// MARK: - Daily Session Summary
struct DailySessionSummary {
    let date: String
    let focusMinutes: Int
    let shortBreaks: Int
    let longBreaks: Int
    let completedSessions: Int
    let totalSessions: Int
    
    var completionRate: Double {
        guard totalSessions > 0 else { return 0.0 }
        return Double(completedSessions) / Double(totalSessions)
    }
}
