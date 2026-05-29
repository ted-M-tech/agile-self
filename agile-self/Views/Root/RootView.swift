//
//  RootView.swift
//  agile-self
//
//  Root wrapper that gates onboarding vs main app.
//

import SwiftUI
import SwiftData

// MARK: - RootView

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.modelContext) private var modelContext

    /// One-shot deep-link flag: set true when the user finished onboarding via
    /// "Start First Check-in". MainTabView consumes it once on first appear to open
    /// the check-in, then clears it (so it never re-opens on later appears).
    @State private var openCheckInOnAppear = false

    var body: some View {
        ZStack {
            Theme.Colors.backgroundPrimary
                .ignoresSafeArea()

            if hasCompletedOnboarding {
                MainTabView(openCheckInOnAppear: $openCheckInOnAppear)
            } else {
                OnboardingContainerView { openCheckIn in
                    completeOnboarding(openCheckIn: openCheckIn)
                }
            }
        }
        .preferredColorScheme(.dark)
        .task {
            ensureDefaultRecords()
            WidgetSnapshotWriter.update(context: modelContext)
        }
    }

    /// SINGLE writer of the onboarding-complete state: flips the @AppStorage gate AND the
    /// persisted profile flag together (the profile flag is exported by DataManagement, so
    /// it must stay in sync with the gate and never diverge). Also records the check-in
    /// deep-link intent so MainTabView can open the check-in once on first appear.
    private func completeOnboarding(openCheckIn: Bool) {
        let descriptor = FetchDescriptor<UserProfile>()
        if let profile = try? modelContext.fetch(descriptor).first {
            profile.hasCompletedOnboarding = true
            try? modelContext.save()
        }
        openCheckInOnAppear = openCheckIn
        withAnimation(Theme.Animation.smooth) {
            hasCompletedOnboarding = true
        }
    }

    // MARK: - First Launch Setup

    /// Creates a default UserProfile and Streak if none exist yet.
    private func ensureDefaultRecords() {
        var didInsert = false

        let profileDescriptor = FetchDescriptor<UserProfile>()
        if (try? modelContext.fetch(profileDescriptor))?.isEmpty ?? true {
            modelContext.insert(UserProfile())
            didInsert = true
        }

        let streakDescriptor = FetchDescriptor<Streak>()
        if (try? modelContext.fetch(streakDescriptor))?.isEmpty ?? true {
            modelContext.insert(Streak())
            didInsert = true
        }

        // Persist immediately so onboarding (which fetches the singleton profile to
        // write displayName / notification prefs / hasCompletedOnboarding) sees it on disk.
        if didInsert {
            try? modelContext.save()
        }

        flipStressToCalmIfNeeded()
        migrateTo5PointScaleIfNeeded()
    }

    /// One-time backfill: legacy DailyCheckIn rows stored the OLD Stress axis (1 calm … 10
    /// overwhelmed, low = good). The axis is now Calm (high = good), so each legacy row's
    /// value is mirrored once. Guarded by UserDefaults so it runs exactly once, and skipped
    /// entirely under UI tests so seeded/in-memory test data is never double-flipped.
    private func flipStressToCalmIfNeeded() {
        guard !ProcessInfo.processInfo.arguments.contains("UITEST") else { return }

        let key = "didFlipStressToCalm.v1"
        guard !UserDefaults.standard.bool(forKey: key) else { return }

        let descriptor = FetchDescriptor<DailyCheckIn>()
        if let rows = try? modelContext.fetch(descriptor) {
            for row in rows {
                // one-time scale flip: calm = (scoreMin+scoreMax) - stress; legacy rows only
                row.stressScore = 11 - row.stressScore
            }
            try? modelContext.save()
        }

        UserDefaults.standard.set(true, forKey: key)
    }

    /// One-time backfill: the daily scale changed from 1–10 to 1–5. Each legacy axis value is
    /// down-mapped once with `new = max(1, min(5, Int((old / 2.0).rounded())))` so e.g. 10→5,
    /// 9→5(4.5→5), 5→3(2.5→3), 1→1(0.5→1). Runs AFTER the calm-flip guard (so it operates on
    /// already-calm-oriented values), guarded by UserDefaults so it runs exactly once, and
    /// skipped under UI tests so seeded/in-memory test data (already 1–5) is never re-scaled.
    private func migrateTo5PointScaleIfNeeded() {
        guard !ProcessInfo.processInfo.arguments.contains("UITEST") else { return }

        let key = "didMigrateTo5Point.v1"
        guard !UserDefaults.standard.bool(forKey: key) else { return }

        func toFive(_ old: Int) -> Int { max(1, min(5, Int((Double(old) / 2.0).rounded()))) }

        let descriptor = FetchDescriptor<DailyCheckIn>()
        if let rows = try? modelContext.fetch(descriptor) {
            for row in rows {
                row.energyScore = toFive(row.energyScore)
                row.focusScore = toFive(row.focusScore)
                row.stressScore = toFive(row.stressScore)
                row.growthScore = toFive(row.growthScore)
            }
            try? modelContext.save()
        }

        UserDefaults.standard.set(true, forKey: key)
    }
}

// MARK: - Preview

#Preview("Main App") {
    RootView()
        .modelContainer(MockData.previewContainer)
        .environment(AppContainer(modelContainer: MockData.previewContainer))
}

#Preview("Onboarding") {
    RootView()
        .modelContainer(MockData.previewContainer)
        .environment(AppContainer(modelContainer: MockData.previewContainer))
        .onAppear {
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        }
}
