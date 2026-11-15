import SwiftUI

/// Searchable exercise library with a muscle-group filter.
struct ExerciseLibraryView: View {
    @EnvironmentObject private var library: ExerciseLibraryLoader
    @State private var searchText = ""
    @State private var selectedGroup = "All"

    private var filtered: [LibraryExercise] {
        library.exercises.filter { item in
            let groupMatches = selectedGroup == "All" || item.muscleGroup == selectedGroup
            let searchMatches = searchText.isEmpty
                || item.name.localizedCaseInsensitiveContains(searchText)
                || item.muscleGroup.localizedCaseInsensitiveContains(searchText)
            return groupMatches && searchMatches
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Muscle group", selection: $selectedGroup) {
                        ForEach(MuscleGroup.filters, id: \.self) { group in
                            Text(group).tag(group)
                        }
                    }
                    .pickerStyle(.menu)
                }
                Section {
                    if filtered.isEmpty {
                        EmptyStateView(icon: "magnifyingglass",
                                       title: "No exercises found",
                                       message: "Try a different search or muscle group.")
                    }
                    ForEach(filtered) { exercise in
                        NavigationLink {
                            ExerciseDetailView(exercise: exercise)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(exercise.name).font(.headline)
                                Text(exercise.muscleGroup)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Exercises")
            .searchable(text: $searchText, prompt: "Search exercises")
            .errorAlert(message: $library.errorMessage)
        }
    }
}
