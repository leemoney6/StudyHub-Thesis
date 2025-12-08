import SwiftUI

struct GroupsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var groupsViewModel = StudyGroupsViewModel()
    
    @State private var showingCreateGroup = false
    @State private var showingJoinGroup = false
    @State private var selectedGroup: StudyGroup?
    
    var body: some View {
        NavigationView {
            ZStack {
                enhancedBackground
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header stats
                        groupStatsSection
                        
                        // My Groups
                        myGroupsSection
                        
                        // Discover Groups
                        discoverGroupsSection
                        
                        // Recent Activity
                        recentActivitySection
                        
                        Spacer(minLength: 50)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Study Groups")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Create Group") {
                            showingCreateGroup = true
                        }
                        Button("Join with Code") {
                            showingJoinGroup = true
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.cyan)
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateGroup) {
            CreateGroupView()
                .environmentObject(groupsViewModel)
        }
        .sheet(isPresented: $showingJoinGroup) {
            JoinGroupView()
                .environmentObject(groupsViewModel)
        }
        .sheet(item: $selectedGroup) { group in
            GroupDetailView(group: group)
        }
        .onAppear {
            if let uid = authViewModel.currentUser?.uid {
                groupsViewModel.configure(userId: uid)
            }
        }
    }
}

// MARK: - Sections

private extension GroupsView {
    
    var groupStatsSection: some View {
        HStack(spacing: 16) {
            GroupStatCard(
                title: "My Groups",
                value: "\(groupsViewModel.myGroups.count)",
                icon: "person.3.fill",
                color: .blue
            )
            
            GroupStatCard(
                title: "Total Sessions",
                value: "\(groupsViewModel.totalGroupSessions)",
                icon: "clock.fill",
                color: .green
            )
            
            GroupStatCard(
                title: "This Week",
                value: "\(groupsViewModel.weeklySessionsCount)",
                icon: "calendar.badge.clock",
                color: .orange
            )
        }
        .padding(.vertical, 10)
    }
    
    var myGroupsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "My Groups", icon: "person.3.fill")
            
            if groupsViewModel.myGroups.isEmpty {
                emptyGroupsState
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(groupsViewModel.myGroups, id: \.id) { group in
                        GroupCard(group: group) {
                            selectedGroup = group
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(cardBackground)
    }
    
    var emptyGroupsState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No Study Groups Yet")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("Create or join a study group to collaborate with others and stay motivated!")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            
            Button("Create Your First Group") {
                showingCreateGroup = true
            }
            .buttonStyle(PrimaryButtonStyle(color: .cyan))
        }
        .padding(.vertical, 20)
    }
    
    var discoverGroupsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Discover Groups", icon: "magnifyingglass")
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(groupsViewModel.discoverableGroups, id: \.id) { group in
                        DiscoverGroupCard(group: group) {
                            groupsViewModel.joinGroup(group)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 20)
        .background(cardBackground)
    }
    
    var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Recent Activity", icon: "clock.arrow.circlepath")
            
            if groupsViewModel.recentActivities.isEmpty {
                Text("No recent group activity yet.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(groupsViewModel.recentActivities, id: \.id) { activity in
                        ActivityRow(activity: activity)
                    }
                }
            }
        }
        .padding(20)
        .background(cardBackground)
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
}

// MARK: - Supporting Views (same UI as you had)

struct GroupStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .fontWeight(.semibold)
            }
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct GroupCard: View {
    let group: StudyGroup
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(group.subject.color.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Text(String(group.name.prefix(2).uppercased()))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(group.subject.color)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(group.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        if group.isActive {
                            Circle()
                                .fill(.green)
                                .frame(width: 8, height: 8)
                        }
                    }
                    
                    Text(group.subject.rawValue)
                        .font(.subheadline)
                        .foregroundColor(group.subject.color)
                    
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2")
                                .font(.caption)
                            Text("\(group.memberCount)")
                                .font(.caption)
                        }
                        .foregroundColor(.white.opacity(0.7))
                        
                        HStack(spacing: 4) {
                            Image(systemName: "target")
                                .font(.caption)
                            Text("\(group.weeklyGoal)h/week")
                                .font(.caption)
                        }
                        .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    if group.hasActiveSession {
                        VStack(spacing: 2) {
                            Circle()
                                .fill(.red)
                                .frame(width: 8, height: 8)
                            Text("Live")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.red)
                        }
                    } else {
                        Text(group.lastActive, style: .relative)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.black.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(group.subject.color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DiscoverGroupCard: View {
    let group: StudyGroup
    let onJoin: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(group.subject.color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Text(String(group.name.prefix(2).uppercased()))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(group.subject.color)
                }
                
                VStack(spacing: 4) {
                    Text(group.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    
                    Text(group.subject.rawValue)
                        .font(.caption)
                        .foregroundColor(group.subject.color)
                }
            }
            
            VStack(spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "person.2")
                        .font(.caption2)
                    Text("\(group.memberCount) members")
                        .font(.caption2)
                }
                .foregroundColor(.white.opacity(0.7))
                
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text("\(group.weeklyGoal)h goal")
                        .font(.caption2)
                }
                .foregroundColor(.white.opacity(0.7))
            }
            
            Button("Join") {
                onJoin()
            }
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(width: 60, height: 28)
            .background(group.subject.color.opacity(0.8))
            .cornerRadius(14)
        }
        .frame(width: 140)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct ActivityRow: View {
    let activity: GroupActivity
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(activity.type.color)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.description)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text(activity.groupName)
                    .font(.caption)
                    .foregroundColor(.cyan)
            }
            
            Spacer()
            
            Text(activity.timestamp, style: .relative)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Create / Join / Detail views (unchanged visually, but using VM)

struct CreateGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var groupsViewModel: StudyGroupsViewModel
    
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
                        groupIconPreview
                        groupDetailsForm
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
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        Task {
                            do {
                                try await groupsViewModel.createGroup(
                                    name: groupName,
                                    subject: selectedSubject,
                                    weeklyGoal: weeklyGoal,
                                    isPublic: isPublic
                                )
                                dismiss()
                            } catch {
                                print("❌ Failed to create group:", error.localizedDescription)
                            }
                        }
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
            SectionHeader(title: "Settings", icon: "gearshape")
            
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
}

struct JoinGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var groupsViewModel: StudyGroupsViewModel
    
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
                            .textInputAutocapitalization(.characters)
                        
                        Button("Join Group") {
                            Task {
                                do {
                                    try await groupsViewModel.joinGroup(code: groupCode)
                                    dismiss()
                                } catch {
                                    print("❌ Failed to join group:", error.localizedDescription)
                                }
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle(color: .cyan))
                        .disabled(groupCode.trimmingCharacters(in: .whitespaces).count < 6)
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
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
    }
}

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
                    Button("Close") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
    }
}

#Preview {
    GroupsView()
        .environmentObject(AuthViewModel())
}
