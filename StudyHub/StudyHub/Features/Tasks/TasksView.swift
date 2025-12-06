import SwiftUI

struct TasksView: View {
    @StateObject private var viewModel = TaskViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingFilters = false
    @State private var showingAddFirstTask = false
    
    var body: some View {
        NavigationView {
            ZStack {
                enhancedBackground
                
                VStack(spacing: 0) {
                    // Statistics header
                    statisticsHeader
                    
                    // Tasks list or loading state
                    if viewModel.isLoading && viewModel.tasks.isEmpty {
                        loadingView
                    } else if viewModel.tasks.isEmpty {
                        emptyStateView
                    } else {
                        tasksListView
                    }
                }
            }
            .navigationTitle("Tasks")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingFilters.toggle() }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.showingAddTask = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Search tasks...")
        .onChange(of: viewModel.searchText) { _ in
            viewModel.updateFilteredTasks()
        }
        .sheet(isPresented: $viewModel.showingAddTask) {
            AddTaskView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingFilters) {
            TaskFiltersView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingAddFirstTask) {
            FirstTaskView(viewModel: viewModel)
        }
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK") {
                viewModel.showingError = false
            }
        } message: {
            Text(viewModel.errorMessage)
        }
        .onAppear {
            viewModel.updateFilteredTasks()
        }
        .onChange(of: authViewModel.isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                viewModel.refreshForNewUser()
            } else {
                viewModel.clearTasksForSignOut()
            }
        }
    }
}

// MARK: - Supporting Views
private extension TasksView {
    
    var statisticsHeader: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Progress")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("\(viewModel.completedTasksCount) of \(viewModel.totalTasksCount) tasks completed")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                // Circular progress
                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.2), lineWidth: 8)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: viewModel.completionPercentage)
                        .stroke(
                            LinearGradient(colors: [.blue, .green], startPoint: .topLeading, endPoint: .bottomTrailing),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.5), value: viewModel.completionPercentage)
                    
                    Text("\(Int(viewModel.completionPercentage * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            
            // Quick stats
            HStack(spacing: 20) {
                statCard("Today", count: viewModel.todayTasks.count, color: .blue)
                statCard("Overdue", count: viewModel.overdueTasks.count, color: .red)
                statCard("Completed", count: viewModel.completedTasksCount, color: .green)
            }
        }
        .padding(20)
        .background(cardBackground)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
    
    var tasksListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if viewModel.filteredTasks.isEmpty && !viewModel.searchText.isEmpty {
                    noResultsView
                } else {
                    ForEach(viewModel.filteredTasks) { task in
                        TaskRowView(task: task, viewModel: viewModel)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
        .refreshable {
            // Pull to refresh - Firebase listener automatically updates
            await Task.sleep(nanoseconds: 500_000_000) // Small delay for UX
        }
    }
    
    var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .cyan))
                .scaleEffect(1.2)
            
            Text("Loading your tasks...")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    var emptyStateView: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 60)
                
                // Welcome illustration
                ZStack {
                    Circle()
                        .fill(.blue.opacity(0.2))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.cyan)
                }
                
                VStack(spacing: 12) {
                    Text("Welcome to StudyHub!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Start organizing your academic life by adding your first task")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                VStack(spacing: 16) {
                    Button("Add Your First Task") {
                        showingAddFirstTask = true
                    }
                    .buttonStyle(PrimaryTaskButtonStyle())
                    
                    Button("Add Demo Tasks") {
                        Task {
                            await viewModel.addDemoTasks()
                        }
                    }
                    .buttonStyle(SecondaryTaskButtonStyle())
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
        }
    }
    
    var noResultsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No tasks found")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("Try adjusting your search or filters")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.top, 60)
    }
    
    func statCard(_ title: String, count: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
    
    var cardBackground: some View {
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
    
    var enhancedBackground: some View {
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
            
            // Subtle floating shapes
            Circle()
                .fill(.blue.opacity(0.1))
                .frame(width: 200, height: 200)
                .offset(x: -80, y: -150)
                .blur(radius: 60)
            
            Circle()
                .fill(.purple.opacity(0.08))
                .frame(width: 150, height: 150)
                .offset(x: 120, y: 200)
                .blur(radius: 50)
        }
    }
}

// MARK: - Button Styles
struct PrimaryTaskButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [.cyan, .blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryTaskButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.cyan)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.cyan.opacity(0.6), lineWidth: 1.5)
                    .background(.cyan.opacity(0.1))
            )
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - First Task View
struct FirstTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TaskViewModel
    
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
                
                VStack(spacing: 30) {
                    VStack(spacing: 16) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.yellow)
                        
                        VStack(spacing: 8) {
                            Text("Add Your First Task!")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Let's get you started with your first study task")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                    }
                    
                    AddTaskFormView(viewModel: viewModel, isFirstTask: true, onTaskAdded: {
                        dismiss()
                    })
                    
                    Spacer()
                }
                .padding(30)
            }
            .navigationTitle("Welcome")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Maybe Later") {
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }
}

#Preview {
    TasksView()
        .environmentObject(AuthViewModel())
}
