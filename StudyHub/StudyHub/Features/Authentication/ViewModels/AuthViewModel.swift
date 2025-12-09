import SwiftUI
import Combine
import Foundation
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import Firebase

@MainActor
class AuthViewModel: ObservableObject {
    // MARK: - Authentication State (SAME AS BEFORE)
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showErrorAlert = false
    @Published var currentUser: User?
    @Published var userProfile: UserProfile?
    
    // MARK: - Profile Completion State (NEW)
    @Published var needsProfileCompletion = false
    
    // MARK: - Login Fields (SAME AS BEFORE)
    @Published var email = ""
    @Published var password = ""
    
    // MARK: - Signup Fields (SAME AS BEFORE)
    @Published var confirmPassword = ""
    @Published var fullName = ""
    @Published var profileImage: UIImage?
    
    // MARK: - Password Reset Fields ← NEW 🔑
    @Published var resetEmail = ""
    @Published var isResettingPassword = false
    @Published var resetEmailSent = false
    @Published var resetMessage = ""
    @Published var showResetAlert = false
    
    // MARK: - Academic Information (SAME AS BEFORE)
    @Published var universityName = ""
    @Published var majorFieldOfStudy = ""
    @Published var yearOfStudy = ""
    
    // MARK: - Study Preferences (SAME AS BEFORE)
    @Published var preferredStudyDuration = 25 // minutes
    @Published var preferredBreakDuration = 5 // minutes
    @Published var notificationsEnabled = true
    @Published var reminderNotifications = true
    @Published var achievementNotifications = true
    
    // MARK: - Firebase Instances
    private let auth = Auth.auth()
    private let firestore = Firestore.firestore()
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    init() {
        setupAuthStateListener()
    }
    
    deinit {
        if let listener = authStateListener {
            auth.removeStateDidChangeListener(listener)
        }
    }
    
    // MARK: - Firebase Auth State Listener (UPDATED)
    private func setupAuthStateListener() {
        authStateListener = auth.addStateDidChangeListener { [weak self] _, user in
            Task {
                await MainActor.run {
                    self?.currentUser = user
                    
                    if let user = user {
                        Task {
                            await self?.loadUserProfile(uid: user.uid)
                        }
                    } else {
                        self?.userProfile = nil
                        self?.isAuthenticated = false
                        self?.needsProfileCompletion = false
                    }
                }
            }
        }
    }
    
    // MARK: - Profile Completion Check (NEW)
    private func checkProfileCompletion(_ profile: UserProfile) {
        let isProfileIncomplete = profile.universityName.isEmpty ||
                                 profile.majorFieldOfStudy.isEmpty ||
                                 profile.yearOfStudy.isEmpty
        print("🔍 Debug - Profile check:")
        print("  - needsProfileCompletion: \(needsProfileCompletion)")
        print("  - isAuthenticated: \(isAuthenticated)")
        print("  - University: '\(profile.universityName)'")
        print("  - Major: '\(profile.majorFieldOfStudy)'")
        print("  - Year: '\(profile.yearOfStudy)'")
        if isProfileIncomplete {
            needsProfileCompletion = true
            isAuthenticated = false // Don't show main app until profile is complete
        } else {
            needsProfileCompletion = false
            isAuthenticated = true
        }
    }
    
    func completeProfile(universityName: String, majorFieldOfStudy: String, yearOfStudy: String) async {
        guard let currentUser = currentUser,
              var userProfile = userProfile else {
            handleError("Unable to update profile. Please try again.")
            return
        }
        
        userProfile.universityName = universityName
        userProfile.majorFieldOfStudy = majorFieldOfStudy
        userProfile.yearOfStudy = yearOfStudy
        
        do {
            try await saveUserProfile(userProfile)
            await MainActor.run {
                self.needsProfileCompletion = false
                self.isAuthenticated = true
            }
        } catch {
            await MainActor.run {
                self.handleError("Failed to complete profile: \(error.localizedDescription)")
            }
        }
    }
    
    
    func sendPasswordReset() async {
        guard !resetEmail.isEmpty else {
            handleResetError("Please enter your email address")
            return
        }
        
        guard isEmailValid(resetEmail) else {
            handleResetError("Please enter a valid email address")
            return
        }
        
        isResettingPassword = true
        clearResetError()
        
        do {
             
            try await auth.sendPasswordReset(withEmail: resetEmail)
            
            await MainActor.run {
                self.isResettingPassword = false
                self.resetEmailSent = true
                self.resetMessage = "Password reset email sent to \(self.resetEmail). Check your inbox and follow the instructions to reset your password."
                self.showResetAlert = true
                print("✅ Password reset email sent to: \(self.resetEmail)")
            }
            
        } catch {
            await MainActor.run {
                self.isResettingPassword = false
                self.handleResetAuthError(error)
            }
        }
    }
    
