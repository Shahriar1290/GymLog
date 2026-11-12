import SwiftUI

/// App-wide colours in one place.
enum AppTheme {
    static let accent = Color.orange
}

// MARK: - Reusable modifiers

/// Rounded "card" background that adapts to light and dark mode.
struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

extension View {
    func card() -> some View { modifier(CardModifier()) }

    /// Shows an alert whenever `message` is not nil. Tapping OK sets it back to nil.
    /// A Binding<String?> is passed in, so the alert can clear the owner's value.
    func errorAlert(message: Binding<String?>) -> some View {
        alert("Something went wrong",
              isPresented: Binding(get: { message.wrappedValue != nil },
                                   set: { if !$0 { message.wrappedValue = nil } })) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(message.wrappedValue ?? "")
        }
    }
}

extension Double {
    /// 60 -> "60 kg", 62.5 -> "62.5 kg"
    var kgText: String {
        "\(self.formatted(.number.precision(.fractionLength(0...1)))) kg"
    }
}

// MARK: - Small reusable views

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(AppTheme.accent)
                .accessibilityHidden(true)
            Text(value)
                .font(.title3.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .card()
        .accessibilityElement(children: .combine)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text(title).font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
    }
}

struct WorkoutRow: View {
    let workout: Workout
    let exerciseCount: Int

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "dumbbell.fill")
                .foregroundStyle(AppTheme.accent)
                .frame(width: 30)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(workout.name).font(.headline)
                Text(workout.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(exerciseCount) exercise\(exerciseCount == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
    }
}

struct ExerciseRow: View {
    let exercise: LoggedExercise

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name).font(.headline)
                Text(exercise.muscleGroup).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(exercise.sets) × \(exercise.reps) @ \(exercise.weight.kgText)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
    }
}
