import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore


// MARK: - Study Group Model

struct StudyGroup: Identifiable, Codable {
    @DocumentID var id: String?              // Firestore document ID
    
    var name: String
    var subject: StudySubject
    var weeklyGoal: Int                      // hours per week
    var isPublic: Bool
    var createdBy: String
    var createdDate: Date
    var memberIds: [String]
    var lastActive: Date
    var hasActiveSession: Bool
    var groupCode: String                    // 6-char join code
    
    // Computed for UI
    var memberCount: Int { memberIds.count }
    var isActive: Bool { hasActiveSession }
}

// MARK: - Study Subject Enum

enum StudySubject: String, CaseIterable, Codable {
    case mathematics = "Mathematics"
    case physics = "Physics"
    case chemistry = "Chemistry"
    case biology = "Biology"
    case computerScience = "Computer Science"
    case history = "History"
    case literature = "Literature"
    case economics = "Economics"
    case psychology = "Psychology"
    case engineering = "Engineering"
    
    var color: Color {
        switch self {
        case .mathematics:     return .blue
        case .physics:         return .purple
        case .chemistry:       return .green
        case .biology:         return .orange
        case .computerScience: return .cyan
        case .history:         return .brown
        case .literature:      return .pink
        case .economics:       return .yellow
        case .psychology:      return .indigo
        case .engineering:     return .red
        }
    }
    
    var icon: String {
        switch self {
        case .mathematics:     return "function"
        case .physics:         return "atom"
        case .chemistry:       return "flask"
        case .biology:         return "leaf"
        case .computerScience: return "laptopcomputer"
        case .history:         return "clock"
        case .literature:      return "book"
        case .economics:       return "chart.line.uptrend.xyaxis"
        case .psychology:      return "brain.head.profile"
        case .engineering:     return "gearshape.2"
        }
    }
}

// MARK: - Group Activity Models

struct GroupActivity: Identifiable, Codable {
    let id = UUID()
    let type: ActivityType
    let description: String
    let groupName: String
    let timestamp: Date
}

enum ActivityType: String, Codable {
    case memberJoined      = "member_joined"
    case memberLeft        = "member_left"
    case sessionStarted    = "session_started"
    case sessionCompleted  = "session_completed"
    case goalAchieved      = "goal_achieved"
    case groupCreated      = "group_created"
    case taskShared        = "task_shared"
    
    var color: Color {
        switch self {
        case .memberJoined:     return .green
        case .memberLeft:       return .orange
        case .sessionStarted:   return .blue
        case .sessionCompleted: return .cyan
        case .goalAchieved:     return .purple
        case .groupCreated:     return .yellow
        case .taskShared:       return .pink
        }
    }
}

// MARK: - ViewModel

@MainActor
class StudyGroupsViewModel: ObservableObject {
    @Published var myGroups: [StudyGroup] = []
    @Published var discoverableGroups: [StudyGroup] = []
    @Published var recentActivities: [GroupActivity] = []
    @Published var totalGroupSessions: Int = 0
    @Published var weeklySessionsCount: Int = 0
    
    private let db = Firestore.firestore()
    private var listeners: [ListenerRegistration] = []
    private var currentUserId: String?
   
    
    // Call this from GroupsView when you know the uid
    func configure(userId: String) {
        guard currentUserId != userId else { return }
        currentUserId = userId
        startListeners()
    }
    
    // MARK: - Firestore listeners
    
    private func startListeners() {
        stopListeners()
        guard let userId = currentUserId else { return }
        
        // 1️⃣ My groups (where I'm a member)
        let myListener = db.collection("groups")
            .whereField("memberIds", arrayContains: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self,
                      let docs = snapshot?.documents else { return }
                
                let groups = docs.compactMap { try? $0.data(as: StudyGroup.self) }
                Task { @MainActor in
                    self.myGroups = groups
                }
            }
        
        listeners.append(myListener)
        
        // 2️⃣ Public discoverable groups
        let discoverListener = db.collection("groups")
            .whereField("isPublic", isEqualTo: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self,
                      let docs = snapshot?.documents else { return }
                
                let groups = docs.compactMap { try? $0.data(as: StudyGroup.self) }
                Task { @MainActor in
                    let myIds = Set(self.myGroups.compactMap { $0.id })
                    self.discoverableGroups = groups.filter { group in
                        guard let id = group.id else { return false }
                        return !myIds.contains(id)
                    }
                }
            }
        
        listeners.append(discoverListener)
    }
    