    private func handleResetAuthError(_ error: Error) {
        let message: String
        
        if let authError = error as? AuthErrorCode {
            switch authError.code {
            case .invalidEmail:
                message = "Please enter a valid email address"
            case .userNotFound:
                message = "No account found with this email address"
            case .networkError:
                message = "Network error. Please check your internet connection"
            case .tooManyRequests:
                message = "Too many requests. Please try again later"
            default:
                message = "Failed to send reset email: \(error.localizedDescription)"
            }
        } else {
            message = "An unexpected error occurred: \(error.localizedDescription)"
        }
        
        handleResetError(message)
    }
    
    private func handleResetError(_ message: String) {
        resetMessage = message
        showResetAlert = true
        print("❌ Password reset error: \(message)")
    }
    
    private func clearResetError() {
        resetMessage = ""
        showResetAlert = false
        resetEmailSent = false
    }
    
    func clearResetForm() {
        resetEmail = ""
        resetEmailSent = false
        isResettingPassword = false
        clearResetError()
    }
    
    // ← NEW: Validation helper for reset email
    private func isEmailValid(_ email: String) -> Bool {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    // ← NEW: Computed property for reset button state
    var canSendReset: Bool {
        return !resetEmail.isEmpty && !isResettingPassword && isEmailValid(resetEmail)
    }
    
    // MARK: - Validation Properties (SAME AS BEFORE)
    private var isEmailValid: Bool {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private var isPasswordValid: Bool {
        return password.count >= 6
    }
    
    private var doPasswordsMatch: Bool {
        return password == confirmPassword
    }
    
    private var isSignupFormValid: Bool {
        return !fullName.isEmpty &&
               isEmailValid &&
               isPasswordValid &&
               doPasswordsMatch &&
               !universityName.isEmpty &&
               !majorFieldOfStudy.isEmpty &&
               !yearOfStudy.isEmpty
    }
    
    var canSubmit: Bool {
        return isEmailValid && isPasswordValid && !isLoading
    }
    
    var canSignUp: Bool {
        return isSignupFormValid && !isLoading
    }
    
    // MARK: - Authentication Methods (SAME AS BEFORE)
    func signIn() async {
        guard validateLoginInputs() else { return }
        
        isLoading = true
        clearError()
        
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            await MainActor.run {
                self.isLoading = false
                print("✅ Sign in successful: \(result.user.email ?? "No email")")
            }
        } catch {
            await MainActor.run {
                self.handleAuthError(error)
            }
        }
    }
    
    func signUp() async {
        guard validateSignupInputs() else { return }
        
        isLoading = true
        clearError()
        
        do {
            // 1. Create Firebase Auth user
            let result = try await auth.createUser(withEmail: email, password: password)
            let user = result.user
            
            // 2. Update display name
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = fullName
            try await changeRequest.commitChanges()
            
            // 3. Create user profile in Firestore
            let userProfile = UserProfile(
                uid: user.uid,
                fullName: fullName,
                email: email,
                universityName: universityName,
                majorFieldOfStudy: majorFieldOfStudy,
                yearOfStudy: yearOfStudy,
                preferredStudyDuration: preferredStudyDuration,
                preferredBreakDuration: preferredBreakDuration,
                notificationsEnabled: notificationsEnabled,
                reminderNotifications: reminderNotifications,
                achievementNotifications: achievementNotifications
            )
            
            try await saveUserProfile(userProfile)
            
            await MainActor.run {
                self.isLoading = false
                print("✅ Sign up successful: \(user.email ?? "No email")")
            }
            
        } catch {
            await MainActor.run {
                self.handleAuthError(error)
            }
        }
    }
    
    func socialLogin(provider: SocialLoginProvider) async {
        isLoading = true
        clearError()
        
        do {
            switch provider {
            case .google:
                try await signInWithGoogle()
            case .apple:
                // Apple Sign In temporarily disabled
                throw AuthError.appleSignInNotImplemented
            }
            
            await MainActor.run {
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.handleAuthError(error)
            }
        }
    }
    
    // MARK: - Google Sign In (SAME AS BEFORE)
    private func signInWithGoogle() async throws {
        guard let presentingViewController = await getRootViewController() else {
            throw AuthError.googleSignInFailed
        }
        
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AuthError.googleSignInFailed
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
        
        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.googleSignInFailed
        }
        
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )
        
        let authResult = try await auth.signIn(with: credential)
        
