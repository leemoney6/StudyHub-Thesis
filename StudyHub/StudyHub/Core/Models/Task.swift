import Foundation
import SwiftUI

struct StudyTask: Identifiable, Codable {  // Changed from Task to StudyTask
    let id = UUID()
    var title: String
    var description: String
    var dueDate: Date
    var priority: TaskPriority
    var isCompleted: Bool
    var subject: String
    var createdDate: Date
    
    init(title: String, description: String = "", dueDate: Date, priority: TaskPriority, subject: String) {
        self.title = title
        self.description = description
        self.dueDate = dueDate
        self.priority = priority
        self.isCompleted = false
        self.subject = subject
        self.createdDate = Date()
    }
}

enum TaskPriority: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case urgent = "Urgent"
    
    var color: Color {
        switch self {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        case .urgent: return .purple
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "circle"
        case .medium: return "circle.fill"
        case .high: return "exclamationmark.circle.fill"
        case .urgent: return "flame.fill"
        }
    }
}