    func stopListeners() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }
    
    // MARK: - Group Management
    
    func createGroup(name: String,
                     subject: StudySubject,
                     weeklyGoal: Int,
                     isPublic: Bool) async throws {
        guard let userId = currentUserId else { return }
        
        let now = Date()
        let code = Self.generateGroupCode()
        
        let group = StudyGroup(
            id: nil,
            name: name,
            subject: subject,
            weeklyGoal: weeklyGoal,
            isPublic: isPublic,
            createdBy: userId,
            createdDate: now,
            memberIds: [userId],
            lastActive: now,
            hasActiveSession: false,
            groupCode: code
        )
        
        _ = try db.collection("groups").addDocument(from: group)
        
        addActivity(.groupCreated,
                    description: "You created \(name)",
                    groupName: name)
    }
    
    func joinGroup(code: String) async throws {
        guard let userId = currentUserId else { return }
        
        let cleanCode = code.uppercased()
        
        let snapshot = try await db.collection("groups")
            .whereField("groupCode", isEqualTo: cleanCode)
            .limit(to: 1)
            .getDocuments()
        
        guard let doc = snapshot.documents.first else {
            throw NSError(domain: "StudyGroups",
                          code: 404,
                          userInfo: [NSLocalizedDescriptionKey: "Group not found"])
        }
        
        try await doc.reference.updateData([
            "memberIds": FieldValue.arrayUnion([userId])
        ])
        
        if let group = try? doc.data(as: StudyGroup.self) {
            addActivity(.memberJoined,
                        description: "You joined \(group.name)",
                        groupName: group.name)
        }
    }
    
    // Used by Discover card
    func joinGroup(_ group: StudyGroup) {
        guard let groupId = group.id,
              let userId = currentUserId else { return }
        
        Task {
            do {
                try await db.collection("groups").document(groupId).updateData([
                    "memberIds": FieldValue.arrayUnion([userId])
                ])
                
                addActivity(.memberJoined,
                            description: "You joined \(group.name)",
                            groupName: group.name)
            } catch {
                print("❌ Failed to join group:", error.localizedDescription)
            }
        }
    }
    
    func leaveGroup(_ group: StudyGroup) {
        guard let groupId = group.id,
              let userId = currentUserId else { return }
        
        Task {
            do {
                try await db.collection("groups").document(groupId).updateData([
                    "memberIds": FieldValue.arrayRemove([userId])
                ])
                
                addActivity(.memberLeft,
                            description: "You left \(group.name)",
                            groupName: group.name)
            } catch {
                print("❌ Failed to leave group:", error.localizedDescription)
            }
        }
    }
    
    func startGroupSession(_ group: StudyGroup) {
        guard let groupId = group.id else { return }
        
        Task {
            do {
                try await db.collection("groups").document(groupId).updateData([
                    "hasActiveSession": true,
                    "lastActive": Date()
                ])
                
                addActivity(.sessionStarted,
                            description: "Group study session started",
                            groupName: group.name)
            } catch {
                print("❌ Failed to start session:", error.localizedDescription)
            }
        }
    }
    
    func endGroupSession(_ group: StudyGroup) {
        guard let groupId = group.id else { return }
        
        Task {
            do {
                try await db.collection("groups").document(groupId).updateData([
                    "hasActiveSession": false,
                    "lastActive": Date()
                ])
                
                totalGroupSessions += 1
                weeklySessionsCount += 1
                
                addActivity(.sessionCompleted,
                            description: "Completed group study session",
                            groupName: group.name)
            } catch {
                print("❌ Failed to end session:", error.localizedDescription)
            }
        }
    }
    
    // MARK: - Activity Feed (local only for now)
    
    private func addActivity(_ type: ActivityType,
                             description: String,
                             groupName: String) {
        let activity = GroupActivity(
            type: type,
            description: description,
            groupName: groupName,
            timestamp: Date()
        )
        
        recentActivities.insert(activity, at: 0)
        if recentActivities.count > 10 {
            recentActivities = Array(recentActivities.prefix(10))
        }
    }
    
    // MARK: - Helpers
    
    private static func generateGroupCode() -> String {
        let characters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
        return String((0..<6).compactMap { _ in characters.randomElement() })
    }
}

// MARK: - Shared Button Style (used by multiple views)

struct PrimaryButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(color.opacity(configuration.isPressed ? 0.7 : 1.0))
            .cornerRadius(25)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
