import SwiftUI
import Firebase
import FirebaseAuth

struct AppSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // Password Change States
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmNewPassword = ""
    @State private var showingPasswordSection = false
    @State private var isChangingPassword = false
    @State private var passwordChangeMessage = ""
    @State private var showPasswordAlert = false
    
    // Settings States
    @State private var notificationsEnabled = true
    @State private var reminderNotifications = true
    @State private var achievementNotifications = true
    @State private var soundEnabled = true
    @State private var darkModeEnabled = true
    
    // Account Management
    @State private var showingDeleteAccount = false
    @State private var showingSignOutAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                enhancedBackground
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Account Section
                        accountSection
                        
                        // Password Section
                        passwordSection
                        
                        // Notification Settings
                        notificationSettingsSection
                        
                        // App Preferences
                        appPreferencesSection
                        
                        // Data & Privacy
                        dataPrivacySection
                        
                        // Danger Zone
                        dangerZoneSection
                        
                        Spacer(minLength: 50)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("App Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await saveSettings()
                        }
                    }
                    .foregroundColor(.cyan)
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            loadCurrentSettings()
        }
        .alert("Password Change", isPresented: $showPasswordAlert) {
            Button("OK") {
                passwordChangeMessage = ""
                if passwordChangeMessage.contains("successfully") {
                    clearPasswordFields()
                }
            }
        } message: {
            Text(passwordChangeMessage)
        }
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                authViewModel.signOut()
                dismiss()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Delete Account", isPresented: $showingDeleteAccount) {
            Button("Cancel", role: .cancel) { }
            Button("Delete Account", role: .destructive) {
                // TODO: Implement account deletion
                print("Delete account - requires re-authentication")
            }
        } message: {
            Text("This action cannot be undone. All your data will be permanently deleted.")
        }
    }
}

// MARK: - Settings Sections
private extension AppSettingsView {
    
