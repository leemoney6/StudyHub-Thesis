import Foundation
import SwiftUI
import Combine

// MARK: - Study Groups ViewModel
class StudyGroupsViewModel: ObservableObject {
    @Published var myGroups: [StudyGroup] = []
    @Published var discoverableGroups: [StudyGroup] = []
    @Published var recentActivities: [GroupActivity] = []
    @Published var totalGroupSessions: Int = 0
    @Published var weeklySessionsCount: Int = 0
    
    init() {
        loadMockData()
    }
    
    // MARK: - Group Management
    func createGroup(_ group: StudyGroup) {
        myGroups.append(group)
        addActivity(.groupCreated, description: "You created \(group.name)", groupName: group.name)
    }
    
    func joinGroup(_ group: StudyGroup) {
        var joinedGroup = group
        joinedGroup.memberCount += 1
        myGroups.append(joinedGroup)
        
        // Remove from discoverable groups
        discoverableGroups.removeAll { $0.id == group.id }
        
        addActivity(.memberJoined, description: "You joined \(group.name)", groupName: group.name)
    }
    
    func leaveGroup(_ group: StudyGroup) {
        myGroups.removeAll { $0.id == group.id }
        addActivity(.memberLeft, description: "You left \(group.name)", groupName: group.name)
    }
    
    func startGroupSession(_ group: StudyGroup) {
        if let index = myGroups.firstIndex(where: { $0.id == group.id }) {
            myGroups[index].hasActiveSession = true
            myGroups[index].isActive = true
        }
        addActivity(.sessionStarted, description: "Group study session started", groupName: group.name)
    }
    
    func endGroupSession(_ group: StudyGroup) {
        if let index = myGroups.firstIndex(where: { $0.id == group.id }) {
            myGroups[index].hasActiveSession = false
            myGroups[index].lastActive = Date()
        }
        totalGroupSessions += 1
        weeklySessionsCount += 1
        addActivity(.sessionCompleted, description: "Completed group study session", groupName: group.name)
    }
    
    private func addActivity(_ type: ActivityType, description: String, groupName: String) {
        let activity = GroupActivity(
            type: type,
            description: description,
            groupName: groupName,
            timestamp: Date()
        )
        recentActivities.insert(activity, at: 0)
        
        // Keep only recent 10 activities
        if recentActivities.count > 10 {
            recentActivities = Array(recentActivities.prefix(10))
        }
    }
    
    // MARK: - Mock Data
    private func loadMockData() {
        // My Groups
        myGroups = [
            StudyGroup(
                name: "CS Study Squad",
                subject: .computerScience,
                memberCount: 8,
                weeklyGoal: 15,
                isActive: true,
                hasActiveSession: true,
                lastActive: Date()
            ),
            StudyGroup(
                name: "Math Masters",
                subject: .mathematics,
                memberCount: 12,
                weeklyGoal: 10,
                isActive: false,
                hasActiveSession: false,
                lastActive: Date().addingTimeInterval(-3600)
            ),
            StudyGroup(
                name: "Physics Force",
                subject: .physics,
                memberCount: 6,
                weeklyGoal: 8,
                isActive: false,
                hasActiveSession: false,
                lastActive: Date().addingTimeInterval(-7200)
            )
        ]
        
        // Discoverable Groups
        discoverableGroups = [
            StudyGroup(
                name: "Chemistry Champions",
                subject: .chemistry,
                memberCount: 15,
                weeklyGoal: 12,
                isActive: true,
                hasActiveSession: false,
                lastActive: Date().addingTimeInterval(-1800)
            ),
            StudyGroup(
                name: "History Hunters",
                subject: .history,
                memberCount: 9,
                weeklyGoal: 6,
                isActive: true,
                hasActiveSession: false,
                lastActive: Date().addingTimeInterval(-900)
            ),
            StudyGroup(
                name: "Bio Buddies",
                subject: .biology,
                memberCount: 11,
                weeklyGoal: 14,
                isActive: false,
                hasActiveSession: false,
                lastActive: Date().addingTimeInterval(-5400)
            ),
            StudyGroup(
                name: "Literature League",
                subject: .literature,
                memberCount: 7,
                weeklyGoal: 8,
                isActive: true,
                hasActiveSession: false,
                lastActive: Date().addingTimeInterval(-2700)
            )
        ]
        
        // Recent Activities
        recentActivities = [
            GroupActivity(
                type: .sessionCompleted,
                description: "Completed 45-min group study session",
                groupName: "CS Study Squad",
                timestamp: Date().addingTimeInterval(-1800)
            ),
            GroupActivity(
                type: .memberJoined,
                description: "Sarah joined the group",
                groupName: "Math Masters",
                timestamp: Date().addingTimeInterval(-3600)
            ),
            GroupActivity(
                type: .goalAchieved,
                description: "Group reached weekly goal!",
                groupName: "Physics Force",
                timestamp: Date().addingTimeInterval(-7200)
            ),
            GroupActivity(
                type: .sessionStarted,
                description: "Group study session started",
                groupName: "CS Study Squad",
                timestamp: Date().addingTimeInterval(-10800)
            )
        ]
        
        totalGroupSessions = 23
        weeklySessionsCount = 7
    }
}

