import SwiftUI
import Firebase
import GoogleSignIn

@main
struct StudyHubApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    init() {
        // Configure Firebase
        FirebaseApp.configure()
        
        // Configure Google Sign In
        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let clientId = plist["CLIENT_ID"] as? String {
            
            let config = GIDConfiguration(clientID: clientId)
            GIDSignIn.sharedInstance.configuration = config
        } else {
            print("⚠️ GoogleService-Info.plist not found or CLIENT_ID missing")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
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
            .onOpenURL { url in
                // Handle Google Sign In URL
                GIDSignIn.sharedInstance.handle(url)
            }
        }
    }
}
