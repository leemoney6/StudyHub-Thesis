import SwiftUI
import MessageUI

struct HelpSupportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingMailComposer = false
    @State private var showingPhoneAlert = false
    @State private var selectedFAQItem: FAQItem?
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                enhancedBackground
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Contact Section
                        contactSection
                        
                        // FAQ Section
                        faqSection
                        
                        // Support Options
                        supportOptionsSection
                        
                        // App Information
                        appInformationSection
                        
                        Spacer(minLength: 50)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Help & Support")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search for help...")
        .sheet(isPresented: $showingMailComposer) {
            MailComposeView()
        }
        .alert("Call Support", isPresented: $showingPhoneAlert) {
            Button("Call Now") {
                makePhoneCall()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will open your phone app to call StudyHub support at +1 (555) 123-STUDY")
        }
        .sheet(item: $selectedFAQItem) { faqItem in
            FAQDetailView(faqItem: faqItem)
        }
    }
}

// MARK: - Help Sections
private extension HelpSupportView {
    
    var contactSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "Contact Us", icon: "phone.fill")
            
            VStack(spacing: 16) {
                // Phone Contact
                ContactRow(
                    icon: "phone.fill",
                    title: "Phone Support",
                    subtitle: "+1 (555) 123-STUDY",
                    description: "Call us Monday-Friday, 9 AM - 6 PM EST",
                    color: .green,
                    action: {
                        showingPhoneAlert = true
                    }
                )
                
                Divider().background(.white.opacity(0.2))
                
                // Email Contact
                ContactRow(
                    icon: "envelope.fill",
                    title: "Email Support",
                    subtitle: "support@studyhub.app",
                    description: "We'll respond within 24 hours",
                    color: .blue,
                    action: {
                        if MFMailComposeViewController.canSendMail() {
                            showingMailComposer = true
                        } else {
                            openEmailApp()
                        }
                    }
                )
                
                Divider().background(.white.opacity(0.2))
                
                // Live Chat (Future Feature)
                ContactRow(
                    icon: "message.fill",
                    title: "Live Chat",
                    subtitle: "Coming Soon",
                    description: "Real-time chat support",
                    color: .purple,
                    action: {
                        // Future live chat implementation
                    }
                )
            }
        }
        .padding(24)
        .background(cardBackground)
    }
    
    var faqSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "Frequently Asked Questions", icon: "questionmark.circle.fill")
            
            let filteredFAQs = searchText.isEmpty ? faqItems :
                faqItems.filter { $0.question.localizedCaseInsensitiveContains(searchText) ||
                                 $0.answer.localizedCaseInsensitiveContains(searchText) }
            
            if filteredFAQs.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.6))
                    
                    Text("No results found")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("Try adjusting your search terms")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(Array(filteredFAQs.prefix(5)), id: \.id) { faq in
                        FAQRowView(faqItem: faq) {
                            selectedFAQItem = faq
                        }
                    }
                    
                    if filteredFAQs.count > 5 {
                        Button("View All \(filteredFAQs.count) FAQs") {
                            // Show all FAQs
                        }
                        .foregroundColor(.cyan)
                        .fontWeight(.semibold)
                        .padding(.top, 8)
                    }
                }
            }
        }
        .padding(24)
        .background(cardBackground)
    }
    
    var supportOptionsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "Other Support Options", icon: "lifepreserver.fill")
            
            VStack(spacing: 12) {
                SupportOptionRow(
                    icon: "book.fill",
                    title: "User Guide",
                    description: "Complete guide to using StudyHub",
                    color: .orange
                ) {
                    // Open user guide
                }
                
                SupportOptionRow(
                    icon: "video.fill",
                    title: "Video Tutorials",
                    description: "Step-by-step video instructions",
                    color: .red
                ) {
                    // Open video tutorials
                }
                
                SupportOptionRow(
                    icon: "bubble.left.and.bubble.right.fill",
                    title: "Community Forum",
                    description: "Connect with other StudyHub users",
                    color: .purple
                ) {
                    // Open community forum
                }
                
                SupportOptionRow(
                    icon: "star.fill",
                    title: "Feature Requests",
                    description: "Suggest new features or improvements",
                    color: .yellow
                ) {
                    // Submit feature request
                }
                
                SupportOptionRow(
                    icon: "exclamationmark.triangle.fill",
                    title: "Report a Bug",
                    description: "Help us improve by reporting issues",
                    color: .red
                ) {
                    // Report bug
                }
            }
        }
        .padding(24)
        .background(cardBackground)
    }
    
    var appInformationSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "App Information", icon: "info.circle.fill")
            
            VStack(spacing: 16) {
                AppInfoRow(title: "Version", value: "1.0.0 (Build 1)")
                
                Divider().background(.white.opacity(0.2))
                
                AppInfoRow(title: "Last Updated", value: "December 2025")
                
                Divider().background(.white.opacity(0.2))
                
                AppInfoRow(title: "Support ID", value: generateSupportID())
                
                Divider().background(.white.opacity(0.2))
                
                Button("Copy Support Information") {
                    copyDebugInfo()
                }
                .foregroundColor(.cyan)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.cyan.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(.cyan.opacity(0.5), lineWidth: 1)
                        )
                )
            }
        }
        .padding(24)
        .background(cardBackground)
    }
}

// MARK: - Helper Functions
private extension HelpSupportView {
    
    func makePhoneCall() {
        let phoneNumber = "tel://15551238839" // +1 (555) 123-STUDY converted to numbers
        if let phoneURL = URL(string: phoneNumber),
           UIApplication.shared.canOpenURL(phoneURL) {
            UIApplication.shared.open(phoneURL)
        }
    }
    
