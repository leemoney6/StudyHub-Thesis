import SwiftUI

struct ProfileView: View {
    @StateObject private var authViewModel = AuthViewModel()
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
        }
        .alert("Sign Out", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                authViewModel.signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
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
                Text("Salah Ben Sarar")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    Image(systemName: "graduationcap.fill")
                        .foregroundColor(.cyan)
                        .font(.caption)
                    Text("Computer Science Student")
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
                InfoRow(icon: "envelope.fill", title: "Email", value: "leemoney6@gmail.com")
                Divider().background(.white.opacity(0.2))
                InfoRow(icon: "building.2.fill", title: "University", value: "John von Neumann University")
                Divider().background(.white.opacity(0.2))
                InfoRow(icon: "book.fill", title: "Major", value: "Computer Science")
                Divider().background(.white.opacity(0.2))
                InfoRow(icon: "graduationcap.fill", title: "Year", value: "Final Year")
                Divider().background(.white.opacity(0.2))
                InfoRow(icon: "calendar", title: "Member Since", value: "November 2025")
            }
        }
        .padding(24)
        .background(premiumCardBackground)
    }
    
    var studyPreferencesSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "Study Preferences", icon: "slider.horizontal.3")
            
            VStack(spacing: 16) {
                PreferenceRow(icon: "timer", title: "Default Session", value: "25 minutes", color: .orange)
                Divider().background(.white.opacity(0.2))
                PreferenceRow(icon: "pause.circle.fill", title: "Break Duration", value: "5 minutes", color: .green)
                Divider().background(.white.opacity(0.2))
                PreferenceRow(icon: "bell.fill", title: "Notifications", value: "Enabled", color: .blue)
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
                StatCard(title: "Tasks Completed", value: "47", icon: "checkmark.circle.fill", color: .green)
                StatCard(title: "Study Sessions", value: "23", icon: "clock.fill", color: .cyan)
                StatCard(title: "Total Hours", value: "12.5", icon: "hourglass", color: .orange)
                StatCard(title: "Streak", value: "7 days", icon: "flame.fill", color: .red)
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

// MARK: - Enhanced Components
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

// MARK: - Edit Profile View
struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var fullName = "Salah Ben Sarar"
    @State private var email = "leemoney6@gmail.com"
    @State private var university = "John von Neumann University"
    @State private var major = "Computer Science"
    @State private var year = "Final Year"
    @State private var sessionDuration = 25
    @State private var breakDuration = 5
    @State private var dailyGoal = 6
    @State private var notificationsEnabled = true
    
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
                                CustomTextField(placeholder: "University", text: $university)
                                CustomTextField(placeholder: "Major", text: $major)
                                CustomTextField(placeholder: "Year", text: $year)
                            }
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.black.opacity(0.4))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                        
                        // Study Preferences
                        VStack(alignment: .leading, spacing: 20) {
                            SectionHeader(title: "Study Preferences", icon: "slider.horizontal.3")
                            
                            VStack(spacing: 20) {
                                EditPreferenceRow(
                                    title: "Session Duration",
                                    selection: $sessionDuration,
                                    options: [15: "15 min", 25: "25 min", 30: "30 min", 45: "45 min"]
                                )
                                
                                EditPreferenceRow(
                                    title: "Break Duration",
                                    selection: $breakDuration,
                                    options: [5: "5 min", 10: "10 min", 15: "15 min"]
                                )
                                
                                EditPreferenceRow(
                                    title: "Daily Goal",
                                    selection: $dailyGoal,
                                    options: Dictionary(uniqueKeysWithValues: (1...10).map { ($0, "\($0) sessions") })
                                )
                                
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
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.black.opacity(0.4))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                        
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
                        dismiss()
                    }
                    .foregroundColor(.cyan)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

struct EditPreferenceRow: View {
    let title: String
    @Binding var selection: Int
    let options: [Int: String]
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.white)
                .fontWeight(.semibold)
            
            Spacer()
            
            Picker(title, selection: $selection) {
                ForEach(options.keys.sorted(), id: \.self) { key in
                    Text(options[key] ?? "").tag(key)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .accentColor(.cyan)
        }
    }
}

#Preview {
    ProfileView()
}
