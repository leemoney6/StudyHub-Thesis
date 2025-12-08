import SwiftUI
import Firebase

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var statsViewModel = UserStatsViewModel()
    @State private var showingEditProfile = false
    @State private var showingLogoutAlert = false
    
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
                        
                        // Statistics Section
                        statisticsSection
                        
                        // Account Management Section
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
                .environmentObject(authViewModel)  // ← Pass environment object to EditProfileView
        }
        .alert("Sign Out", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                authViewModel.signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .onAppear{
            if let uid = authViewModel.currentUser?.uid {
                        statsViewModel.startListening(userId: uid)
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
                // ← FIXED: Use real user data
                Text(authViewModel.userProfile?.fullName ?? "User")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    Image(systemName: "graduationcap.fill")
                        .foregroundColor(.cyan)
                        .font(.caption)
                    // ← FIXED: Use real major field
                    Text("\(authViewModel.userProfile?.majorFieldOfStudy ?? "Student") Student")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(darkCardBackground)
                .cornerRadius(12)
            }
        }
        .padding(24)
        .background(premiumCardBackground)
    }
    
    var userInfoSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "Personal Information", icon: "person.text.rectangle")
            
            VStack(spacing: 16) {
                // ← FIXED: Use real user data
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
    
    // ← FIXED: Calculate member since from real creation date
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
                // ← FIXED: Use real user preferences
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
                PreferenceRow(icon: "target", title: "Daily Goal", value: "6 sessions", color: .purple)
            }
        }
        .padding(24)
        .background(premiumCardBackground)
    }
    
    var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "Statistics", icon: "chart.bar.fill")
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
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
        }
        .padding(24)
        .background(premiumCardBackground)
    }
    var accountManagementSection: some View {
        VStack(spacing: 12) {
            // Settings Button
            ActionButton(
                icon: "gearshape.fill",
                title: "App Settings",
                color: .blue,
                action: { /* Settings action */ }
            )
            
            // Help & Support Button
            ActionButton(
                icon: "questionmark.circle.fill",
                title: "Help & Support",
                color: .green,
                action: { /* Help action */ }
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

// MARK: - Edit Profile View (FIXED WITH REAL DATA)
struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel  // ← FIXED: Use environment object
    
    // Form fields - loaded from real user data
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
                                    .disabled(true) // Email shouldn't be editable
                                    .opacity(0.7)
                                CustomTextField(placeholder: "University", text: $universityName)
                                CustomTextField(placeholder: "Major", text: $majorFieldOfStudy)
                                
                                // Year Picker
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
                                // Study Duration Slider
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
                                
                                // Break Duration Slider
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
                                
                                // Notifications Toggle
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
    
    // ← FIXED: Load real user data when view appears
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
    
    // ← FIXED: Actually save changes to Firebase
    private func saveProfile() async {
        guard var profile = authViewModel.userProfile else {
            errorMessage = "Unable to load profile data"
            showingError = true
            return
        }
        
        isLoading = true
        
        // Update profile with form data
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
            // Save to Firestore
            let firestore = Firestore.firestore()
            let data = try Firestore.Encoder().encode(profile)
            try await firestore.collection("users").document(profile.id).setData(data)
            
            await MainActor.run {
                // Update AuthViewModel's profile
                authViewModel.userProfile = profile
                isLoading = false
                dismiss() // Close edit view on success
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
