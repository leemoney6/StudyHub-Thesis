import SwiftUI

struct TaskDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State var task: StudyTask
    @ObservedObject var viewModel: TaskViewModel
    @State private var isEditing = false
    @State private var isLoading = false // Added for Firebase operations
    @State private var showingDeleteAlert = false // Added delete confirmation
    
    var body: some View {
        NavigationView {
            ZStack {
                enhancedBackground
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Task header
                        taskHeaderSection
                        
                        // Task details
                        taskDetailsSection
                        
                        // Actions
                        taskActionsSection
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Task Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .disabled(isLoading) // Disable during loading
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        isEditing = true
                    }
                    .foregroundColor(.blue)
                    .disabled(isLoading) // Disable during loading
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            EditTaskView(task: task, viewModel: viewModel)
        }
        .alert("Delete Task", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await deleteTask()
                }
            }
        } message: {
            Text("Are you sure you want to delete '\(task.title)'? This action cannot be undone.")
        }
        // Show Firebase errors
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
    
    private func toggleCompletion() async {
        isLoading = true
        
        // Update local state immediately for UI feedback
        withAnimation {
            task.isCompleted.toggle()
        }
        
        await viewModel.toggleTaskCompletion(task)
        isLoading = false
    }
    
    private func deleteTask() async {
        isLoading = true
        await viewModel.deleteTask(task)
        isLoading = false
        dismiss()
    }
}

// MARK: - Task Detail Sections (EXACT SAME DESIGN)
private extension TaskDetailView {
    
    var taskHeaderSection: some View {
        VStack(spacing: 16) {
            HStack {
                Button {
                    Task {
                        await toggleCompletion()
                    }
                } label: {
                    ZStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.title)
                                .foregroundColor(task.isCompleted ? .green : .white.opacity(0.6))
                        }
                    }
                    .frame(width: 28, height: 28)
                }
                .disabled(isLoading)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(task.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .strikethrough(task.isCompleted)
                    
                    HStack(spacing: 12) {
                        // Priority badge
                        HStack(spacing: 4) {
                            Image(systemName: task.priority.icon)
                            Text(task.priority.rawValue)
                        }
                        .font(.caption)
                        .foregroundColor(task.priority.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(task.priority.color.opacity(0.2))
                        .cornerRadius(6)
                        
                        // Subject badge
                        Text(task.subject)
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.blue.opacity(0.2))
                            .cornerRadius(6)
                    }
                }
                
                Spacer()
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.08))
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial.opacity(0.8))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                }
        }
    }
    
    var taskDetailsSection: some View {
        let backgroundView = RoundedRectangle(cornerRadius: 16)
            .fill(.white.opacity(0.08))
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial.opacity(0.8))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
        
        return VStack(alignment: .leading, spacing: 20) {
            if !task.description.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(task.description)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Details")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                VStack(spacing: 12) {
                    DetailRow(icon: "calendar", title: "Due Date", value: task.dueDate, formatter: DetailRow.dateTime)
                    DetailRow(icon: "clock", title: "Created", value: task.createdDate, formatter: DetailRow.dateTime)
                    
                    if task.isCompleted {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Completed")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                            Spacer()
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(backgroundView)
    }
    
    var taskActionsSection: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    await toggleCompletion()
                }
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: task.isCompleted ? "arrow.clockwise" : "checkmark")
                            .font(.subheadline)
                    }
                    Text(task.isCompleted ? "Mark as Incomplete" : "Mark as Complete")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(task.isCompleted ? .orange.opacity(0.6) : .green.opacity(0.6))
                .cornerRadius(10)
            }
            .disabled(isLoading)
            
            Button {
                showingDeleteAlert = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                        .font(.subheadline)
                    Text("Delete Task")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(.red.opacity(0.6))
                .cornerRadius(10)
            }
            .disabled(isLoading)
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.08))
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial.opacity(0.8))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                }
        }
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

// MARK: - Supporting Views (EXACT SAME)
struct DetailRow: View {
    let icon: String
    let title: String
    let value: Date
    let formatter: DateFormatter
    
    static let dateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Text(formatter.string(from: value))
                .font(.subheadline)
                .foregroundColor(.white)
        }
    }
}

// Placeholder for EditTaskView (EXACT SAME)
struct EditTaskView: View {
    let task: StudyTask
    let viewModel: TaskViewModel
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
                
                VStack(spacing: 20) {
                    Text("Edit Task")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    Text("Edit functionality coming soon!")
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                }
                .padding(40)
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

#Preview {
    TaskDetailView(
        task: StudyTask(
            title: "Complete Mathematics Assignment",
            description: "Solve problems 1-15 from Chapter 7. Focus on quadratic equations and logarithmic functions.",
            dueDate: Date(),
            priority: .high,
            subject: "Mathematics"
        ),
        viewModel: TaskViewModel()
    )
}
