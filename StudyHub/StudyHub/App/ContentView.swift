import SwiftUI

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                MainAppView()
                    .environmentObject(authViewModel)
            } else {
                AuthenticationView()
                    .environmentObject(authViewModel)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: authViewModel.isAuthenticated)
    }
}

#Preview {
    ContentView()
}
