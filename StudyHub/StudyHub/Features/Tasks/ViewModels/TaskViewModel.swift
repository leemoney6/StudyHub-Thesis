import SwiftUI
import Combine
import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
class TaskViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var tasks: [StudyTask] = []
    @Published var filteredTasks: [StudyTask] = []
    @Published var searchText = ""
    @Published var selectedPriority: TaskPriority?
    @Published var selectedSubject: String?
    @Published var showingAddTask = false
    @Published var showingTaskDetail = false
    @Published var selectedTask: StudyTask?
    
    // MARK: - Firebase Integration Properties
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showingError = false
    
    // MARK: - Firebase Instances
    private let firestore = Firestore.firestore()
    private let auth = Auth.auth()
    private var tasksListener: ListenerRegistration?
    
    // MARK: - Constants
    let subjects = ["Mathematics", "Physics", "Chemistry", "Biology", "Computer Science", "Literature", "History", "Economics", "Other"]
    
    init() {
        setupTasksListener()
    }
    
    deinit {
        tasksListener?.remove()
    }
    
    // MARK: - Firebase Real-time Listener
    private func setupTasksListener() {
        guard let currentUser = auth.currentUser else {
            print("⚠️ No authenticated user for tasks")
            return
        }
        
        isLoading = true
        
        tasksListener = firestore
            .collection("users")
            .document(currentUser.uid)
            .collection("tasks")
            .addSnapshotListener { [weak self] snapshot, error in
                
                Task {
                    await MainActor.run {
                        self?.handleTasksUpdate(snapshot: snapshot, error: error)
                    }
                }
            }
    }
    
    private func handleTasksUpdate(snapshot: QuerySnapshot?, error: Error?) {
        isLoading = false
        
        if let error = error {
            handleError("Failed to load tasks: \(error.localizedDescription)")
            return
        }
        
        guard let documents = snapshot?.documents else {
            tasks = []
            updateFilteredTasks()
            return
        }
        
        // ← FIXED: Removed problematic ID assignment
        let loadedTasks = documents.compactMap { document -> StudyTask? in
            do {
                let task = try document.data(as: StudyTask.self)
                // ← REMOVED: task.id = document.documentID (this was causing the error)
                return task
            } catch {
                print("❌ Error decoding task \(document.documentID): \(error)")
                return nil
            }
        }
        
        tasks = loadedTasks
        updateFilteredTasks()
        
        print("✅ Loaded \(tasks.count) tasks from Firestore")
    }
    
    // MARK: - Firebase CRUD Operations
    func addTask(_ task: StudyTask) async {
        guard let currentUser = auth.currentUser else {
            handleError("Please sign in to add tasks")
            return
        }
        
        isLoading = true
        
        do {
            let data = try Firestore.Encoder().encode(task)
            
            // ← FIXED: Use task.id.uuidString as document ID
            try await firestore
                .collection("users")
                .document(currentUser.uid)
                .collection("tasks")
                .document(task.id.uuidString)
                .setData(data)
            
            print("✅ Task added successfully: \(task.title)")
            
        } catch {
            handleError("Failed to add task: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func updateTask(_ task: StudyTask) async {
        guard let currentUser = auth.currentUser else {
            handleError("Please sign in to update tasks")
            return
        }
        
        do {
            let data = try Firestore.Encoder().encode(task)
            
            try await firestore
                .collection("users")
                .document(currentUser.uid)
                .collection("tasks")
                .document(task.id.uuidString)
                .setData(data)
            
            print("✅ Task updated successfully: \(task.title)")
            
        } catch {
            handleError("Failed to update task: \(error.localizedDescription)")
        }
    }
    
    func deleteTask(_ task: StudyTask) async {
        guard let currentUser = auth.currentUser else {
            handleError("Please sign in to delete tasks")
            return
        }
        
        do {
            try await firestore
                .collection("users")
                .document(currentUser.uid)
                .collection("tasks")
                .document(task.id.uuidString)
                .delete()
            
            print("✅ Task deleted successfully: \(task.title)")
            
        } catch {
            handleError("Failed to delete task: \(error.localizedDescription)")
        }
    }
    
    func toggleTaskCompletion(_ task: StudyTask) async {
        var updatedTask = task
        updatedTask.isCompleted.toggle()
        await updateTask(updatedTask)
    }
    
    // MARK: - User Management
    func refreshForNewUser() {
        tasksListener?.remove()
        tasks = []
        filteredTasks = []
        setupTasksListener()
    }
    
    func clearTasksForSignOut() {
        tasksListener?.remove()
        tasks = []
        filteredTasks = []
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
    
    // MARK: - Error Handling
    private func handleError(_ message: String) {
        errorMessage = message
        showingError = true
        print("❌ TaskViewModel Error: \(message)")
        
        // Auto-clear error after 4 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.clearError()
        }
    }
    
    private func clearError() {
        errorMessage = ""
        showingError = false
    }
    
    // MARK: - Demo Data
    func addDemoTasks() async {
        let calendar = Calendar.current
        let today = Date()
        
        let demoTasks = [
            StudyTask(
                title: "Complete Mathematics Assignment",
                description: "Solve problems 1-15 from Chapter 7",
                dueDate: calendar.date(byAdding: .day, value: 2, to: today)!,
                priority: .high,
                subject: "Mathematics"
            ),
            StudyTask(
                title: "Read Physics Chapter 5",
                description: "Study quantum mechanics fundamentals",
                dueDate: calendar.date(byAdding: .day, value: 1, to: today)!,
                priority: .medium,
                subject: "Physics"
            ),
            StudyTask(
                title: "Lab Report - Chemistry",
                description: "Write up results from acid-base experiment",
                dueDate: calendar.date(byAdding: .day, value: 3, to: today)!,
                priority: .high,
                subject: "Chemistry"
            )
        ]
        
        for task in demoTasks {
            await addTask(task)
        }
    }
}
