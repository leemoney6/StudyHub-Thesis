import SwiftUI
import Firebase
import GoogleSignIn

// MARK: - App Delegate for proper Firebase setup
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Configure Firebase
        FirebaseApp.configure()
        
        // Configure Google Sign In
        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let clientId = plist["CLIENT_ID"] as? String {
            
            let config = GIDConfiguration(clientID: clientId)
            GIDSignIn.sharedInstance.configuration = config
            print("✅ Google Sign In configured successfully")
        } else {
            print("⚠️ GoogleService-Info.plist not found or CLIENT_ID missing")
        }
        
        return true
    }
    
    // Handle URL schemes for Google Sign In
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}

@main
struct StudyHubApp: App {
    // Register app delegate for Firebase
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.needsProfileCompletion {
                    // Show profile completion for Google users with incomplete profiles
                    ProfileCompletionView()
                        .environmentObject(authViewModel)
                } else if authViewModel.isAuthenticated {
                    // Show main app after complete login
                    ContentView()
                        .environmentObject(authViewModel)
                } else {
                    // Show login/signup screen
                    AuthenticationView()
                        .environmentObject(authViewModel)
                }
            }
            .onOpenURL { url in
                // Handle Google Sign In URL (backup)
                GIDSignIn.sharedInstance.handle(url)
            }
        }
    }
}
