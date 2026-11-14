import SwiftUI

/// Sheet for creating or editing a workout.
/// @Binding = this view does not own the workout; it edits the parent's copy directly.
struct AddEditWorkoutView: View {
    @Binding var workout: Workout
    let isNew: Bool
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss

    private var trimmedName: String {
        workout.name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Workout") {
                    TextField("Name (e.g. Push Day)", text: $workout.name)
                    DatePicker("Date", selection: $workout.date)
                }
                Section("Notes") {
                    TextField("Notes (optional)", text: $workout.notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(isNew ? "New Workout" : "Edit Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        workout.name = trimmedName
                        onSave()
                        dismiss()
                    }
                    .disabled(trimmedName.isEmpty)
                }
            }
        }
    }
}
