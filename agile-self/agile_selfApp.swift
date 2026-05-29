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
            #if DEBUG
            if !isUITest, launchArgs.contains("SEED_DEMO") {
                // Demo seeding into the PERSISTENT store: ~30 days of editable check-ins +
                // correlated health so trends/insights/connections/monthly report populate for a
                // live demo. Idempotent (skips days that already exist) → preserves today's real
                // check-in and any manual edits across re-launches. The seed is already in the
                // current 1–5 calm-oriented scale, so mark RootView's one-time scale migrations
                // done first — they must not re-flip/re-scale it. Land straight on the dashboard.
                UserDefaults.standard.set(true, forKey: "didFlipStressToCalm.v1")
                UserDefaults.standard.set(true, forKey: "didMigrateTo5Point.v1")
                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                Self.seedDemoHistory(into: container.mainContext)
            }
            #endif
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

        // A small mix of action items (varied priority/source/deadline, plus one completed) so
        // the Profile actions list renders populated for screenshots.
        context.insert(ActionItemV2(
            text: "Protect a 90-minute deep-work block tomorrow",
            deadline: cal.date(byAdding: .day, value: 2, to: today),
            priority: .high, source: .aiSuggested
        ))
        context.insert(ActionItemV2(
            text: "Walk 8,000 steps before noon",
            deadline: cal.date(byAdding: .day, value: 5, to: today),
            priority: .medium, source: .manual
        ))
        context.insert(ActionItemV2(
            text: "Read 10 pages before bed",
            priority: .low, source: .manual
        ))
        context.insert(ActionItemV2(
            text: "Go for a morning run",
            isCompleted: true,
            completedAt: cal.date(byAdding: .day, value: -1, to: today),
            priority: .medium, source: .aiSuggested
        ))

        try? context.save()
    }

    #if DEBUG
    /// Seeds ~30 days of plausible, EDITABLE check-ins (+ correlated health) into the PERSISTENT
    /// store for a live demo. Idempotent: only fills days that have no check-in yet, so today's
    /// real check-in and any manual edits survive re-launches. DEBUG-only; triggered by the
    /// `SEED_DEMO` launch argument. Everything seeded is a normal SwiftData row — editable and
    /// deletable from the app like any other check-in.
    private static func seedDemoHistory(into context: ModelContext) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let totalDays = 30

        // Days that already have data are skipped so real/edited rows are never overwritten.
        let existingCheckInDays = Set(
            ((try? context.fetch(FetchDescriptor<DailyCheckIn>())) ?? []).map { cal.startOfDay(for: $0.date) }
        )
        let existingHealthDays = Set(
            ((try? context.fetch(FetchDescriptor<HealthSnapshot>())) ?? []).map { cal.startOfDay(for: $0.date) }
        )

        // Deterministic 1–5 score: a gentle upward trend toward today + believable wobble (no RNG
        // so it's reproducible). `d` = 0 (oldest) … totalDays-1 (today).
        let wobble = [0, 1, -1, 0, 1, -1, 1, 0, -1, 1]
        func score(base: Double, d: Int, phase: Int) -> Int {
            let progress = Double(d) / Double(max(1, totalDays - 1))
            let w = Double(wobble[(d + phase) % wobble.count])
            return max(1, min(5, Int((base + progress * 1.4 + w * 0.8).rounded())))
        }

        var seeded = 0
        for i in 0 ..< totalDays {                                   // i = days ago (0 = today)
            guard let date = cal.date(byAdding: .day, value: -i, to: today) else { continue }
            let d = (totalDays - 1) - i                              // 0 oldest → rises to today

            let energy = score(base: 2.8, d: d, phase: 0)
            let focus = score(base: 2.6, d: d, phase: 3)
            let calm = score(base: 2.9, d: d, phase: 6)              // stored under stressScore
            let growth = score(base: 2.5, d: d, phase: 1)

            if !existingCheckInDays.contains(date) {
                context.insert(DailyCheckIn(
                    date: date, energyScore: energy, focusScore: focus,
                    stressScore: calm, growthScore: growth, note: nil
                ))
                seeded += 1
            }

            // Correlated health for PAST days only (today's is owned by the live HealthKit fetch).
            if i >= 1, !existingHealthDays.contains(date) {
                let w = wobble[(d + 4) % wobble.count]
                context.insert(HealthSnapshot(
                    date: date,
                    sleepMinutes: 300 + focus * 36 + w * 8,          // tracks Focus
                    steps: 3000 + energy * 1500 + w * 300,           // tracks Energy
                    activeCalories: 200 + energy * 60,
                    exerciseMinutes: max(0, growth * 12 + w * 4),    // tracks Growth
                    restingHeartRate: 74 - calm * 3 + w,             // lower when calmer
                    runningDistanceMeters: Double(focus * 900 + w * 150)
                ))
            }
        }

        // Reflect the seeded history in the single Streak row (upsert).
        if let streak = (try? context.fetch(FetchDescriptor<Streak>()))?.first {
            streak.currentStreak = max(streak.currentStreak, totalDays)
            streak.longestStreak = max(streak.longestStreak, totalDays)
            streak.lastCheckInDate = today
            streak.totalCheckIns = max(streak.totalCheckIns, totalDays)
        } else {
            context.insert(Streak(
                currentStreak: totalDays, longestStreak: totalDays,
                lastCheckInDate: today, totalCheckIns: totalDays
            ))
        }

        try? context.save()
        print("SEED_DEMO: inserted \(seeded) new check-in day(s) for a ~\(totalDays)-day history.")
    }
    #endif

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
