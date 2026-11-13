import SwiftUI

/// Weekly summary + the 5 most recent workouts + "Add Workout".
struct HomeView: View {
    @EnvironmentObject private var workoutVM: WorkoutViewModel
    @EnvironmentObject private var auth: AuthViewModel

    @State private var showingAdd = false
    @State private var draft = Workout(userId: "")     // the workout being created (passed as @Binding)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    weeklySummarySection

                    Button {
                        draft = Workout(userId: auth.userId ?? "")
                        showingAdd = true
                    } label: {
                        Label("Add Workout", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .accessibilityLabel("Add workout")

                    Text("Recent Workouts").font(.headline)
                    recentSection
                }
                .padding()
            }
            .navigationTitle("GymLog")
            .sheet(isPresented: $showingAdd) {
                AddEditWorkoutView(workout: $draft, isNew: true) {
                    workoutVM.addWorkout(draft)
                }
            }
        }
    }

    private var weeklySummarySection: some View {
        let summary = workoutVM.weeklySummary
        return VStack(alignment: .leading, spacing: 10) {
            Text("This Week").font(.headline)
            HStack(spacing: 12) {
                SummaryCard(title: "Workouts", value: "\(summary.workouts)", icon: "figure.strengthtraining.traditional")
                SummaryCard(title: "Sets", value: "\(summary.sets)", icon: "list.number")
                SummaryCard(title: "Volume", value: "\(Int(summary.volume)) kg", icon: "scalemass.fill")
            }
        }
    }

    @ViewBuilder
    private var recentSection: some View {
        if workoutVM.isLoading {
            ProgressView().frame(maxWidth: .infinity)
        } else if workoutVM.workouts.isEmpty {
            EmptyStateView(icon: "figure.run",
                           title: "No workouts yet",
                           message: "Tap “Add Workout” to log your first session.")
        } else {
            ForEach(Array(workoutVM.workouts.prefix(5))) { workout in
                NavigationLink {
                    WorkoutDetailView(workout: workout)
                } label: {
                    WorkoutRow(workout: workout,
                               exerciseCount: workoutVM.exercises(for: workout.id ?? "").count)
                        .card()
                }
                .buttonStyle(.plain)
            }
        }
    }
}
