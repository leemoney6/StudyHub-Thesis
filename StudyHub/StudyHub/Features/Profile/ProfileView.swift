import SwiftUI
import Firebase

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var statsViewModel = UserStatsViewModel() // ← Uses Firebase version!
    @State private var showingEditProfile = false
    @State private var showingLogoutAlert = false
    @State private var showingAppSettings = false  // ← NEW
    @State private var showingHelpSupport = false  // ← NEW
    
    var body: some View {
        NavigationView {
            ZStack {
                enhancedBackground
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Header Section
                        profileHeaderSection
                        
                        // User Info Section
                        userInfoSection
                        
                        // Study Preferences Section
                        studyPreferencesSection
                        
                        // Statistics Section (NOW WITH REAL FIREBASE DATA!)
                        statisticsSection
                        
                        // Account Management Section (NOW CONNECTED!)
                        accountManagementSection
                        
                        Spacer(minLength: 50)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        showingEditProfile = true
                    }
                    .foregroundColor(.cyan)
                    .fontWeight(.semibold)
                }
            }
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView()
                .environmentObject(authViewModel)
        }
        .sheet(isPresented: $showingAppSettings) {  // ← NEW
            AppSettingsView()
                .environmentObject(authViewModel)
        }
        .sheet(isPresented: $showingHelpSupport) {  // ← NEW
            HelpSupportView()
        }
        .alert("Sign Out", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                authViewModel.signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .onAppear {
            // ← FIXED: Connect to real Firebase statistics
            if let uid = authViewModel.currentUser?.uid {
                statsViewModel.startListening(userId: uid)
            }
        }
        .onDisappear {
            // Clean up listeners when view disappears
            statsViewModel.stopListening()
        }
        .onChange(of: authViewModel.isAuthenticated) { isAuthenticated in
            if isAuthenticated, let uid = authViewModel.currentUser?.uid {
                statsViewModel.startListening(userId: uid)
            } else {
                statsViewModel.stopListening()
            }
        }
    }
}

// MARK: - Profile Sections
private extension ProfileView {
    
