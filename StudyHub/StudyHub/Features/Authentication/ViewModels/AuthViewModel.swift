import SwiftUI
import Combine
import Foundation
@MainActor
class AuthViewModel: ObservableObject {
    // MARK: - Authentication State
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showErrorAlert = false
    
    // MARK: - Login Fields
    @Published var email = ""
    @Published var password = ""
    
    // MARK: - Signup Fields
    @Published var confirmPassword = ""
    @Published var fullName = ""
    @Published var profileImage: UIImage?
    
    // MARK: - Academic Information
    @Published var universityName = ""
    @Published var majorFieldOfStudy = ""
    @Published var yearOfStudy = ""
    
    // MARK: - Study Preferences
    @Published var preferredStudyDuration = 25 // minutes
    @Published var preferredBreakDuration = 5 // minutes
    @Published var notificationsEnabled = true
    @Published var reminderNotifications = true
    @Published var achievementNotifications = true
    
    // MARK: - Validation Properties
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
    
    // MARK: - Authentication Methods
    func signIn() async {
        guard validateLoginInputs() else { return }
        
        await performAuthentication(.signIn)
    }
    
    func signUp() async {
        guard validateSignupInputs() else { return }
        
        await performAuthentication(.signUp)
    }
    
    func socialLogin(provider: SocialLoginProvider) async {
        isLoading = true
        clearError()
        
        do {
            try await Task.sleep(nanoseconds: 1_500_000_000)
            
            await MainActor.run {
                self.isAuthenticated = true
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.handleError("Social login failed. Please try again.")
            }
        }
    }
    
    func signOut() {
        isAuthenticated = false
        clearAllFields()
    }
    
    // MARK: - Validation Methods
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
    
    // MARK: - Helper Methods
    private func performAuthentication(_ type: AuthenticationType) async {
        isLoading = true
        clearError()
        
        do {
            try await Task.sleep(nanoseconds: 2_000_000_000)
            
            await MainActor.run {
                // TODO: Replace with actual authentication service
                self.isAuthenticated = true
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.handleError("Network error. Please check your connection.")
            }
        }
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
        
        clearError()
    }
    
    func clearFormForModeSwitch() {
        email = ""
        password = ""
        confirmPassword = ""
        clearError()
    }
}

// MARK: - Supporting Types
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
