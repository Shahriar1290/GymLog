import SwiftUI

/// Personal records: heaviest weight ever logged for each exercise.
struct RecordsView: View {
    @EnvironmentObject private var workoutVM: WorkoutViewModel

    var body: some View {
        NavigationStack {
            Group {
                if workoutVM.isLoading {
                    ProgressView("Loading…")
                } else if workoutVM.personalRecords.isEmpty {
                    EmptyStateView(icon: "trophy",
                                   title: "No records yet",
                                   message: "Log exercises with a weight to see your personal bests.")
                } else {
                    List(workoutVM.personalRecords) { record in
                        HStack {
                            Image(systemName: "trophy.fill")
                                .foregroundStyle(AppTheme.accent)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(record.name).font(.headline)
                                Text("\(record.muscleGroup) · \(record.date.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(record.weight.kgText).font(.headline)
                                Text("\(record.reps) reps").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
            .navigationTitle("Records")
        }
    }
}
