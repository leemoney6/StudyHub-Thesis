import SwiftUI
import WebKit


struct GIFView: UIViewRepresentable {
    let gifName: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.backgroundColor = UIColor.clear
        webView.isOpaque = false
        webView.scrollView.isScrollEnabled = false
        
        if let path = Bundle.main.path(forResource: gifName, ofType: "gif"),
           let data = NSData(contentsOfFile: path) {
            webView.load(data as Data, mimeType: "image/gif", characterEncodingName: "UTF-8", baseURL: URL(fileURLWithPath: path))
        }
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}


struct AuthenticationView: View {
    @State private var showingForgotPassword = false
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var isSignUpMode = false
    @State private var showingImagePicker = false
    @State private var showingActionSheet = false
    
    let yearOptions = ["1st Year", "2nd Year", "3rd Year", "4th Year", "Graduate", "PhD"]
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack {
                    Spacer(minLength: max(60, (geometry.size.height - cardHeight) / 2))
                    
                    VStack(spacing: 20) {
                        // Enhanced app branding
                        appBrandingSection
                        
                        // Main authentication card
                        VStack(alignment: .leading, spacing: 18) {
                            if isSignUpMode {
                                signUpForm
                            } else {
                                loginForm
                            }
                            
                            if !viewModel.errorMessage.isEmpty {
                                errorMessageView
                            }
                            
                            primaryActionButton
                        }
                        
                        if !isSignUpMode {
                            socialLoginSection
                        }
                        
                        modeToggleSection
                    }
                    .animation(.easeInOut(duration: 0.4), value: isSignUpMode)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 32)
                    .background {
                        // Lighter glassmorphic background
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.white.opacity(0.08))
                            .background {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.ultraThinMaterial.opacity(0.9))
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(
                                        LinearGradient(
                                            colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            }
                    }
                    .shadow(color: .black.opacity(0.15), radius: 30, x: 0, y: 10)
                    .padding(.horizontal, 24)
                    
                    Spacer(minLength: 60)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .preferredColorScheme(.dark)
        .background {
            enhancedBackground
        }
        .alert("Notice", isPresented: $viewModel.showErrorAlert) {
            Button("Got it") { viewModel.showErrorAlert = false }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
    
    private var cardHeight: CGFloat {
        return isSignUpMode ? 900 : 500
    }
}

// MARK: - Enhanced Components
private extension AuthenticationView {
    
