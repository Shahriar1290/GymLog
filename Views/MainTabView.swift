import SwiftUI

/// The signed-in part of the app. Every tab holds its own NavigationStack.
struct MainTabView: View {
    @EnvironmentObject private var auth: AuthViewModel
    // @StateObject: this view CREATES and OWNS these objects.
    @StateObject private var workoutVM = WorkoutViewModel()
    @StateObject private var library = ExerciseLibraryLoader()

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
            ExerciseLibraryView()
                .tabItem { Label("Library", systemImage: "books.vertical.fill") }
            RecordsView()
                .tabItem { Label("Records", systemImage: "trophy.fill") }
            HistoryView()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        // @EnvironmentObject: inject once here, every child tab can read them.
        .environmentObject(workoutVM)
        .environmentObject(library)
        // onAppear: start loading data. onDisappear: stop the Firestore listeners.
        .onAppear {
            if let uid = auth.userId { workoutVM.start(userId: uid) }
            library.load()
        }
        .onDisappear { workoutVM.stop() }
        .errorAlert(message: $workoutVM.errorMessage)
    }
}
