import SwiftUI

@main
struct StudyHubApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                // Show main app after login
                ContentView()
                    .environmentObject(authViewModel)
            } else {
                // Show login/signup screen
                AuthenticationView()
                    .environmentObject(authViewModel)
            }
        }
    }
}
