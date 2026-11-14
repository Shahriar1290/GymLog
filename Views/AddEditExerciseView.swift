import SwiftUI

/// Sheet for logging or editing one exercise (sets, reps, weight).
struct AddEditExerciseView: View {
    @Binding var exercise: LoggedExercise       // @Binding: edits the parent's draft
    let isNew: Bool
    let onSave: () -> Void

    @EnvironmentObject private var library: ExerciseLibraryLoader
    @Environment(\.dismiss) private var dismiss
    @State private var weightText = ""          // text typed in the weight field

    /// Parses "62.5" or "62,5". Empty means 0 (body-weight exercise).
    private var parsedWeight: Double? {
        let cleaned = weightText.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        if cleaned.isEmpty { return 0 }
        guard let value = Double(cleaned), value >= 0 else { return nil }
        return value
    }

    private var canSave: Bool { !exercise.name.isEmpty && parsedWeight != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise") {
                    if library.exercises.isEmpty {
                        Text("The exercise library could not be loaded.").foregroundStyle(.secondary)
                    } else {
                        // Picker: choose from the library; the tag is the exercise name
                        Picker("Exercise", selection: $exercise.name) {
                            ForEach(library.exercises) { item in
                                Text(item.name).tag(item.name)
                            }
                        }
                        Text("Muscle group: \(exercise.muscleGroup)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                Section("Sets & Reps") {
                    Stepper("Sets: \(exercise.sets)", value: $exercise.sets, in: 1...20)
                    Stepper("Reps: \(exercise.reps)", value: $exercise.reps, in: 1...100)
                }
                Section("Weight") {
                    TextField("Weight in kg (optional)", text: $weightText)
                        .keyboardType(.decimalPad)
                    if parsedWeight == nil {
                        Text("Enter a valid number, for example 62.5")
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(isNew ? "Add Exercise" : "Edit Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        exercise.weight = parsedWeight ?? 0
                        onSave()
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
            .onAppear {
                weightText = exercise.weight == 0 ? "" : String(format: "%g", exercise.weight)
                // New exercise: pre-select the first library item
                if exercise.name.isEmpty, let first = library.exercises.first {
                    exercise.name = first.name
                    exercise.muscleGroup = first.muscleGroup
                }
            }
            // Keep the muscle group in sync with the chosen exercise
            .onChange(of: exercise.name) { _, newName in
                if let match = library.exercises.first(where: { $0.name == newName }) {
                    exercise.muscleGroup = match.muscleGroup
                }
            }
        }
    }
}