    func openEmailApp() {
        let emailSubject = "StudyHub Support Request"
        let emailBody = generateEmailBody()
        
        if let emailURL = URL(string: "mailto:support@studyhub.app?subject=\(emailSubject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(emailBody.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            UIApplication.shared.open(emailURL)
        }
    }
    
    func generateEmailBody() -> String {
        let deviceInfo = """
        
        
        --- Device Information ---
        Device: \(UIDevice.current.name)
        iOS Version: \(UIDevice.current.systemVersion)
        App Version: 1.0.0 (Build 1)
        Support ID: \(generateSupportID())
        
        Please describe your issue below:
        """
        
        return deviceInfo
    }
    
    func generateSupportID() -> String {
        let uuid = UUID().uuidString
        return String(uuid.prefix(8).uppercased())
    }
    
    func copyDebugInfo() {
        let debugInfo = """
        StudyHub Support Information
        Version: 1.0.0 (Build 1)
        Device: \(UIDevice.current.name)
        iOS: \(UIDevice.current.systemVersion)
        Support ID: \(generateSupportID())
        """
        
        UIPasteboard.general.string = debugInfo
        
        // Show feedback that info was copied (could be a toast or haptic)
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    // MARK: - Background Components
    var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.black.opacity(0.4))
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.3), .white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 10)
    }
    
    var enhancedBackground: some View {
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
    }
}

// MARK: - Supporting Components
struct ContactRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let description: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(color)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.6))
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FAQRowView: View {
    let faqItem: FAQItem
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(faqItem.question)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.caption)
                }
                
                Text(String(faqItem.answer.prefix(100)) + (faqItem.answer.count > 100 ? "..." : ""))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.black.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SupportOptionRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.system(size: 18, weight: .semibold))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.6))
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.black.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.white.opacity(0.15), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AppInfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
    }
}

// MARK: - FAQ Data Model
struct FAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
    let category: String
}

private let faqItems: [FAQItem] = [
    FAQItem(
        question: "How do I start a study session?",
        answer: "To start a study session, go to the Focus Timer tab and tap the play button. You can select a specific task or start a free focus session. The default session is 25 minutes followed by a 5-minute break.",
        category: "Getting Started"
    ),
    FAQItem(
        question: "Can I customize timer durations?",
        answer: "Yes! Go to your Profile > Edit Profile to customize your default study session and break durations. You can set study sessions between 15-60 minutes and breaks between 5-20 minutes.",
        category: "Timer Settings"
    ),
    FAQItem(
        question: "How do I add tasks?",
        answer: "Tap the + button in the Tasks tab to add a new task. Fill in the title, description, due date, priority level, and subject. Your tasks will automatically sync across all your devices.",
        category: "Task Management"
    ),
    FAQItem(
        question: "What are study groups?",
        answer: "Study groups allow you to collaborate with other students. You can create or join groups, share study sessions, and motivate each other to reach your goals. Groups can be public or private with invite codes.",
        category: "Study Groups"
    ),
    FAQItem(
        question: "How do notifications work?",
        answer: "StudyHub can send you notifications for timer completion, study reminders, and achievement celebrations. You can customize which notifications you receive in the App Settings.",
        category: "Notifications"
    ),
    FAQItem(
        question: "How is my data synchronized?",
        answer: "All your data is securely stored in the cloud using Firebase. This means your tasks, sessions, and progress are automatically synced across all your devices when you're signed in.",
        category: "Data & Sync"
    ),
    FAQItem(
        question: "Can I export my study data?",
        answer: "Yes, you can export your study statistics and task history. Go to App Settings > Data & Privacy > Export Data to download a copy of your information.",
        category: "Data & Privacy"
    ),
    FAQItem(
        question: "How do I reset my password?",
        answer: "You can change your password in App Settings > Change Password. You'll need to enter your current password and choose a new one. For forgotten passwords, use the 'Forgot Password' link on the login screen.",
        category: "Account"
    )
]

// MARK: - FAQ Detail View
struct FAQDetailView: View {
    let faqItem: FAQItem
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
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
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text(faqItem.question)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                        
                        Text(faqItem.answer)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                            .lineSpacing(4)
                        
                        HStack {
                            Text("Category")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                                .textCase(.uppercase)
                            
                            Spacer()
                            
                            Text(faqItem.category)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.cyan)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.cyan.opacity(0.2))
                                .cornerRadius(8)
                        }
                        
                        Spacer()
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.black.opacity(0.4))
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.ultraThinMaterial)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(.white.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.3), radius: 10)
                    )
                    .padding(20)
                }
            }
            .navigationTitle("FAQ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.cyan)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Mail Composer
struct MailComposeView: UIViewControllerRepresentable {
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = context.coordinator
        
        mailComposer.setToRecipients(["support@studyhub.app"])
        mailComposer.setSubject("StudyHub Support Request")
        
        let messageBody = """
        Hi StudyHub Support Team,
        
        I need help with:
        
        [Please describe your issue here]
        
        
        --- Device Information ---
        Device: \(UIDevice.current.name)
        iOS Version: \(UIDevice.current.systemVersion)
        App Version: 1.0.0 (Build 1)
        Support ID: \(UUID().uuidString.prefix(8).uppercased())
        
        Thank you!
        """
        
        mailComposer.setMessageBody(messageBody, isHTML: false)
        
        return mailComposer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            controller.dismiss(animated: true)
        }
    }
}

#Preview {
    HelpSupportView()
}
