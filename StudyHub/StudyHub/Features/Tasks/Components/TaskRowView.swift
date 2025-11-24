import SwiftUI

struct TaskRowView: View {
    let task: StudyTask 
    let viewModel: TaskViewModel
    @State private var showingTaskDetail = false
    
    var body: some View {
        Button {
            showingTaskDetail = true
        } label: {
            HStack(spacing: 16) {
                // Completion checkbox
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.toggleTaskCompletion(task)
                    }
                } label: {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(task.isCompleted ? .green : .white.opacity(0.6))
                }
                
                // Task content
                VStack(alignment: .leading, spacing: 8) {
                    // Title and priority
                    HStack {
                        Text(task.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .strikethrough(task.isCompleted)
                        
                        Spacer()
                        
                        // Priority indicator
                        HStack(spacing: 4) {
                            Image(systemName: task.priority.icon)
                                .font(.caption)
                            Text(task.priority.rawValue)
                                .font(.caption)
                        }
                        .foregroundColor(task.priority.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(task.priority.color.opacity(0.2))
                        .cornerRadius(6)
                    }
                    
                    // Description (if exists)
                    if !task.description.isEmpty {
                        Text(task.description)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(2)
                    }
                    
                    // Bottom row: Subject and due date
                    HStack {
                        // Subject tag
                        Text(task.subject)
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.blue.opacity(0.2))
                            .cornerRadius(4)
                        
                        Spacer()
                        
                        // Due date
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption2)
                            Text(formattedDueDate)
                                .font(.caption)
                        }
                        .foregroundColor(dueDateColor)
                    }
                }
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white.opacity(task.isCompleted ? 0.05 : 0.08))
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial.opacity(0.8))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.white.opacity(0.15), lineWidth: 1)
                    }
            }
            .opacity(task.isCompleted ? 0.7 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingTaskDetail) {
            TaskDetailView(task: task, viewModel: viewModel)
        }
    }
    
    private var formattedDueDate: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(task.dueDate) {
            return "Today"
        } else if calendar.isDateInTomorrow(task.dueDate) {
            return "Tomorrow"
        } else if calendar.isDate(task.dueDate, equalTo: Date(), toGranularity: .weekOfYear) {
            formatter.dateFormat = "EEEE"
            return formatter.string(from: task.dueDate)
        } else {
            formatter.dateFormat = "MMM d"
            return formatter.string(from: task.dueDate)
        }
    }
    
    private var dueDateColor: Color {
        let calendar = Calendar.current
        
        if task.isCompleted {
            return .white.opacity(0.6)
        } else if task.dueDate < Date() {
            return .red // Overdue
        } else if calendar.isDateInToday(task.dueDate) {
            return .orange // Due today
        } else if calendar.isDateInTomorrow(task.dueDate) {
            return .yellow // Due tomorrow
        } else {
            return .white.opacity(0.7)
        }
    }
}

#Preview {
    TaskRowView(
        task: StudyTask(
            title: "Complete Mathematics Assignment",
            description: "Solve problems 1-15 from Chapter 7",
            dueDate: Date(),
            priority: .high,
            subject: "Mathematics"
        ),
        viewModel: TaskViewModel()
    )
    .padding()
    .background(.black)
}
