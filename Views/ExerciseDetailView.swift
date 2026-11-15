import SwiftUI

/// Details of one library exercise (opened with a NavigationLink).
struct ExerciseDetailView: View {
    let exercise: LibraryExercise
    @EnvironmentObject private var workoutVM: WorkoutViewModel

    private var record: PersonalRecord? {
        workoutVM.personalRecords.first { $0.name == exercise.name }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.largeTitle)
                        .foregroundStyle(AppTheme.accent)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading) {
                        Text(exercise.name).font(.title2.bold())
                        Text(exercise.muscleGroup).foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Label("About", systemImage: "info.circle").font(.headline)
                    Text(exercise.description)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .card()

                VStack(alignment: .leading, spacing: 6) {
                    Label("Tips", systemImage: "lightbulb").font(.headline)
                    Text(exercise.tips)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .card()

                VStack(alignment: .leading, spacing: 6) {
                    Label("Your personal best", systemImage: "trophy").font(.headline)
                    if let record {
                        Text("\(record.weight.kgText) × \(record.reps) reps on \(record.date.formatted(date: .abbreviated, time: .omitted))")
                    } else {
                        Text("Not logged yet.").foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .card()
            }
            .padding()
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
