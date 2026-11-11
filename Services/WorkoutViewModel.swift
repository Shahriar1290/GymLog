import Foundation
import FirebaseFirestore

/// Best (heaviest) lift ever logged for one exercise.
struct PersonalRecord: Identifiable {
    var id: String { name }
    let name: String
    let muscleGroup: String
    let weight: Double
    let reps: Int
    let date: Date
}

/// Totals for the current week.
struct WeeklySummary {
    var workouts = 0
    var sets = 0
    var volume = 0.0
}

/// Talks to Cloud Firestore: full CRUD for workouts and exercises of the signed-in user.
/// Structure: users/{uid}/workouts/{workoutId}/exercises/{exerciseId}
@MainActor
final class WorkoutViewModel: ObservableObject {
    @Published private(set) var workouts: [Workout] = []
    /// Exercises cached per workout ID, so Records and Weekly Summary can be computed.
    @Published private(set) var exercisesByWorkout: [String: [LoggedExercise]] = [:]
    @Published var isLoading = true
    @Published var errorMessage: String?

    private var db: Firestore { Firestore.firestore() }
    private var userId: String?
    private var workoutsListener: ListenerRegistration?
    private var exerciseListeners: [String: ListenerRegistration] = [:]

    // MARK: - Collection paths
    private func workoutsRef(_ uid: String) -> CollectionReference {
        db.collection("users").document(uid).collection("workouts")
    }
    private func exercisesRef(_ uid: String, _ workoutId: String) -> CollectionReference {
        workoutsRef(uid).document(workoutId).collection("exercises")
    }

    // MARK: - Start / stop listening (called from onAppear / onDisappear)

    func start(userId: String) {
        guard self.userId != userId else { return }
        stop()
        self.userId = userId
        isLoading = true
        // Snapshot listener = live updates: the closure runs now and again on every change.
        workoutsListener = workoutsRef(userId)
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                if let error {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    return
                }
                let documents = snapshot?.documents ?? []
                // data(as:) decodes a Firestore document into our Codable struct
                self.workouts = documents.compactMap { try? $0.data(as: Workout.self) }
                self.isLoading = false
                self.syncExerciseListeners()
            }
    }

    func stop() {
        workoutsListener?.remove()
        workoutsListener = nil
        exerciseListeners.values.forEach { $0.remove() }
        exerciseListeners = [:]
        workouts = []
        exercisesByWorkout = [:]
        userId = nil
    }

    /// Makes sure there is exactly one exercises-listener per existing workout.
    private func syncExerciseListeners() {
        guard let uid = userId else { return }
        let currentIds = Set(workouts.compactMap { $0.id })

        // Remove listeners of workouts that no longer exist
        for id in Array(exerciseListeners.keys) where !currentIds.contains(id) {
            exerciseListeners[id]?.remove()
            exerciseListeners[id] = nil
            exercisesByWorkout[id] = nil
        }
        // Add listeners for new workouts
        for id in currentIds where exerciseListeners[id] == nil {
            exerciseListeners[id] = exercisesRef(uid, id)
                .order(by: "date")
                .addSnapshotListener { [weak self] snapshot, error in
                    guard let self else { return }
                    if let error {
                        self.errorMessage = error.localizedDescription
                        return
                    }
                    let documents = snapshot?.documents ?? []
                    self.exercisesByWorkout[id] = documents.compactMap { try? $0.data(as: LoggedExercise.self) }
                }
        }
    }

    // MARK: - Workouts CRUD

    func addWorkout(_ workout: Workout) {
        guard let uid = userId else { return }
        var newWorkout = workout
        newWorkout.userId = uid
        do {
            // addDocument(from:) encodes the struct and lets Firestore create the ID
            try workoutsRef(uid).addDocument(from: newWorkout) { [weak self] error in
                if let error { self?.errorMessage = error.localizedDescription }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateWorkout(_ workout: Workout) {
        guard let uid = userId, let id = workout.id else { return }
        do {
            try workoutsRef(uid).document(id).setData(from: workout) { [weak self] error in
                if let error { self?.errorMessage = error.localizedDescription }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Firestore does not delete sub-collections automatically,
    /// so we delete the workout's exercises and the workout in one batch.
    func deleteWorkout(_ workout: Workout) {
        guard let uid = userId, let id = workout.id else { return }
        let batch = db.batch()
        for exercise in exercisesByWorkout[id] ?? [] {
            if let exerciseId = exercise.id {
                batch.deleteDocument(exercisesRef(uid, id).document(exerciseId))
            }
        }
        batch.deleteDocument(workoutsRef(uid).document(id))
        batch.commit { [weak self] error in
            if let error { self?.errorMessage = error.localizedDescription }
        }
    }

    // MARK: - Exercises CRUD

    func exercises(for workoutId: String) -> [LoggedExercise] {
        exercisesByWorkout[workoutId] ?? []
    }

    func addExercise(_ exercise: LoggedExercise, to workoutId: String) {
        guard let uid = userId else { return }
        do {
            try exercisesRef(uid, workoutId).addDocument(from: exercise) { [weak self] error in
                if let error { self?.errorMessage = error.localizedDescription }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateExercise(_ exercise: LoggedExercise, in workoutId: String) {
        guard let uid = userId, let id = exercise.id else { return }
        do {
            try exercisesRef(uid, workoutId).document(id).setData(from: exercise) { [weak self] error in
                if let error { self?.errorMessage = error.localizedDescription }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteExercise(_ exercise: LoggedExercise, from workoutId: String) {
        guard let uid = userId, let id = exercise.id else { return }
        exercisesRef(uid, workoutId).document(id).delete { [weak self] error in
            if let error { self?.errorMessage = error.localizedDescription }
        }
    }

    // MARK: - Computed statistics

    /// Every exercise the user has ever logged.
    private var allExercises: [LoggedExercise] {
        exercisesByWorkout.values.flatMap { $0 }
    }

    /// Personal records: heaviest weight per exercise name, heaviest first.
    var personalRecords: [PersonalRecord] {
        var best: [String: LoggedExercise] = [:]
        for exercise in allExercises where exercise.weight > 0 {
            if let current = best[exercise.name], current.weight >= exercise.weight { continue }
            best[exercise.name] = exercise
        }
        return best.values
            .map { PersonalRecord(name: $0.name, muscleGroup: $0.muscleGroup,
                                  weight: $0.weight, reps: $0.reps, date: $0.date) }
            .sorted { $0.weight > $1.weight }
    }

    /// Workouts, sets and volume (sets × reps × weight) for the current week.
    var weeklySummary: WeeklySummary {
        guard let week = Calendar.current.dateInterval(of: .weekOfYear, for: Date()) else {
            return WeeklySummary()
        }
        var summary = WeeklySummary()
        for workout in workouts where week.contains(workout.date) {
            summary.workouts += 1
            for exercise in exercisesByWorkout[workout.id ?? ""] ?? [] {
                summary.sets += exercise.sets
                summary.volume += exercise.volume
            }
        }
        return summary
    }
}
