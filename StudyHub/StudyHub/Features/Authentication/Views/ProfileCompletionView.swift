import SwiftUI

struct ProfileCompletionView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var universityName = ""
    @State private var majorFieldOfStudy = ""
    @State private var yearOfStudy = ""
    @State private var isLoading = false
    
    let yearOptions = ["1st Year", "2nd Year", "3rd Year", "4th Year", "Graduate", "PhD"]
    
    var body: some View {
        ZStack {
            enhancedBackground
            
            ScrollView {
                VStack(spacing: 30) {
                    // Welcome Header
                    welcomeHeader
                    
                    // Completion Form
                    completionForm
                    
                    // Complete Profile Button
                    completeProfileButton
                    
                    Spacer(minLength: 50)
                }
                .padding(20)
            }
        }
        .navigationBarHidden(true)
    }
    
    private var welcomeHeader: some View {
        VStack(spacing: 20) {
            // App Icon
            ZStack {
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
                
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 12) {
                Text("Complete Your Profile")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Let's add your academic information to personalize your StudyHub experience")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
        }
    }
    
    private var completionForm: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Academic Information")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 16) {
                CustomTextField(placeholder: "University/School", text: $universityName)
                    .textInputAutocapitalization(.words)
                
                CustomTextField(placeholder: "Major/Field of Study", text: $majorFieldOfStudy)
                    .textInputAutocapitalization(.words)
                
                Menu {
                    ForEach(yearOptions, id: \.self) { year in
                        Button(year) {
                            yearOfStudy = year
                        }
                    }
                } label: {
                    HStack {
                        Text(yearOfStudy.isEmpty ? "Year of Study" : yearOfStudy)
                            .foregroundColor(yearOfStudy.isEmpty ? .white.opacity(0.6) : .white)
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
        .padding(24)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.08))
                .background {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial.opacity(0.9))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                }
        }
    }
    
    private var completeProfileButton: some View {
        Button {
            Task {
                await completeProfile()
            }
        } label: {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                }
                Text("Complete Profile")
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
        .disabled(universityName.isEmpty || majorFieldOfStudy.isEmpty || yearOfStudy.isEmpty || isLoading)
        .opacity((universityName.isEmpty || majorFieldOfStudy.isEmpty || yearOfStudy.isEmpty) ? 0.7 : 1.0)
        .padding(.horizontal, 20)
    }
    
    private func completeProfile() async {
        isLoading = true
        
        // Update the user profile with academic info
        await authViewModel.completeProfile(
            universityName: universityName,
            majorFieldOfStudy: majorFieldOfStudy,
            yearOfStudy: yearOfStudy
        )
        
        isLoading = false
    }
    
    private var enhancedBackground: some View {
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
        }
    }
}

#Preview {
    ProfileCompletionView()
        .environmentObject(AuthViewModel())
}
