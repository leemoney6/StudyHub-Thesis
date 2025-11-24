import SwiftUI
import WebKit

struct TasksView: View {
    @StateObject private var viewModel = TaskViewModel()
    @State private var showingFilters = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Same background as dashboard
                enhancedBackground
                
                VStack(spacing: 0) {
                    // Statistics header
                    statisticsHeader
                    
                    // Tasks list
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if viewModel.filteredTasks.isEmpty {
                                emptyStateView
                            } else {
                                ForEach(viewModel.filteredTasks) { task in
                                    TaskRowView(task: task, viewModel: viewModel)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
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
        .onAppear {
            viewModel.updateFilteredTasks()
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
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
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
    
    var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green.opacity(0.7))
            
            Text("All caught up!")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text("You have no tasks matching your current filters.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 40)
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

#Preview {
    TasksView()
}