        // Check if this is a new user and create profile if needed
        if authResult.additionalUserInfo?.isNewUser == true {
            try await createSocialUserProfile(user: authResult.user)
        }
    }
    
    private func createSocialUserProfile(user: User) async throws {
        let userProfile = UserProfile(
            uid: user.uid,
            fullName: user.displayName ?? "User",
            email: user.email ?? "",
            universityName: "", // EMPTY - will trigger profile completion
            majorFieldOfStudy: "", // EMPTY - will trigger profile completion
            yearOfStudy: "", // EMPTY - will trigger profile completion
            preferredStudyDuration: 25,
            preferredBreakDuration: 5,
            notificationsEnabled: true,
            reminderNotifications: true,
            achievementNotifications: true
        )
        
        try await saveUserProfile(userProfile)
    }
    
    func signOut() {
        do {
            try auth.signOut()
            clearAllFields()
        } catch {
            handleError("Failed to sign out: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Firestore Operations (UPDATED)
    private func saveUserProfile(_ profile: UserProfile) async throws {
        let data = try Firestore.Encoder().encode(profile)
        try await firestore.collection("users").document(profile.id).setData(data)
        
        await MainActor.run {
            self.userProfile = profile
            self.checkProfileCompletion(profile) // NEW: Check if profile needs completion
        }
    }
    
    private func loadUserProfile(uid: String) async {
        do {
            let document = try await firestore.collection("users").document(uid).getDocument()
            
            if document.exists {
                let profile = try document.data(as: UserProfile.self)
                await MainActor.run {
                    self.userProfile = profile
                    self.checkProfileCompletion(profile) // NEW: Check if profile needs completion
                }
            } else {
                print("⚠️ User profile not found for UID: \(uid)")
                await MainActor.run {
                    self.isAuthenticated = false
                }
            }
        } catch {
            print("❌ Error loading user profile: \(error)")
            await MainActor.run {
                self.isAuthenticated = false
            }
        }
    }
    
    // MARK: - Validation Methods (SAME AS BEFORE)
    private func validateLoginInputs() -> Bool {
        if email.isEmpty || password.isEmpty {
            handleError("Please fill in all fields")
            return false
        }
        
        if !isEmailValid {
            handleError("Please enter a valid email address")
            return false
        }
        
        if !isPasswordValid {
            handleError("Password must be at least 6 characters")
            return false
        }
        
        return true
    }
    
    private func validateSignupInputs() -> Bool {
        if fullName.isEmpty {
            handleError("Please enter your full name")
            return false
        }
        
        if email.isEmpty || password.isEmpty || confirmPassword.isEmpty {
            handleError("Please fill in all required fields")
            return false
        }
        
        if !isEmailValid {
            handleError("Please enter a valid email address")
            return false
        }
        
        if !isPasswordValid {
            handleError("Password must be at least 6 characters")
            return false
        }
        
        if !doPasswordsMatch {
            handleError("Passwords do not match")
            return false
        }
        
        if universityName.isEmpty {
            handleError("Please enter your university/school name")
            return false
        }
        
        if majorFieldOfStudy.isEmpty {
            handleError("Please enter your major/field of study")
            return false
        }
        
        if yearOfStudy.isEmpty {
            handleError("Please select your year of study")
            return false
        }
        
        return true
    }
    
    // MARK: - Error Handling (SAME AS BEFORE)
    private func handleAuthError(_ error: Error) {
        let message: String
        
        if let authError = error as? AuthErrorCode {
            switch authError.code {
            case .emailAlreadyInUse:
                message = "An account with this email already exists"
            case .invalidEmail:
                message = "Please enter a valid email address"
            case .weakPassword:
                message = "Password is too weak. Please choose a stronger password"
            case .userNotFound:
                message = "No account found with this email address"
            case .wrongPassword:
                message = "Incorrect password. Please try again"
            case .networkError:
                message = "Network error. Please check your internet connection"
            case .tooManyRequests:
                message = "Too many failed attempts. Please try again later"
            default:
                message = "Authentication error: \(error.localizedDescription)"
            }
        } else {
            message = "An unexpected error occurred: \(error.localizedDescription)"
        }
        
        handleError(message)
    }
    
    private func handleError(_ message: String) {
        errorMessage = message
        showErrorAlert = true
        isLoading = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.clearError()
        }
    }
    
    private func clearError() {
        errorMessage = ""
        showErrorAlert = false
    }
    
    private func clearAllFields() {
        // Login fields
        email = ""
        password = ""
        
        // Signup fields
        confirmPassword = ""
        fullName = ""
        profileImage = nil
        
        // Academic info
        universityName = ""
        majorFieldOfStudy = ""
        yearOfStudy = ""
        
        // Reset states
        needsProfileCompletion = false
        
        // ← NEW: Clear reset fields too
        clearResetForm()
        
        clearError()
    }
    
    func clearFormForModeSwitch() {
        email = ""
        password = ""
        confirmPassword = ""
        clearError()
    }
    
    // MARK: - Helper Functions (SAME AS BEFORE)
    @MainActor
    private func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }
        return window.rootViewController
    }
}

// MARK: - Supporting Types (SAME AS BEFORE)
enum AuthenticationType {
    case signIn
    case signUp
}

enum SocialLoginProvider: String, CaseIterable {
    case google = "Google"
    case apple = "Apple"
    
    var systemImage: String {
        switch self {
        case .google: return "envelope.fill"
        case .apple: return "applelogo"
        }
    }
}

// MARK: - Auth Errors (SAME AS BEFORE)
enum AuthError: Error {
    case googleSignInFailed
    case appleSignInNotImplemented
    case profileCreationFailed
    
    var localizedDescription: String {
        switch self {
        case .googleSignInFailed:
            return "Google sign in failed"
        case .appleSignInNotImplemented:
            return "Apple sign in is not yet implemented"
        case .profileCreationFailed:
            return "Failed to create user profile"
        }
    }
}
