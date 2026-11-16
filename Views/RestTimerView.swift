import SwiftUI
import UIKit

/// Holds the countdown logic. Kept in a small class so the Timer can be started and invalidated safely.
@MainActor
final class RestTimerEngine: ObservableObject {
    @Published var duration = 60        // chosen preset (seconds)
    @Published var remaining = 60       // seconds left
    @Published var isRunning = false

    private var timer: Timer?

    /// 1.0 = full ring, 0.0 = empty ring
    var progress: Double {
        duration == 0 ? 0 : Double(remaining) / Double(duration)
    }

    func start() {
        guard !isRunning else { return }
        if remaining <= 0 { remaining = duration }
        isRunning = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    /// Pause = stop the Timer. invalidate() removes it from the run loop so it never leaks.
    func pause() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    func reset() {
        pause()
        remaining = duration
    }

    func setDuration(_ seconds: Int) {
        let wasRunning = isRunning
        pause()
        duration = seconds
        remaining = seconds
        if wasRunning { start() }
    }

    private func tick() {
        guard remaining > 0 else { return }
        remaining -= 1
        if remaining == 0 {
            pause()
            UINotificationFeedbackGenerator().notificationOccurred(.success)   // buzz when finished
        }
    }
}

/// Rest timer screen with a progress ring.
struct RestTimerView: View {
    @StateObject private var engine = RestTimerEngine()
    private let presets = [30, 60, 90, 120]

    var body: some View {
        VStack(spacing: 28) {
            Picker("Duration", selection: Binding(get: { engine.duration },
                                                  set: { engine.setDuration($0) })) {
                ForEach(presets, id: \.self) { seconds in
                    Text("\(seconds)s").tag(seconds)
                }
            }
            .pickerStyle(.segmented)

            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 14)
                Circle()
                    .trim(from: 0, to: engine.progress)
                    .stroke(AppTheme.accent, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: engine.remaining)
                Text(timeString)
                    .font(.system(size: 54, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }
            .frame(width: 240, height: 240)
            .padding(.top, 20)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(engine.remaining) seconds remaining")

            HStack(spacing: 16) {
                Button {
                    if engine.isRunning { engine.pause() } else { engine.start() }
                } label: {
                    Label(engine.isRunning ? "Pause" : "Start",
                          systemImage: engine.isRunning ? "pause.fill" : "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    engine.reset()
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .controlSize(.large)

            Spacer()
        }
        .padding()
        .navigationTitle("Rest Timer")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { engine.start() }        // start counting as soon as the screen appears
        .onDisappear { engine.pause() }     // invalidate the Timer when leaving the screen
    }

    private var timeString: String {
        String(format: "%02d:%02d", engine.remaining / 60, engine.remaining % 60)
    }
}
