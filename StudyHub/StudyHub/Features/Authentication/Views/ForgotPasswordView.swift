import SwiftUI

struct ForgotPasswordView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
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
            
            VStack(spacing: 24) {
             
                VStack(spacing: 8) {
                    Text("Reset Password")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("Enter the email you used for your StudyHub account and we’ll send you a reset link.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                 
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    HStack {
                        Image(systemName: "envelope")
                            .foregroundColor(.white.opacity(0.6))
                        
                        TextField("name@example.com", text: $viewModel.resetEmail)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.black.opacity(0.35))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
           
                VStack(spacing: 12) {
                    // Send reset link
                    Button {
                        Task {
                            await viewModel.sendPasswordReset()
                        }
                    } label: {
                        HStack {
                            if viewModel.isResettingPassword {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "paperplane.fill")
                            }
                            
                            Text(viewModel.isResettingPassword ? "Sending..." : "Send reset link")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.cyan.opacity(viewModel.canSendReset ? 1.0 : 0.5))
                        )
                        .foregroundColor(.white)
                    }
                    .disabled(!viewModel.canSendReset || viewModel.isResettingPassword)
                    
                    // Cancel
                    Button {
                        viewModel.clearResetForm()
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.85))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.white.opacity(0.06))
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(.ultraThinMaterial.opacity(0.9))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(.white.opacity(0.18), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 24)
        }
        .onAppear {
            // Pre-fill with login email if the user typed it already
            if viewModel.resetEmail.isEmpty {
                viewModel.resetEmail = viewModel.email
            }
        }
    }
}

 