    var appBrandingSection: some View {
        VStack(spacing: 16) {
            // Modern app icon
            ZStack {
                // Outer glow effect
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.3), .purple.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .blur(radius: 20)
                
                // Main icon background
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.8), .purple.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .overlay {
                        Circle()
                            .stroke(.white.opacity(0.2), lineWidth: 2)
                    }
                
                // Icon content
                GIFView(gifName: "studyhub-brain-icon")
                    .frame(width: 70,height: 70)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.3),radius: 4, x:0, y: 2)
            }
            
            
            VStack(spacing: 8) {
                Text("StudyHub")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                
                Text("Focus. Learn. Achieve.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .tracking(1)
            }
        }
        .padding(.bottom, 8)
    }
    
    var loginForm: some View {
        VStack(spacing: 16) {
            CustomTextField(placeholder: "Email", text: $viewModel.email)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
            
            CustomSecureTextField(placeholder: "Password", text: $viewModel.password)
            HStack {
                Spacer()
                Button("Forgot Password?") {
                    showingForgotPassword = true
                }
                .font(.caption)
                .foregroundColor(.cyan)
                .fontWeight(.medium)
            }.sheet(isPresented: $showingForgotPassword) {
                ForgotPasswordView()
                    .environmentObject(viewModel)
            }.alert("Password Reset", isPresented: $viewModel.showResetAlert) {
                Button("OK") {
                    viewModel.showResetAlert = false
                    if viewModel.resetEmailSent {
                        showingForgotPassword = false
                    }
                }
            } message: {
                Text(viewModel.resetMessage)
            }
        }
        
    }
    
    var signUpForm: some View {
        VStack(spacing: 16) {
            profilePictureSection
            
            CustomTextField(placeholder: "Full Name", text: $viewModel.fullName)
                .textInputAutocapitalization(.words)
            
            CustomTextField(placeholder: "Email", text: $viewModel.email)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
            
            CustomSecureTextField(placeholder: "Password", text: $viewModel.password)
            CustomSecureTextField(placeholder: "Confirm Password", text: $viewModel.confirmPassword)
            
            academicInfoSection
            studyPreferencesSection
        }
    }
    
    var profilePictureSection: some View {
        VStack(spacing: 10) {
            Button {
                showingActionSheet = true
            } label: {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.1))
                        .frame(width: 70, height: 70)
                        .overlay {
                            Circle()
                                .stroke(.white.opacity(0.3), lineWidth: 1.5)
                        }
                    
                    if let profileImage = viewModel.profileImage {
                        Image(uiImage: profileImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 66, height: 66)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            
            Text("Add Photo")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    var academicInfoSection: some View {
        VStack(spacing: 16) {
            CustomTextField(placeholder: "University/School", text: $viewModel.universityName)
                .textInputAutocapitalization(.words)
            
            CustomTextField(placeholder: "Major/Field of Study", text: $viewModel.majorFieldOfStudy)
                .textInputAutocapitalization(.words)
            
            Menu {
                ForEach(yearOptions, id: \.self) { year in
                    Button(year) {
                        viewModel.yearOfStudy = year
                    }
                }
            } label: {
                HStack {
                    Text(viewModel.yearOfStudy.isEmpty ? "Year of Study" : viewModel.yearOfStudy)
                        .foregroundColor(viewModel.yearOfStudy.isEmpty ? .white.opacity(0.6) : .white)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.caption)
                }
                .font(.system(size: 15))
                .padding(EdgeInsets(top: 15, leading: 10, bottom: 15, trailing: 10))
                .background {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(.white.opacity(0.3), lineWidth: 1)
                }
            }
        }
    }
    
    var studyPreferencesSection: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Study: \(viewModel.preferredStudyDuration) min")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                Slider(value: Binding(
                    get: { Double(viewModel.preferredStudyDuration) },
                    set: { viewModel.preferredStudyDuration = Int($0) }
                ), in: 15...60, step: 5)
                .accentColor(.blue.opacity(0.8))
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Break: \(viewModel.preferredBreakDuration) min")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                Slider(value: Binding(
                    get: { Double(viewModel.preferredBreakDuration) },
                    set: { viewModel.preferredBreakDuration = Int($0) }
                ), in: 5...20, step: 5)
                .accentColor(.green.opacity(0.8))
            }
            
            Toggle("Notifications", isOn: $viewModel.notificationsEnabled)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .toggleStyle(SwitchToggleStyle(tint: .blue.opacity(0.8)))
        }
    }
    
    var errorMessageView: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(.orange)
                .font(.caption)
            Text(viewModel.errorMessage)
                .font(.caption)
                .foregroundColor(.orange.opacity(0.9))
        }
        .padding(.horizontal, 4)
    }
    
    var primaryActionButton: some View {
        Button {
            Task {
                if isSignUpMode {
                    await viewModel.signUp()
                } else {
                    await viewModel.signIn()
                }
            }
        } label: {
            HStack(spacing: 10) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                }
                Text(isSignUpMode ? "Create Account" : "Log In")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [.blue.opacity(0.9), .purple.opacity(0.7)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(isSignUpMode ? !viewModel.canSignUp : !viewModel.canSubmit)
        .opacity((isSignUpMode ? viewModel.canSignUp : viewModel.canSubmit) ? 1.0 : 0.7)
        .animation(.easeInOut(duration: 0.2), value: isSignUpMode ? viewModel.canSignUp : viewModel.canSubmit)
        .padding(.top, 8)
    }
    
    var socialLoginSection: some View {
        VStack(spacing: 12) {
            HStack {
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.white.opacity(0.25))
                
                Text("or")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 12)
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.white.opacity(0.25))
            }
            .padding(.vertical, 8)
            
            HStack() {
                socialButton("Gmail", icon: "envelope.fill", colors: [.orange.opacity(0.8), .red.opacity(0.6)]) {
                    Task { await viewModel.socialLogin(provider: .google) }
                }
                
                
            }
        }
    }
    
    func socialButton(_ title: String, icon: String, colors: [Color], action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 14, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                        .opacity(0.3)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                }
                .cornerRadius(10)
        }
        .foregroundColor(.white.opacity(0.9))
    }
    
    var modeToggleSection: some View {
        HStack(spacing: 6) {
            Text(isSignUpMode ? "Already have an account?" : "Don't have an account?")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.7))
            
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isSignUpMode.toggle()
                    viewModel.clearFormForModeSwitch()
                }
            } label: {
                Text(isSignUpMode ? "Log In" : "Sign Up")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.blue.opacity(0.9))
            }
        }
    }
    
    var enhancedBackground: some View {
        ZStack {
            // Lighter, more subtle gradient
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
            
            // Softer floating shapes
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
    AuthenticationView()
        .environmentObject(AuthViewModel())
}