// MARK: - Study Group Model
struct StudyGroup: Identifiable, Codable {
    let id = UUID()
    var name: String
    var subject: StudySubject
    var memberCount: Int
    var weeklyGoal: Int // hours
    var isActive: Bool
    var hasActiveSession: Bool
    var lastActive: Date
    var createdDate: Date = Date()
    var groupCode: String = ""
    
    init(name: String, subject: StudySubject, memberCount: Int, weeklyGoal: Int, isActive: Bool, hasActiveSession: Bool, lastActive: Date) {
        self.name = name
        self.subject = subject
        self.memberCount = memberCount
        self.weeklyGoal = weeklyGoal
        self.isActive = isActive
        self.hasActiveSession = hasActiveSession
        self.lastActive = lastActive
        self.groupCode = generateGroupCode()
    }
    
    private func generateGroupCode() -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<6).map{ _ in characters.randomElement()! })
    }
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
        case .mathematics:
            return .blue
        case .physics:
            return .purple
        case .chemistry:
            return .green
        case .biology:
            return .orange
        case .computerScience:
            return .cyan
        case .history:
            return .brown
        case .literature:
            return .pink
        case .economics:
            return .yellow
        case .psychology:
            return .indigo
        case .engineering:
            return .red
        }
    }
    
    var icon: String {
        switch self {
        case .mathematics:
            return "function"
        case .physics:
            return "atom"
        case .chemistry:
            return "flask"
        case .biology:
            return "leaf"
        case .computerScience:
            return "laptop"
        case .history:
            return "clock"
        case .literature:
            return "book"
        case .economics:
            return "chart.line.uptrend.xyaxis"
        case .psychology:
            return "brain.head.profile"
        case .engineering:
            return "gearshape.2"
        }
    }
}

// MARK: - Group Activity Model
struct GroupActivity: Identifiable, Codable {
    let id = UUID()
    let type: ActivityType
    let description: String
    let groupName: String
    let timestamp: Date
}

enum ActivityType: String, Codable {
    case memberJoined = "member_joined"
    case memberLeft = "member_left"
    case sessionStarted = "session_started"
    case sessionCompleted = "session_completed"
    case goalAchieved = "goal_achieved"
    case groupCreated = "group_created"
    case taskShared = "task_shared"
    
    var color: Color {
        switch self {
        case .memberJoined:
            return .green
        case .memberLeft:
            return .orange
        case .sessionStarted:
            return .blue
        case .sessionCompleted:
            return .cyan
        case .goalAchieved:
            return .purple
        case .groupCreated:
            return .yellow
        case .taskShared:
            return .pink
        }
    }
    
    var icon: String {
        switch self {
        case .memberJoined:
            return "person.badge.plus"
        case .memberLeft:
            return "person.badge.minus"
        case .sessionStarted:
            return "play.circle"
        case .sessionCompleted:
            return "checkmark.circle"
        case .goalAchieved:
            return "trophy"
        case .groupCreated:
            return "plus.circle"
        case .taskShared:
            return "square.and.arrow.up"
        }
    }
}

