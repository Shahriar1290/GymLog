import Foundation
import FirebaseFirestore

/// One exercise logged inside a workout.
/// Stored at users/{uid}/workouts/{workoutId}/exercises/{exerciseId}.
struct LoggedExercise: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var muscleGroup: String
    var sets: Int
    var reps: Int
    var weight: Double      // kilograms
    var date: Date

    init(id: String? = nil, name: String = "", muscleGroup: String = "",
         sets: Int = 3, reps: Int = 10, weight: Double = 0, date: Date = Date()) {
        self.id = id
        self.name = name
        self.muscleGroup = muscleGroup
        self.sets = sets
        self.reps = reps
        self.weight = weight
        self.date = date
    }

    /// sets × reps × weight (computed property, so it is NOT saved to Firestore)
    var volume: Double { Double(sets * reps) * weight }
}
