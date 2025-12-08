import Foundation
import FirebaseFirestore

@MainActor
class UserStatsViewModel: ObservableObject {
    @Published var tasksCompleted: Int = 0
    @Published var studySessions: Int = 0      // placeholder for later
    @Published var totalHours: Double = 0      // placeholder for later
    @Published var streakDays: Int = 0         // placeholder for later
    
    private var listener: ListenerRegistration?
    
    deinit {
        listener?.remove()
    }
    
    func startListening(userId: String) {
        let db = Firestore.firestore()
        
        // Stop old listener if we switch user
        listener?.remove()
        
        listener = db.collection("users")
            .document(userId)
            .collection("tasks")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Stats listener error:", error.localizedDescription)
                    return
                }
                
                guard let docs = snapshot?.documents else { return }
                
                // Decode to StudyTask – you already have this model
                let tasks: [StudyTask] = docs.compactMap { doc in
                    return try? doc.data(as: StudyTask.self)
                }
                
                Task { @MainActor in
                    self.tasksCompleted = tasks.filter { $0.isCompleted }.count
                    
                    // TODO: later compute studySessions, totalHours, streakDays
                    
                }
            }
    }
}