    var accountSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "Account", icon: "person.circle")
            
            VStack(spacing: 16) {
                InfoDisplayRow(
                    icon: "envelope.fill",
                    title: "Email",
                    value: authViewModel.userProfile?.email ?? "No email",
                    color: .cyan
                )
                
                InfoDisplayRow(
                    icon: "person.fill",
                    title: "Full Name",
                    value: authViewModel.userProfile?.fullName ?? "No name",
                    color: .blue
                )
                
                InfoDisplayRow(
                    icon: "calendar",
                    title: "Member Since",
                    value: memberSinceText,
                    color: .green
                )
            }
        }
        .padding(24)
        .background(cardBackground)
    }
    
    var passwordSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingPasswordSection.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.orange)
                        .font(.title3)
                        .frame(width: 24)
                    
                    Text("Change Password")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: showingPasswordSection ? "chevron.up" : "chevron.down")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }
            
            if showingPasswordSection {
                VStack(spacing: 16) {
                    // Current Password
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Password")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        SecureField("Enter current password", text: $currentPassword)
                            .textFieldStyle(CustomSecureFieldStyle())
                    }
                    
                    // New Password
                    VStack(alignment: .leading, spacing: 8) {
                        Text("New Password")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        SecureField("Enter new password", text: $newPassword)
                            .textFieldStyle(CustomSecureFieldStyle())
                    }
                    
                    // Confirm New Password
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirm New Password")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        SecureField("Confirm new password", text: $confirmNewPassword)
                            .textFieldStyle(CustomSecureFieldStyle())
                    }
                    
                    // Password Requirements
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Password Requirements:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.8))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            PasswordRequirement(text: "At least 6 characters", isMet: newPassword.count >= 6)
                            PasswordRequirement(text: "Passwords match", isMet: !newPassword.isEmpty && newPassword == confirmNewPassword)
                        }
                    }
                    
                    // Change Password Button
                    Button {
                        Task {
                            await changePassword()
                        }
                    } label: {
                        HStack {
                            if isChangingPassword {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.9)
                            }
                            Text("Change Password")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(isPasswordValid ? .orange : .gray.opacity(0.5))
                        .cornerRadius(10)
                    }
                    .disabled(!isPasswordValid || isChangingPassword)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(24)
        .background(cardBackground)
    }
    
    var notificationSettingsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "Notifications", icon: "bell.fill")
            
            VStack(spacing: 16) {
                SettingsToggleRow(
                    icon: "bell",
                    title: "Push Notifications",
                    description: "Receive notifications about study sessions",
                    isOn: $notificationsEnabled,
                    color: .blue
                )
                
                Divider().background(.white.opacity(0.2))
                
                SettingsToggleRow(
                    icon: "clock",
                    title: "Study Reminders",
                    description: "Get reminded about scheduled study sessions",
                    isOn: $reminderNotifications,
                    color: .green
                )
                
                Divider().background(.white.opacity(0.2))
                
                SettingsToggleRow(
                    icon: "star.fill",
                    title: "Achievement Notifications",
                    description: "Celebrate your study milestones",
                    isOn: $achievementNotifications,
                    color: .yellow
                )
                
                Divider().background(.white.opacity(0.2))
                
                SettingsToggleRow(
                    icon: "speaker.wave.2",
                    title: "Sound Effects",
                    description: "Play sounds for timer and notifications",
                    isOn: $soundEnabled,
                    color: .purple
                )
            }
        }
        .padding(24)
        .background(cardBackground)
    }
    
    var appPreferencesSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "App Preferences", icon: "gearshape.fill")
            
            VStack(spacing: 16) {
                SettingsToggleRow(
                    icon: "moon.fill",
                    title: "Dark Mode",
                    description: "Use dark appearance",
                    isOn: $darkModeEnabled,
                    color: .indigo
                )
                
                Divider().background(.white.opacity(0.2))
                
                SettingsNavRow(
                    icon: "timer",
                    title: "Default Timer Settings",
                    description: "Customize focus and break durations",
                    color: .orange
                ) {
                    // Navigate to timer settings
                }
                
                Divider().background(.white.opacity(0.2))
                
                SettingsNavRow(
                    icon: "list.bullet",
                    title: "Task Preferences",
                    description: "Default priority, sorting, and display",
                    color: .cyan
                ) {
                    // Navigate to task settings
                }
            }
        }
        .padding(24)
        .background(cardBackground)
    }
    
    var dataPrivacySection: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "Data & Privacy", icon: "shield.fill")
            
            VStack(spacing: 16) {
                SettingsNavRow(
                    icon: "doc.text",
                    title: "Privacy Policy",
                    description: "Learn how we protect your data",
                    color: .blue
                ) {
                    // Open privacy policy
                }
                
                Divider().background(.white.opacity(0.2))
                
                SettingsNavRow(
                    icon: "doc.plaintext",
                    title: "Terms of Service",
                    description: "Read our terms and conditions",
                    color: .green
                ) {
                    // Open terms of service
                }
                
                Divider().background(.white.opacity(0.2))
                
                SettingsNavRow(
                    icon: "arrow.down.doc",
                    title: "Export Data",
                    description: "Download your study data",
                    color: .purple
                ) {
                    // Export user data
                }
            }
        }
        .padding(24)
        .background(cardBackground)
    }
    
    var dangerZoneSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "Account Management", icon: "exclamationmark.triangle.fill")
            
            VStack(spacing: 12) {
                Button {
                    showingSignOutAlert = true
                } label: {
                    HStack(spacing: 16) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.orange)
                            .font(.system(size: 16, weight: .semibold))
                        
                        Text("Sign Out")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.caption)
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.black.opacity(0.3))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.orange.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                Button {
                    showingDeleteAccount = true
                } label: {
                    HStack(spacing: 16) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .font(.system(size: 16, weight: .semibold))
                        
                        Text("Delete Account")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.caption)
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.black.opacity(0.3))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.red.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(24)
        .background(cardBackground)
    }
}

