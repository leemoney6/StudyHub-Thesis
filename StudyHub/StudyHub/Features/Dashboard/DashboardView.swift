import SwiftUI

struct DashboardView: View {
    @State private var currentTime = Date()
    @State private var breathingAnimation = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Same background as login
                enhancedBackground
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Welcome header with glassmorphic design
                        welcomeHeader
                        
                        // Today's progress cards
                        progressSection
                        
                        // Quick actions
                        quickActionsSection
                        
                        // Recent activity
                        recentActivitySection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
        }
        .onAppear {
            startTimeUpdates()
        }
    }
    
    private func startTimeUpdates() {
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            currentTime = Date()
        }
        breathingAnimation = true
    }
}

// MARK: - Dashboard Components
private extension DashboardView {
    
    var welcomeHeader: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(greeting)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("Ready to achieve your study goals?")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                // Animated brain icon (same as login)
                GIFView(gifName: "studyhub-brain-icon")
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    .scaleEffect(breathingAnimation ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(), value: breathingAnimation)
            }
            
            // Time display
            VStack(spacing: 4) {
                Text(currentTime, style: .time)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(currentTime, style: .date)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.08))
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial.opacity(0.8))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                }
        }
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: currentTime)
        switch hour {
        case 0..<12: return "Good morning! ☀️"
        case 12..<17: return "Good afternoon! 🌤️"
        case 17..<21: return "Good evening! 🌅"
        default: return "Good night! 🌙"
        }
    }
    
    var progressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Progress")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                progressCard("2h 30m", subtitle: "Study Time", icon: "clock.fill", color: .orange, progress: 0.75)
                progressCard("8/12", subtitle: "Tasks", icon: "checkmark.circle.fill", color: .green, progress: 0.67)
                progressCard("5", subtitle: "Sessions", icon: "timer", color: .blue, progress: 0.5)
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.08))
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial.opacity(0.8))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                }
        }
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    func progressCard(_ value: String, subtitle: String, icon: String, color: Color, progress: Double) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle())
                .tint(color)
                .frame(height: 4)
                .background(.white.opacity(0.2))
                .cornerRadius(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
    
    var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Start")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                actionButton("Start Focus Session", icon: "timer", gradient: [.orange, .red]) {}
                actionButton("Add New Task", icon: "plus.circle.fill", gradient: [.green, .mint]) {}
                actionButton("Join Study Group", icon: "person.2.fill", gradient: [.purple, .pink]) {}
                actionButton("View Statistics", icon: "chart.bar.fill", gradient: [.blue, .cyan]) {}
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.08))
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial.opacity(0.8))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                }
        }
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    func actionButton(_ title: String, icon: String, gradient: [Color], action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: gradient.map { $0.opacity(0.3) },
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.white.opacity(0.15), lineWidth: 1)
            }
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                activityRow("Completed Mathematics Session", time: "25 min", color: .green, timeAgo: "1h ago")
                activityRow("Added Physics Assignment", time: "Due Mon", color: .blue, timeAgo: "2h ago")
                activityRow("Joined Chemistry Group", time: "5 members", color: .purple, timeAgo: "3h ago")
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.08))
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial.opacity(0.8))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                }
        }
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    func activityRow(_ title: String, time: String, color: Color, timeAgo: String) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color.opacity(0.3))
                .frame(width: 8, height: 8)
                .overlay {
                    Circle()
                        .stroke(color, lineWidth: 2)
                }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(time)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Text(timeAgo)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.vertical, 6)
    }
    
    var enhancedBackground: some View {
        ZStack {
            // Same gradient as login
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
            
            // Same floating shapes as login
            subtleShapes
        }
    }
    
    var subtleShapes: some View {
        ZStack {
            Circle()
                .fill(.blue.opacity(0.15))
                .frame(width: 200, height: 200)
                .offset(x: -80, y: -150)
                .blur(radius: 60)
            
            Circle()
                .fill(.purple.opacity(0.12))
                .frame(width: 150, height: 150)
                .offset(x: 120, y: 200)
                .blur(radius: 50)
            
            Circle()
                .fill(.blue.opacity(0.08))
                .frame(width: 100, height: 100)
                .offset(x: -120, y: 150)
                .blur(radius: 40)
        }
    }
}

#Preview {
    DashboardView()
}
