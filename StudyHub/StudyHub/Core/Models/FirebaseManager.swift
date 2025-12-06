import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    
    let auth = Auth.auth()
    let firestore = Firestore.firestore()
    
    private init() {
        // Firebase is configured in StudyHubApp.swift
    }
}

// MARK: - User Profile Model for Firestore
struct UserProfile: Identifiable, Codable {
    let id: String // Firebase UID
    var fullName: String
    var email: String
    
    // Academic Information
    var universityName: String
    var majorFieldOfStudy: String
    var yearOfStudy: String
    
    // Study Preferences
    var preferredStudyDuration: Int
    var preferredBreakDuration: Int
    var notificationsEnabled: Bool
    var reminderNotifications: Bool
    var achievementNotifications: Bool
    
    // Metadata
    var createdDate: Date
    var profileImageURL: String?
    
    init(uid: String, fullName: String, email: String, universityName: String, majorFieldOfStudy: String, yearOfStudy: String, preferredStudyDuration: Int, preferredBreakDuration: Int, notificationsEnabled: Bool, reminderNotifications: Bool, achievementNotifications: Bool) {
        self.id = uid
        self.fullName = fullName
        self.email = email
        self.universityName = universityName
        self.majorFieldOfStudy = majorFieldOfStudy
        self.yearOfStudy = yearOfStudy
        self.preferredStudyDuration = preferredStudyDuration
        self.preferredBreakDuration = preferredBreakDuration
        self.notificationsEnabled = notificationsEnabled
        self.reminderNotifications = reminderNotifications
        self.achievementNotifications = achievementNotifications
        self.createdDate = Date()
        self.profileImageURL = nil
    }
}
