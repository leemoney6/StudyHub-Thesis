import SwiftUI
import Combine

@MainActor
class TaskViewModel: ObservableObject {
    @Published var tasks: [StudyTask] = []
    @Published var filteredTasks: [StudyTask] = []
    @Published var searchText = ""
    @Published var selectedPriority: TaskPriority?
    @Published var selectedSubject: String?
    @Published var showingAddTask = false
    @Published var showingTaskDetail = false
    @Published var selectedTask: StudyTask?
    
    // Common subjects for students
    let subjects = ["Mathematics", "Physics", "Chemistry", "Biology", "Computer Science", "Literature", "History", "Economics", "Other"]
    
    init() {
        loadMockTasks()
        updateFilteredTasks()
    }
    
    // MARK: - Task Operations
    func addTask(_ task: StudyTask) {
        tasks.append(task)
        updateFilteredTasks()
        saveTasks()
    }
    
    func updateTask(_ task: StudyTask) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
            updateFilteredTasks()
            saveTasks()
        }
    }
    
    func deleteTask(_ task: StudyTask) {
        tasks.removeAll { $0.id == task.id }
        updateFilteredTasks()
        saveTasks()
    }
    
    func toggleTaskCompletion(_ task: StudyTask) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
            updateFilteredTasks()
            saveTasks()
        }
    }
    
    // MARK: - Filtering
    func updateFilteredTasks() {
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
        
        // Subject filter
        if let subject = selectedSubject {
            filtered = filtered.filter { $0.subject == subject }
        }
        
        // Sort by due date and priority
        filtered.sort { lhs, rhs in
            if lhs.isCompleted != rhs.isCompleted {
                return !lhs.isCompleted // Incomplete tasks first
            }
            
            if lhs.dueDate != rhs.dueDate {
                return lhs.dueDate < rhs.dueDate // Earlier due dates first
            }
            
            return lhs.priority.rawValue > rhs.priority.rawValue // Higher priority first
        }
        
        filteredTasks = filtered
    }
    
    // MARK: - Statistics
    var completedTasksCount: Int {
        tasks.filter { $0.isCompleted }.count
    }
    
    var totalTasksCount: Int {
        tasks.count
    }
    
    var completionPercentage: Double {
        guard totalTasksCount > 0 else { return 0 }
        return Double(completedTasksCount) / Double(totalTasksCount)
    }
    
    var overdueTasks: [StudyTask] {
        tasks.filter { !$0.isCompleted && $0.dueDate < Date() }
    }
    
    var todayTasks: [StudyTask] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        return tasks.filter { task in
            !task.isCompleted && task.dueDate >= today && task.dueDate < tomorrow
        }
    }
    
    // MARK: - Persistence (UserDefaults for now)
    private func saveTasks() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(encoded, forKey: "StudyHubTasks")
        }
    }
    
    private func loadTasks() {
        if let data = UserDefaults.standard.data(forKey: "StudyHubTasks"),
           let decoded = try? JSONDecoder().decode([StudyTask].self, from: data) {
            tasks = decoded
        }
    }
    
    // MARK: - Mock Data
    private func loadMockTasks() {
        let calendar = Calendar.current
        let today = Date()
        
        tasks = [
            StudyTask(title: "Complete Mathematics Assignment",
                 description: "Solve problems 1-15 from Chapter 7",
                 dueDate: calendar.date(byAdding: .day, value: 2, to: today)!,
                 priority: .high,
                 subject: "Mathematics"),
            
            StudyTask(title: "Read Physics Chapter 5",
                 description: "Study quantum mechanics fundamentals",
                 dueDate: calendar.date(byAdding: .day, value: 1, to: today)!,
                 priority: .medium,
                 subject: "Physics"),
            
            StudyTask(title: "Prepare History Presentation",
                 description: "Create slides about World War II",
                 dueDate: calendar.date(byAdding: .day, value: 5, to: today)!,
                 priority: .medium,
                 subject: "History"),
            
            StudyTask(title: "Lab Report - Chemistry",
                 description: "Write up results from acid-base experiment",
                 dueDate: calendar.date(byAdding: .day, value: 3, to: today)!,
                 priority: .high,
                 subject: "Chemistry"),
            
            StudyTask(title: "Code Review - iOS App",
                 description: "Review StudyHub authentication module",
                 dueDate: today,
                 priority: .urgent,
                 subject: "Computer Science")
        ]
        
        // Mark some as completed
        tasks[0].isCompleted = true
        tasks[2].isCompleted = true
    }
}
