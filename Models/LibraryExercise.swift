import Foundation

/// One entry of the built-in exercise library (decoded from exercises.json).
struct LibraryExercise: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let muscleGroup: String
    let description: String
    let tips: String
}

/// Options for the muscle-group filter Picker.
enum MuscleGroup {
    static let filters = ["All", "Chest", "Back", "Legs", "Shoulders", "Arms", "Core"]
}
