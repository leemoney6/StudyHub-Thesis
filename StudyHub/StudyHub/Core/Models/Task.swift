import Foundation
import SwiftUI
import FirebaseFirestore

struct StudyTask: Identifiable, Codable {
    var id = UUID()
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
    
    // MARK: - Custom Codable for Firebase
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // ← FIXED: Handle ID properly from Firestore
        if let idString = try? container.decode(String.self, forKey: .id) {
            if let uuid = UUID(uuidString: idString) {
                self.id = uuid
            } else {
                // If it's not a valid UUID string, generate a new one
                self.id = UUID()
            }
        } else {
            self.id = UUID()
        }
        
        self.title = try container.decode(String.self, forKey: .title)
        self.description = try container.decode(String.self, forKey: .description)
        self.priority = try container.decode(TaskPriority.self, forKey: .priority)
        self.isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        self.subject = try container.decode(String.self, forKey: .subject)
        
        // Handle Firestore Timestamp conversion
        if let timestamp = try? container.decode(Timestamp.self, forKey: .dueDate) {
            self.dueDate = timestamp.dateValue()
        } else {
            self.dueDate = try container.decode(Date.self, forKey: .dueDate)
        }
        
        if let timestamp = try? container.decode(Timestamp.self, forKey: .createdDate) {
            self.createdDate = timestamp.dateValue()
        } else {
            self.createdDate = try container.decode(Date.self, forKey: .createdDate)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id.uuidString, forKey: .id) // Encode as string for Firestore
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(priority, forKey: .priority)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encode(subject, forKey: .subject)
        try container.encode(Timestamp(date: dueDate), forKey: .dueDate)
        try container.encode(Timestamp(date: createdDate), forKey: .createdDate)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, title, description, priority, isCompleted, subject, dueDate, createdDate
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