    var profileHeaderSection: some View {
        VStack(spacing: 20) {
            // Profile Picture with glow effect
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.cyan.opacity(0.3), .blue.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .overlay {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.cyan, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                    }
                    .shadow(color: .cyan.opacity(0.3), radius: 10)
                
                Image(systemName: "person.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 12) {
                Text(authViewModel.userProfile?.fullName ?? "User")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    Image(systemName: "graduationcap.fill")
                        .foregroundColor(.cyan)
                        .font(.caption)
                    Text("\(authViewModel.userProfile?.majorFieldOfStudy ?? "Student") Student")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(darkCardBackground)
                .cornerRadius(12)
                
                // ← NEW: Show current streak prominently
                if statsViewModel.currentStreak > 0 {
                    HStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text("\(statsViewModel.currentStreak) day streak!")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.orange.opacity(0.2))
                    .cornerRadius(10)
                }
            }
        }
        .padding(24)
        .background(premiumCardBackground)
    }
    
    var userInfoSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "Personal Information", icon: "person.text.rectangle")
            
            VStack(spacing: 16) {
                InfoRow(icon: "envelope.fill", title: "Email", value: authViewModel.userProfile?.email ?? "No email")
                Divider().background(.white.opacity(0.2))
                InfoRow(icon: "building.2.fill", title: "University", value: authViewModel.userProfile?.universityName ?? "Not specified")
                Divider().background(.white.opacity(0.2))
                InfoRow(icon: "book.fill", title: "Major", value: authViewModel.userProfile?.majorFieldOfStudy ?? "Not specified")
                Divider().background(.white.opacity(0.2))
                InfoRow(icon: "graduationcap.fill", title: "Year", value: authViewModel.userProfile?.yearOfStudy ?? "Not specified")
                Divider().background(.white.opacity(0.2))
                InfoRow(icon: "calendar", title: "Member Since", value: memberSinceText)
            }
        }
        .padding(24)
        .background(premiumCardBackground)
    }
    
    private var memberSinceText: String {
        guard let createdDate = authViewModel.userProfile?.createdDate else {
            return "Recently"
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: createdDate)
    }
    
    var studyPreferencesSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "Study Preferences", icon: "slider.horizontal.3")
            
            VStack(spacing: 16) {
                PreferenceRow(
                    icon: "timer",
                    title: "Default Session",
                    value: "\(authViewModel.userProfile?.preferredStudyDuration ?? 25) minutes",
                    color: .orange
                )
                Divider().background(.white.opacity(0.2))
                PreferenceRow(
                    icon: "pause.circle.fill",
                    title: "Break Duration",
                    value: "\(authViewModel.userProfile?.preferredBreakDuration ?? 5) minutes",
                    color: .green
                )
                Divider().background(.white.opacity(0.2))
                PreferenceRow(
                    icon: "bell.fill",
                    title: "Notifications",
                    value: (authViewModel.userProfile?.notificationsEnabled ?? false) ? "Enabled" : "Disabled",
                    color: .blue
                )
                Divider().background(.white.opacity(0.2))
                // ← ENHANCED: Show actual completion rate
                PreferenceRow(
                    icon: "target",
                    title: "Completion Rate",
                    value: String(format: "%.0f%%", statsViewModel.completionRate * 100),
                    color: .purple
                )
            }
        }
        .padding(24)
        .background(premiumCardBackground)
    }
    
    // ← ENHANCED: Real Firebase Statistics Section
    var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                SectionHeader(title: "Statistics", icon: "chart.bar.fill")
                
                if statsViewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .cyan))
                        .scaleEffect(0.8)
                }
            }
            
            if statsViewModel.errorMessage.isEmpty {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    // ← REAL FIREBASE DATA
                    StatCard(
                        title: "Tasks Completed",
                        value: "\(statsViewModel.tasksCompleted)",
                        icon: "checkmark.circle.fill",
                        color: .green
                    )
                    StatCard(
                        title: "Study Sessions",
                        value: "\(statsViewModel.studySessions)",
                        icon: "clock.fill",
                        color: .cyan
                    )
                    StatCard(
                        title: "Total Hours",
                        value: String(format: "%.1f", statsViewModel.totalHours),
                        icon: "hourglass",
                        color: .orange
                    )
                    StatCard(
                        title: "Streak",
                        value: "\(statsViewModel.streakDays) days",
                        icon: "flame.fill",
                        color: .red
                    )
                }
                
                // ← NEW: Additional Statistics Row
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    StatCard(
                        title: "This Week",
                        value: "\(statsViewModel.thisWeekSessions)",
                        icon: "calendar.badge.clock",
                        color: .blue
                    )
                    StatCard(
                        title: "Avg Session",
                        value: String(format: "%.0f min", statsViewModel.averageSessionLength),
                        icon: "timer.circle",
                        color: .purple
                    )
                }
                
                // ← NEW: Detailed Statistics Summary
                if statsViewModel.studySessions > 0 {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Study Insights")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        VStack(spacing: 8) {
                            InsightRow(
                                icon: "target",
                                title: "Completion Rate",
                                value: String(format: "%.0f%%", statsViewModel.completionRate * 100),
                                color: statsViewModel.completionRate >= 0.8 ? .green : statsViewModel.completionRate >= 0.6 ? .orange : .red
                            )
                            
                            if statsViewModel.longestSessionMinutes > 0 {
                                InsightRow(
                                    icon: "stopwatch",
                                    title: "Longest Session",
                                    value: "\(statsViewModel.longestSessionMinutes) min",
                                    color: .cyan
                                )
                            }
                            
                            if !statsViewModel.mostProductiveDay.isEmpty {
                                InsightRow(
                                    icon: "calendar.badge.plus",
                                    title: "Most Productive Day",
                                    value: statsViewModel.mostProductiveDay,
                                    color: .blue
                                )
                            }
                        }
                    }
                    .padding(.top, 16)
                }
            } else {
                // Error state
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                        .font(.title2)
                    
                    Text("Unable to load statistics")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.subheadline)
                    
                    Button("Try Again") {
                        statsViewModel.refreshStatistics()
                    }
                    .foregroundColor(.cyan)
                    .fontWeight(.semibold)
                }
                .padding(.vertical, 20)
            }
        }
        .padding(24)
        .background(premiumCardBackground)
    }
    
    // ← ENHANCED: Connected Account Management Section
    var accountManagementSection: some View {
        VStack(spacing: 12) {
            // Refresh Statistics Button
            ActionButton(
                icon: "arrow.clockwise",
                title: "Refresh Statistics",
                color: .cyan,
                action: { statsViewModel.refreshStatistics() }
            )
            
            // Settings Button (NOW CONNECTED! 🎯)
            ActionButton(
                icon: "gearshape.fill",
                title: "App Settings",
                color: .blue,
                action: { showingAppSettings = true }  // ← CONNECTED!
            )
            
            // Help & Support Button (NOW CONNECTED! 🎯)
            ActionButton(
                icon: "questionmark.circle.fill",
                title: "Help & Support",
                color: .green,
                action: { showingHelpSupport = true }  // ← CONNECTED!
            )
            
            // Sign Out Button
            ActionButton(
                icon: "rectangle.portrait.and.arrow.right",
                title: "Sign Out",
                color: .red,
                action: { showingLogoutAlert = true }
            )
        }
    }
    
    // MARK: - Background Components
    var premiumCardBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.black.opacity(0.4))
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.3), .white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 10)
    }
    
    var darkCardBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(.black.opacity(0.3))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.cyan.opacity(0.3), lineWidth: 1)
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

