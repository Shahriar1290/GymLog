import Foundation
import FirebaseFirestore

/// One workout session. Stored at users/{uid}/workouts/{workoutId}.
/// Codable lets Firestore convert this struct to/from a document automatically.
struct Workout: Codable, Identifiable {
    @DocumentID var id: String?     // Firestore fills this with the document ID
    var userId: String
    var name: String
    var date: Date
    var notes: String

    init(id: String? = nil, userId: String, name: String = "", date: Date = Date(), notes: String = "") {
        self.id = id
        self.userId = userId
        self.name = name
        self.date = date
        self.notes = notes
    }
}
