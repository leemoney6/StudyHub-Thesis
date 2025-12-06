import SwiftUI

struct MainAppView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab: AppTab = .dashboard
    
    enum AppTab: String, CaseIterable {
        case dashboard = "Dashboard"
        case tasks = "Tasks"
        case timer = "Focus"
        case groups = "Groups"
        case profile = "Profile"
        
        var icon: String {
            switch self {
            case .dashboard: return "house.fill"
            case .tasks: return "list.bullet.clipboard.fill"
            case .timer: return "timer"
            case .groups: return "person.2.fill"
            case .profile: return "person.circle.fill"
            }
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Image(systemName: AppTab.dashboard.icon)
                    Text(AppTab.dashboard.rawValue)
                }
                .tag(AppTab.dashboard)
            
            TasksView()
                .tabItem {
                    Image(systemName: AppTab.tasks.icon)
                    Text(AppTab.tasks.rawValue)
                }
                .tag(AppTab.tasks)
            
            PomodoroView()
                .tabItem {
                    Image(systemName: AppTab.timer.icon)
                    Text(AppTab.timer.rawValue)
                }
                .tag(AppTab.timer)
            
            GroupsView()  // ← TO DO: Need to decide what this should be
                .tabItem {
                    Image(systemName: AppTab.groups.icon)
                    Text(AppTab.groups.rawValue)
                }
                .tag(AppTab.groups)
            
            ProfileView()
                .tabItem {
                    Image(systemName: AppTab.profile.icon)
                    Text(AppTab.profile.rawValue)
                }
                .tag(AppTab.profile)
                .environmentObject(authViewModel)
        }
        .tint(.blue)
    }
}

#Preview {
    MainAppView()
        .environmentObject(AuthViewModel())
}