// MARK: - Enhanced Components (Same as before)
struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.cyan)
                .font(.title3)
                .frame(width: 24)
            
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(.cyan)
                .frame(width: 24)
                .font(.system(size: 18, weight: .medium))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
    }
}

struct PreferenceRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 16, weight: .semibold))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
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

// ← NEW: Insight Row Component
struct InsightRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.caption)
                .frame(width: 20)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .padding(.vertical, 4)
    }
}

struct ActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.6))
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.black.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Edit Profile View (Same as before)
struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var fullName = ""
    @State private var email = ""
    @State private var universityName = ""
    @State private var majorFieldOfStudy = ""
    @State private var yearOfStudy = ""
    @State private var preferredStudyDuration = 25
    @State private var preferredBreakDuration = 5
    @State private var notificationsEnabled = true
    @State private var reminderNotifications = true
    @State private var achievementNotifications = true
    
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    let yearOptions = ["1st Year", "2nd Year", "3rd Year", "4th Year", "Graduate", "PhD"]
    
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
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Personal Information
                        VStack(alignment: .leading, spacing: 20) {
                            SectionHeader(title: "Personal Information", icon: "person.text.rectangle")
                            
                            VStack(spacing: 16) {
                                CustomTextField(placeholder: "Full Name", text: $fullName)
                                CustomTextField(placeholder: "Email", text: $email)
                                    .disabled(true)
                                    .opacity(0.7)
                                CustomTextField(placeholder: "University", text: $universityName)
                                CustomTextField(placeholder: "Major", text: $majorFieldOfStudy)
                                
                                Menu {
                                    ForEach(yearOptions, id: \.self) { year in
                                        Button(year) {
                                            yearOfStudy = year
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(yearOfStudy.isEmpty ? "Year of Study" : yearOfStudy)
                                            .foregroundColor(yearOfStudy.isEmpty ? .white.opacity(0.6) : .white)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .foregroundColor(.white.opacity(0.6))
                                            .font(.caption)
                                    }
                                    .font(.system(size: 15))
                                    .padding(EdgeInsets(top: 15, leading: 10, bottom: 15, trailing: 10))
                                    .background {
                                        RoundedRectangle(cornerRadius: 5)
                                            .stroke(.white.opacity(0.3), lineWidth: 1)
                                    }
                                }
                            }
                        }
                        .padding(24)
                        .background(cardBackground)
                        
                        // Study Preferences
                        VStack(alignment: .leading, spacing: 20) {
                            SectionHeader(title: "Study Preferences", icon: "slider.horizontal.3")
                            
                            VStack(spacing: 20) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Study Session: \(preferredStudyDuration) minutes")
                                        .foregroundColor(.white)
                                        .fontWeight(.semibold)
                                    
                                    Slider(
                                        value: Binding(
                                            get: { Double(preferredStudyDuration) },
                                            set: { preferredStudyDuration = Int($0) }
                                        ),
                                        in: 15...60,
                                        step: 5
                                    )
                                    .accentColor(.orange)
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Break Duration: \(preferredBreakDuration) minutes")
                                        .foregroundColor(.white)
                                        .fontWeight(.semibold)
                                    
                                    Slider(
                                        value: Binding(
                                            get: { Double(preferredBreakDuration) },
                                            set: { preferredBreakDuration = Int($0) }
                                        ),
                                        in: 5...20,
                                        step: 5
                                    )
                                    .accentColor(.green)
                                }
                                
                                HStack {
                                    Text("Notifications")
                                        .foregroundColor(.white)
                                        .fontWeight(.semibold)
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: $notificationsEnabled)
                                        .toggleStyle(SwitchToggleStyle(tint: .cyan))
                                }
                            }
                        }
                        .padding(24)
                        .background(cardBackground)
                        
                        Spacer(minLength: 50)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await saveProfile()
                        }
                    }
                    .foregroundColor(.cyan)
                    .fontWeight(.semibold)
                    .disabled(isLoading || !isValidForm)
                }
            }
            .onAppear {
                loadUserData()
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func loadUserData() {
        guard let profile = authViewModel.userProfile else { return }
        
        fullName = profile.fullName
        email = profile.email
        universityName = profile.universityName
        majorFieldOfStudy = profile.majorFieldOfStudy
        yearOfStudy = profile.yearOfStudy
        preferredStudyDuration = profile.preferredStudyDuration
        preferredBreakDuration = profile.preferredBreakDuration
        notificationsEnabled = profile.notificationsEnabled
        reminderNotifications = profile.reminderNotifications
        achievementNotifications = profile.achievementNotifications
    }
    
    private func saveProfile() async {
        guard var profile = authViewModel.userProfile else {
            errorMessage = "Unable to load profile data"
            showingError = true
            return
        }
        
        isLoading = true
        
        profile.fullName = fullName.trimmingCharacters(in: .whitespaces)
        profile.universityName = universityName.trimmingCharacters(in: .whitespaces)
        profile.majorFieldOfStudy = majorFieldOfStudy.trimmingCharacters(in: .whitespaces)
        profile.yearOfStudy = yearOfStudy
        profile.preferredStudyDuration = preferredStudyDuration
        profile.preferredBreakDuration = preferredBreakDuration
        profile.notificationsEnabled = notificationsEnabled
        profile.reminderNotifications = reminderNotifications
        profile.achievementNotifications = achievementNotifications
        
        do {
            let firestore = Firestore.firestore()
            let data = try Firestore.Encoder().encode(profile)
            try await firestore.collection("users").document(profile.id).setData(data)
            
            await MainActor.run {
                authViewModel.userProfile = profile
                isLoading = false
                dismiss()
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = "Failed to save profile: \(error.localizedDescription)"
                showingError = true
            }
        }
    }
    
    private var isValidForm: Bool {
        return !fullName.trimmingCharacters(in: .whitespaces).isEmpty &&
               !universityName.trimmingCharacters(in: .whitespaces).isEmpty &&
               !majorFieldOfStudy.trimmingCharacters(in: .whitespaces).isEmpty &&
               !yearOfStudy.isEmpty
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.black.opacity(0.4))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.white.opacity(0.3), lineWidth: 1)
            )
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
}