// MARK: - Create Group View
struct CreateGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var groupName = ""
    @State private var selectedSubject: StudySubject = .computerScience
    @State private var weeklyGoal: Int = 10
    @State private var isPublic = true
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Group Icon Preview
                        groupIconPreview
                        
                        // Group Details Form
                        groupDetailsForm
                        
                        // Settings
                        groupSettingsForm
                        
                        Spacer(minLength: 50)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Create Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createGroup()
                    }
                    .foregroundColor(.cyan)
                    .fontWeight(.semibold)
                    .disabled(groupName.isEmpty)
                }
            }
        }
    }
    
    private var groupIconPreview: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(selectedSubject.color.opacity(0.2))
                    .frame(width: 100, height: 100)
                
                if groupName.isEmpty {
                    Image(systemName: selectedSubject.icon)
                        .font(.system(size: 40))
                        .foregroundColor(selectedSubject.color)
                } else {
                    Text(String(groupName.prefix(2).uppercased()))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(selectedSubject.color)
                }
            }
            
            Text(groupName.isEmpty ? "Group Name" : groupName)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text(selectedSubject.rawValue)
                .font(.subheadline)
                .foregroundColor(selectedSubject.color)
        }
    }
    
    private var groupDetailsForm: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "Group Details", icon: "info.circle")
            
            VStack(spacing: 16) {
                CustomTextField(placeholder: "Group Name", text: $groupName)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Subject")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Picker("Subject", selection: $selectedSubject) {
                        ForEach(StudySubject.allCases, id: \.self) { subject in
                            HStack {
                                Image(systemName: subject.icon)
                                Text(subject.rawValue)
                            }
                            .tag(subject)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .accentColor(.cyan)
                }
            }
        }
        .padding(20)
        .background(cardBackground)
    }
    
    private var groupSettingsForm: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "Settings", icon: "gearshape" )
            
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Weekly Goal")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("\(weeklyGoal) hours per week")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Stepper("", value: $weeklyGoal, in: 1...30)
                        .labelsHidden()
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Group Visibility")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text(isPublic ? "Anyone can discover and join" : "Invite only with group code")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $isPublic)
                        .labelsHidden()
                        .toggleStyle(SwitchToggleStyle(tint: .cyan))
                }
            }
        }
        .padding(20)
        .background(cardBackground)
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(.black.opacity(0.4))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
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
    
    private func createGroup() {
        // Create group logic here
        dismiss()
    }
}

// MARK: - Join Group View
struct JoinGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var groupCode = ""
    
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
                
                VStack(spacing: 30) {
                    VStack(spacing: 16) {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 64))
                            .foregroundColor(.cyan)
                        
                        VStack(spacing: 8) {
                            Text("Join Study Group")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Enter the 6-character group code to join")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                    }
                    
                    VStack(spacing: 20) {
                        CustomTextField(placeholder: "Group Code (e.g. ABC123)", text: $groupCode)
                            .textCase(.uppercase)
                        
                        Button("Join Group") {
                            joinGroup()
                        }
                        .buttonStyle(PrimaryButtonStyle(color: .cyan))
                        .disabled(groupCode.count < 6)
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
                .padding(40)
            }
            .navigationTitle("Join Group")
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
    
    private func joinGroup() {
        // Join group logic here
        dismiss()
    }
}

// MARK: - Group Detail View (Placeholder)
struct GroupDetailView: View {
    let group: StudyGroup
    @Environment(\.dismiss) private var dismiss
    
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
                
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(group.subject.color.opacity(0.2))
                                .frame(width: 100, height: 100)
                            
                            Text(String(group.name.prefix(2).uppercased()))
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(group.subject.color)
                        }
                        
                        VStack(spacing: 8) {
                            Text(group.name)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text(group.subject.rawValue)
                                .font(.subheadline)
                                .foregroundColor(group.subject.color)
                        }
                    }
                    
                    Text("Group Detail View - Coming Soon!")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                }
                .padding(40)
            }
            .navigationTitle(group.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

#Preview {
    GroupsView()
}
