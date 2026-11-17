import SwiftUI

/// All workouts grouped by day, newest first. Tap to open, swipe to delete.
struct HistoryView: View {
    @EnvironmentObject private var workoutVM: WorkoutViewModel

    /// Groups workouts by the start of their day.
    private var grouped: [Date: [Workout]] {
        Dictionary(grouping: workoutVM.workouts) { Calendar.current.startOfDay(for: $0.date) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if workoutVM.isLoading {
                    ProgressView("Loading…")
                } else if workoutVM.workouts.isEmpty {
                    EmptyStateView(icon: "clock",
                                   title: "No workouts yet",
                                   message: "Your finished workouts will appear here.")
                } else {
                    historyList
                }
            }
            .navigationTitle("History")
        }
    }

    private var historyList: some View {
        let groups = grouped
        let days = groups.keys.sorted(by: >)        // newest day first
        return List {
            ForEach(days, id: \.self) { day in
                let items = groups[day] ?? []
                Section(day.formatted(date: .complete, time: .omitted)) {
                    ForEach(items) { workout in
                        NavigationLink {
                            WorkoutDetailView(workout: workout)
                        } label: {
                            WorkoutRow(workout: workout,
                                       exerciseCount: workoutVM.exercises(for: workout.id ?? "").count)
                        }
                    }
                    .onDelete { offsets in
                        for index in offsets { workoutVM.deleteWorkout(items[index]) }
                    }
                }
            }
        }
    }
}
