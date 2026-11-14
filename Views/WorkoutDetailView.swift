import SwiftUI

/// Shows one workout with its exercises. Add / edit / delete exercises here.
struct WorkoutDetailView: View {
    @EnvironmentObject private var workoutVM: WorkoutViewModel
    @Environment(\.dismiss) private var dismiss

    let workout: Workout        // the workout this screen was opened for

    @State private var workoutDraft = Workout(userId: "")
    @State private var showEditWorkout = false
    @State private var exerciseDraft = LoggedExercise()
    @State private var isNewExercise = true
    @State private var showExerciseSheet = false
    @State private var showDeleteConfirm = false

    /// Always the latest version from Firestore (so edits show immediately).
    private var current: Workout {
        workoutVM.workouts.first { $0.id == workout.id } ?? workout
    }
    private var workoutId: String { workout.id ?? "" }
    private var exercises: [LoggedExercise] { workoutVM.exercises(for: workoutId) }

    var body: some View {
        List {
            Section("Details") {
                LabeledContent("Date", value: current.date.formatted(date: .abbreviated, time: .shortened))
                if !current.notes.isEmpty {
                    Text(current.notes)
                }
            }

            Section {
                NavigationLink {
                    RestTimerView()
                } label: {
                    Label("Rest Timer", systemImage: "timer")
                }
            }

            Section("Exercises") {
                if exercises.isEmpty {
                    Text("No exercises yet. Tap + to add one.")
                        .foregroundStyle(.secondary)
                }
                ForEach(exercises) { exercise in
                    Button {
                        startEditExercise(exercise)
                    } label: {
                        ExerciseRow(exercise: exercise)
                    }
                    .buttonStyle(.plain)
                }
                .onDelete(perform: deleteExercises)     // swipe to delete
            }

            Section {
                Button("Delete Workout", role: .destructive) { showDeleteConfirm = true }
            }
        }
        .navigationTitle(current.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    workoutDraft = current
                    showEditWorkout = true
                } label: {
                    Image(systemName: "pencil")
                }
                .accessibilityLabel("Edit workout")

                Button {
                    exerciseDraft = LoggedExercise(date: current.date)
                    isNewExercise = true
                    showExerciseSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add exercise")
            }
        }
        .sheet(isPresented: $showEditWorkout) {
            AddEditWorkoutView(workout: $workoutDraft, isNew: false) {
                workoutVM.updateWorkout(workoutDraft)
            }
        }
        .sheet(isPresented: $showExerciseSheet) {
            AddEditExerciseView(exercise: $exerciseDraft, isNew: isNewExercise) {
                if isNewExercise {
                    workoutVM.addExercise(exerciseDraft, to: workoutId)
                } else {
                    workoutVM.updateExercise(exerciseDraft, in: workoutId)
                }
            }
        }
        .confirmationDialog("Delete this workout and all its exercises?",
                            isPresented: $showDeleteConfirm,
                            titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                workoutVM.deleteWorkout(current)
                dismiss()
            }
        }
    }

    private func startEditExercise(_ exercise: LoggedExercise) {
        exerciseDraft = exercise
        isNewExercise = false
        showExerciseSheet = true
    }

    private func deleteExercises(at offsets: IndexSet) {
        let list = exercises
        for index in offsets {
            workoutVM.deleteExercise(list[index], from: workoutId)
        }
    }
}
