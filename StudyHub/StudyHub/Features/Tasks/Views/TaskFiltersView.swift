import SwiftUI

struct TaskFiltersView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TaskViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                enhancedBackground
                
                VStack(spacing: 24) {
                    // Priority Filter Section
                    priorityFilterSection
                    
                    // Subject Filter Section
                    subjectFilterSection
                    
                    // Clear Filters Button
                    clearFiltersSection
                    
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Filter Tasks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        viewModel.updateFilteredTasks()
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        // Show Firebase errors if any occur during filtering
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

// MARK: - Filter Sections (EXACT SAME DESIGN)
private extension TaskFiltersView {
    
    var priorityFilterSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Filter by Priority")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                // All priorities option
                Button {
                    viewModel.selectedPriority = nil
                } label: {
                    HStack {
                        Text("All Priorities")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(viewModel.selectedPriority == nil ? .white : .white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(viewModel.selectedPriority == nil ? .blue.opacity(0.6) : .white.opacity(0.1))
                    .cornerRadius(10)
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    }
                }
                
                ForEach(TaskPriority.allCases, id: \.self) { priority in
                    Button {
                        viewModel.selectedPriority = viewModel.selectedPriority == priority ? nil : priority
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: priority.icon)
                                .font(.subheadline)
                            Text(priority.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(viewModel.selectedPriority == priority ? .white : priority.color)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            viewModel.selectedPriority == priority ?
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
    
    var subjectFilterSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Filter by Subject")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                // All subjects option
                Button {
                    viewModel.selectedSubject = nil
                } label: {
                    Text("All Subjects")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(viewModel.selectedSubject == nil ? .white : .white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(viewModel.selectedSubject == nil ? .purple.opacity(0.6) : .white.opacity(0.1))
                        .cornerRadius(10)
                        .overlay {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(.white.opacity(0.2), lineWidth: 1)
                        }
                }
                
                ForEach(viewModel.subjects, id: \.self) { subject in
                    Button {
                        viewModel.selectedSubject = viewModel.selectedSubject == subject ? nil : subject
                    } label: {
                        Text(subject)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(viewModel.selectedSubject == subject ? .white : .blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                viewModel.selectedSubject == subject ?
                                .blue.opacity(0.8) : .blue.opacity(0.2)
                            )
                            .cornerRadius(10)
                            .overlay {
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(.blue.opacity(0.5), lineWidth: 1)
                            }
                    }
                }
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
    
    var clearFiltersSection: some View {
        Button {
            viewModel.selectedPriority = nil
            viewModel.selectedSubject = nil
            viewModel.updateFilteredTasks()
        } label: {
            HStack {
                Image(systemName: "xmark.circle")
                    .font(.subheadline)
                Text("Clear All Filters")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(.red.opacity(0.6))
            .cornerRadius(12)
        }
        .padding(.horizontal, 20)
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

#Preview {
    TaskFiltersView(viewModel: TaskViewModel())
}
