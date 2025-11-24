import SwiftUI

struct GroupsView: View {
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
                        // Header Stats
                        groupStatsSection
                        
                        // My Groups Section
                        myGroupsSection
                        
                        // Discover Groups
                        discoverGroupsSection
                        
                        // Recent Group Activity
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
        }
        .sheet(isPresented: $showingJoinGroup) {
            JoinGroupView()
        }
        .sheet(item: $selectedGroup) { group in
            GroupDetailView(group: group)
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
            
            LazyVStack(spacing: 10) {
                ForEach(groupsViewModel.recentActivities, id: \.id) { activity in
                    ActivityRow(activity: activity)
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

// MARK: - Supporting Views
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
                // Group Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(group.subject.color.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Text(String(group.name.prefix(2).uppercased()))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(group.subject.color)
                }
                
                // Group Info
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
                
                // Status Indicator
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
            // Group Header
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
            
            // Group Stats
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
            
            // Join Button
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

#Preview {
    GroupsView()
}
