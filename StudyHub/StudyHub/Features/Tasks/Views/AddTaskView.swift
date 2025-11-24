import SwiftUI

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TaskViewModel
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedSubject = "Mathematics"
    @State private var selectedPriority: TaskPriority = .medium
    @State private var dueDate = Date()
    @State private var showingDatePicker = false
    
    private var isValidTask: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Same background as other views
                enhancedBackground
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Task title
                        taskTitleSection
                        
                        // Task description
                        taskDescriptionSection
                        
                        // Subject selection
                        subjectSelectionSection
                        
                        // Priority selection
                        prioritySelectionSection
                        
                        // Due date selection
                        dueDateSection
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTask()
                    }
                    .foregroundColor(isValidTask ? .blue : .gray)
                    .disabled(!isValidTask)
                }
            }
        }
    }
    
    private func saveTask() {
        let newTask = StudyTask(
            title: title.trimmingCharacters(in: .whitespaces),
            description: description.trimmingCharacters(in: .whitespaces),
            dueDate: dueDate,
            priority: selectedPriority,
            subject: selectedSubject
        )
        
        viewModel.addTask(newTask)
        dismiss()
    }
}

// MARK: - Form Sections
private extension AddTaskView {
    
    var taskTitleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Task Title")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            TextField("Enter task title...", text: $title)
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(16)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.white.opacity(0.08))
                        .background {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.white.opacity(0.2), lineWidth: 1)
                        }
                }
        }
    }
    
    var taskDescriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Description (Optional)")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            TextField("Add more details...", text: $description, axis: .vertical)
                .font(.subheadline)
                .foregroundColor(.white)
                .lineLimit(3...6)
                .padding(16)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.white.opacity(0.08))
                        .background {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.white.opacity(0.2), lineWidth: 1)
                        }
                }
        }
    }
    
    var subjectSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Subject")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Menu {
                ForEach(viewModel.subjects, id: \.self) { subject in
                    Button(subject) {
                        selectedSubject = subject
                    }
                }
            } label: {
                HStack {
                    Text(selectedSubject)
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(16)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.white.opacity(0.08))
                        .background {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.white.opacity(0.2), lineWidth: 1)
                        }
                }
            }
        }
    }
    
    var prioritySelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Priority")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(TaskPriority.allCases, id: \.self) { priority in
                    Button {
                        selectedPriority = priority
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: priority.icon)
                                .font(.subheadline)
                            Text(priority.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(selectedPriority == priority ? .white : priority.color)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            selectedPriority == priority ?
                            priority.color.opacity(0.8) : priority.color.opacity(0.2)
                        )
                        .cornerRadius(10)
                        .overlay {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(priority.color.opacity(0.5), lineWidth: 1)
                        }
                    }
                }
            }
        }
    }
    
    var dueDateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Due Date")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Button {
                showingDatePicker = true
            } label: {
                HStack {
                    Image(systemName: "calendar")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    
                    Text(dueDate, style: .date)
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(dueDate, style: .time)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(16)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.white.opacity(0.08))
                        .background {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.white.opacity(0.2), lineWidth: 1)
                        }
                }
            }
            .sheet(isPresented: $showingDatePicker) {
                DatePickerView(selectedDate: $dueDate)
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

// MARK: - Date Picker Sheet
struct DatePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDate: Date
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                
                Spacer()
            }
            .padding()
            .navigationTitle("Due Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    AddTaskView(viewModel: TaskViewModel())
}
