import SwiftUI

// MARK: - Firebase-Enhanced Task Selector View for Timer
struct TaskSelectorView: View {
    let tasks: [StudyTask]
    @Binding var selectedTask: StudyTask?
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var selectedPriority: TaskPriority?
    
    var filteredTasks: [StudyTask] {
        var filtered = tasks
        
        // Search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { task in
                task.title.localizedCaseInsensitiveContains(searchText) ||
                task.description.localizedCaseInsensitiveContains(searchText) ||
                task.subject.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Priority filter
        if let priority = selectedPriority {
            filtered = filtered.filter { $0.priority == priority }
        }
        
        // Sort by priority and due date
        filtered.sort { lhs, rhs in
            if lhs.priority != rhs.priority {
                return lhs.priority.rawValue > rhs.priority.rawValue // Higher priority first
            }
            return lhs.dueDate < rhs.dueDate // Earlier due dates first
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                
                VStack(spacing: 0) {
                    // Search and filter section
                    searchAndFilterSection
                    
                    // Task list
                    taskListSection
                }
            }
            .navigationTitle("Select Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if selectedTask != nil {
                        Button("Clear") {
                            selectedTask = nil
                            dismiss()
                        }
                        .foregroundColor(.orange)
                    }
                }
            }
        }
    }
    
    private var backgroundGradient: some View {
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
    
    private var searchAndFilterSection: some View {
        VStack(spacing: 16) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.6))
                
                TextField("Search tasks...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.white)
                
                if !searchText.isEmpty {
                    Button("Clear") {
                        searchText = ""
                    }
                    .foregroundColor(.cyan)
                    .font(.caption)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.black.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
            )
            
            // Priority filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    PriorityFilterChip(
                        title: "All",
                        isSelected: selectedPriority == nil,
                        color: .gray
                    ) {
                        selectedPriority = nil
                    }
                    
                    ForEach(TaskPriority.allCases, id: \.self) { priority in
                        PriorityFilterChip(
                            title: priority.rawValue,
                            isSelected: selectedPriority == priority,
                            color: priority.color
                        ) {
                            selectedPriority = selectedPriority == priority ? nil : priority
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(20)
        .background(cardBackground)
    }
    
    private var taskListSection: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Free focus option
                freeSessionOption
                
                // Task list
                if filteredTasks.isEmpty {
                    emptyStateView
                } else {
                    taskList
                }
                
                Spacer(minLength: 50)
            }
            .padding(20)
        }
    }
    
    private var freeSessionOption: some View {
        TaskSelectorRow(
            title: "Free Focus Session",
            subtitle: "Study without a specific task",
            icon: "brain.head.profile",
            color: .purple,
            isSelected: selectedTask == nil,
            priority: nil,
            dueDate: nil
        ) {
            selectedTask = nil
            dismiss()
        }
    }
    
    private var taskList: some View {
        LazyVStack(spacing: 12) {
            ForEach(filteredTasks, id: \.id) { task in
                TaskSelectorRow(
                    title: task.title,
                    subtitle: task.description.isEmpty ? task.subject : task.description,
                    icon: "checkmark.circle",
                    color: task.priority.color,
                    isSelected: selectedTask?.id == task.id,
                    priority: task.priority,
                    dueDate: task.dueDate
                ) {
                    selectedTask = task
                    dismiss()
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No tasks found")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                if !searchText.isEmpty {
                    Text("Try a different search term")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                } else if selectedPriority != nil {
                    Text("No tasks with this priority")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                } else {
                    Text("Add tasks in the Tasks tab")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding(.top, 60)
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.black.opacity(0.4))
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
    }
}

// MARK: - Supporting Views
struct TaskSelectorRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let priority: TaskPriority?
    let dueDate: Date?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Task icon
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Circle()
                                .stroke(color, lineWidth: isSelected ? 3 : 1)
                        )
                    
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                        .fontWeight(.semibold)
                }
                
                // Task info
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    
                    // Priority and due date
                    if let priority = priority, let dueDate = dueDate {
                        HStack(spacing: 12) {
                            // Priority badge
                            HStack(spacing: 4) {
                                Image(systemName: priority.icon)
                                Text(priority.rawValue)
                            }
                            .font(.caption2)
                            .foregroundColor(priority.color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(priority.color.opacity(0.2))
                            .cornerRadius(4)
                            
                            // Due date
                            Text("Due \(dueDate, style: .relative)")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(color)
                        .fontWeight(.semibold)
                        .font(.title3)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? color.opacity(0.1) : .black.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? color : .white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PriorityFilterChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(isSelected ? .white : color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? color : color.opacity(0.2))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color, lineWidth: isSelected ? 0 : 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    TaskSelectorView(
        tasks: [
            StudyTask(
                title: "Mathematics Assignment",
                description: "Complete problems 1-15",
                dueDate: Date().addingTimeInterval(86400),
                priority: .high,
                subject: "Mathematics"
            ),
            StudyTask(
                title: "Physics Lab Report",
                description: "Write up results from experiment",
                dueDate: Date().addingTimeInterval(172800),
                priority: .medium,
                subject: "Physics"
            )
        ],
        selectedTask: .constant(nil)
    )
}
