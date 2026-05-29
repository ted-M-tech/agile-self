//
//  agile_selfApp.swift
//  agile-self
//
//  Created by Tetsuya Maeda on 2025/11/30.
//

import SwiftUI
import SwiftData

@main
struct agile_selfApp: App {
    private let sharedModelContainer: ModelContainer?
    private let appContainer: AppContainer?

    init() {
        // Versioned schema (V1) — stable migration foundation. See AppSchema.swift.
        let schema = Schema(versionedSchema: AppSchemaV1.self)

        // UI-test launch seam (XCUITest only). `UITEST` → ephemeral in-memory store so every
        // run starts from a known-empty state with no disk pollution / migration risk;
        // `UITEST_ONBOARDED` (used with UITEST) → land directly on MainTabView, otherwise the
        // run starts at onboarding. Real device/launch behavior is untouched (flag left alone).
        let launchArgs = ProcessInfo.processInfo.arguments
        let isUITest = launchArgs.contains("UITEST")
        if isUITest {
            UserDefaults.standard.set(launchArgs.contains("UITEST_ONBOARDED"), forKey: "hasCompletedOnboarding")
        }

        // CloudKit is disabled for the free-account device build (no paid Apple
        // Developer Program → no iCloud container). `.automatic` without an iCloud
        // entitlement crashes/sync-fails on device. Re-enable in M6 after enrolling.
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: isUITest,
            cloudKitDatabase: .none
        )

        do {
            let container = try ModelContainer(
                for: schema,
                migrationPlan: AppMigrationPlan.self,
                configurations: [modelConfiguration]
            )
            self.sharedModelContainer = container
            if isUITest, launchArgs.contains("UITEST_SEED") {
                Self.seedSampleData(into: container.mainContext)
            }
            let app = AppContainer(modelContainer: container)
            self.appContainer = app
            app.refreshCloudAIPreference(context: container.mainContext)
            app.watchConnectivityService.activate()
            Task { await app.refreshSubscriptionState() }
        } catch {
            self.sharedModelContainer = nil
            self.appContainer = nil
            print("Could not create ModelContainer: \(error)")
        }
    }

    /// Seeds 8 ascending days of check-ins into an (in-memory) UI-test store so screens can be
    /// screenshotted in a populated state without manual tapping. UI-test only.
    private static func seedSampleData(into context: ModelContext) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        // Tuples are (energy, focus, calm, growth) — all 1-5, higher = better. The 3rd value
        // is Calm (high = calm/good) and is stored under stressScore. Ascending good days so
        // the Home trend chart rises toward today.
        let days: [(Int, Int, Int, Int)] = [
            (3, 3, 2, 3), (3, 3, 4, 3), (2, 2, 2, 3), (4, 4, 4, 4),
            (3, 3, 3, 3), (4, 4, 4, 4), (4, 4, 4, 5), (5, 4, 5, 5),
        ]
        for (i, s) in days.enumerated() {
            let date = cal.date(byAdding: .day, value: -(days.count - 1 - i), to: today) ?? today
            context.insert(DailyCheckIn(
                date: date, energyScore: s.0, focusScore: s.1, stressScore: s.2, growthScore: s.3, note: nil
            ))

            // Seed a matching HealthSnapshot whose metrics are CORRELATED with that day's
            // scores, so AnalyticsService finds >=5 matched pairs and surfaces real correlations:
            //   - sleep tracks Focus (more sleep on higher-Focus days)
            //   - steps track Energy
            //   - exercise tracks Growth
            //   - resting heart rate inversely tracks Calm (lower HR on calmer days)
            // Higher scores → "better" health values, with small per-day jitter so the Pearson
            // coefficients clear the |r| >= 0.3 gate without being a perfect 1.0 line.
            let jitter = (i % 3) - 1                              // -1, 0, +1 cycle
            let sleepMinutes = 300 + s.1 * 36 + jitter * 8        // ~336–516 min, tracks Focus
            let steps = 3000 + s.0 * 1500 + jitter * 300          // tracks Energy
            let exerciseMinutes = max(0, s.3 * 12 + jitter * 4)   // tracks Growth
            let restingHeartRate = 74 - s.2 * 3 + jitter          // lower on calmer days
            let runningMeters = Double(s.1 * 900 + jitter * 150)  // tracks Focus

            context.insert(HealthSnapshot(
                date: date,
                sleepMinutes: sleepMinutes,
                steps: steps,
                activeCalories: 200 + s.0 * 60,
                exerciseMinutes: exerciseMinutes,
                restingHeartRate: restingHeartRate,
                runningDistanceMeters: runningMeters
            ))
        }

        // Seed a Streak consistent with the 8 consecutive seeded days so the Insights/Profile
        // streak cards render a populated state (StreakService.fetchOrCreateStreak reuses this).
        context.insert(Streak(
            currentStreak: days.count,
            longestStreak: days.count,
            lastCheckInDate: today,
            totalCheckIns: days.count
        ))

        try? context.save()
    }

    var body: some Scene {
        WindowGroup {
            if let container = sharedModelContainer, let appContainer {
                RootView()
                    .modelContainer(container)
                    .environment(appContainer)
            } else {
                DatabaseErrorView()
            }
        }
    }
}

// MARK: - Database Error View

struct DatabaseErrorView: View {
    var body: some View {
        ZStack {
            Theme.Colors.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: Theme.Spacing.lg) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Theme.Colors.warning)

                Text("Unable to Load Data")
                    .font(Theme.Typography.title2)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text("There was a problem loading your data. Please try restarting the app.")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.xl)

                Text("Please close and reopen the app to try again.")
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.Colors.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.xl)
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }
}
