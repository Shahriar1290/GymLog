import Foundation

/// Loads the built-in exercise library from exercises.json (JSON parsing with Codable).
@MainActor
final class ExerciseLibraryLoader: ObservableObject {
    @Published var exercises: [LibraryExercise] = []
    @Published var errorMessage: String?

    func load() {
        guard exercises.isEmpty else { return }     // only load once
        // 1. Find the file inside the app bundle
        guard let url = Bundle.main.url(forResource: "exercises", withExtension: "json") else {
            errorMessage = "exercises.json was not found in the app bundle."
            return
        }
        do {
            // 2. Read the bytes, 3. decode them into [LibraryExercise]
            let data = try Data(contentsOf: url)
            exercises = try JSONDecoder().decode([LibraryExercise].self, from: data)
        } catch {
            errorMessage = "Could not read exercises.json: \(error.localizedDescription)"
        }
    }
}