// MARK: - Helper Functions
private extension AppSettingsView {
    
    var memberSinceText: String {
        guard let createdDate = authViewModel.userProfile?.createdDate else {
            return "Recently"
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: createdDate)
    }
    
    var isPasswordValid: Bool {
        return !currentPassword.isEmpty &&
               newPassword.count >= 6 &&
               newPassword == confirmNewPassword &&
               currentPassword != newPassword
    }
    
    func loadCurrentSettings() {
        guard let profile = authViewModel.userProfile else { return }
        
        notificationsEnabled = profile.notificationsEnabled
        reminderNotifications = profile.reminderNotifications
        achievementNotifications = profile.achievementNotifications
    }
    
    func saveSettings() async {
        guard var profile = authViewModel.userProfile else {
            print("No user profile found")
            return
        }
        
        // Update notification settings
        profile.notificationsEnabled = notificationsEnabled
        profile.reminderNotifications = reminderNotifications
        profile.achievementNotifications = achievementNotifications
        
        do {
            let firestore = Firestore.firestore()
            let data = try Firestore.Encoder().encode(profile)
            try await firestore.collection("users").document(profile.id).setData(data)
            
            await MainActor.run {
                authViewModel.userProfile = profile
                print("✅ Settings saved successfully")
            }
        } catch {
            print("❌ Failed to save settings: \(error.localizedDescription)")
        }
    }
    
    func changePassword() async {
        guard isPasswordValid else {
            passwordChangeMessage = "Please check your password requirements"
            showPasswordAlert = true
            return
        }
        
        isChangingPassword = true
        
        do {
            // Re-authenticate user first
            guard let currentUser = Auth.auth().currentUser,
                  let email = currentUser.email else {
                passwordChangeMessage = "Unable to verify current user"
                showPasswordAlert = true
                isChangingPassword = false
                return
            }
            
            let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
            try await currentUser.reauthenticate(with: credential)
            
            // Now change password
            try await currentUser.updatePassword(to: newPassword)
            
            await MainActor.run {
                passwordChangeMessage = "Password changed successfully!"
                showPasswordAlert = true
                isChangingPassword = false
                print("✅ Password changed successfully")
            }
            
        } catch let error as NSError {
            await MainActor.run {
                isChangingPassword = false
                
                switch error.code {
                case AuthErrorCode.wrongPassword.rawValue:
                    passwordChangeMessage = "Current password is incorrect"
                case AuthErrorCode.weakPassword.rawValue:
                    passwordChangeMessage = "New password is too weak"
                case AuthErrorCode.networkError.rawValue:
                    passwordChangeMessage = "Network error. Please try again."
                default:
                    passwordChangeMessage = "Failed to change password: \(error.localizedDescription)"
                }
                showPasswordAlert = true
            }
        }
    }
    
    func clearPasswordFields() {
        currentPassword = ""
        newPassword = ""
        confirmNewPassword = ""
    }
    
    // MARK: - Background Components
    var cardBackground: some View {
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

// MARK: - Supporting Components
struct InfoDisplayRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 18, weight: .medium))
                .frame(width: 24)
            
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

struct SettingsToggleRow: View {
    let icon: String
    let title: String
    let description: String
    @Binding var isOn: Bool
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
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: color))
        }
    }
}

struct SettingsNavRow: View {
    let icon: String
    let title: String
    let description: String
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
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.6))
                    .font(.caption)
                    .fontWeight(.semibold)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PasswordRequirement: View {
    let text: String
    let isMet: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isMet ? .green : .white.opacity(0.5))
                .font(.caption)
            
            Text(text)
                .font(.caption)
                .foregroundColor(isMet ? .white : .white.opacity(0.7))
        }
    }
}

struct CustomSecureFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.black.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.white.opacity(0.3), lineWidth: 1)
                    )
            )
            .foregroundColor(.white)
    }
}

#Preview {
    AppSettingsView()
        .environmentObject(AuthViewModel())
}
