//
//  M1RegressionTests.swift
//  agile-selfTests
//
//  Regression tests for the M1 fixes: WCSession replyHandler (#30),
//  check-in upsert (#6), date-based Insights filtering (#14), note sentiment
//  (#21), AIServiceRouter wiring (#9), and the versioned schema (#12).
//

import Testing
import Foundation
import SwiftData
@testable import agile_self

// MARK: - Helpers

@MainActor
private func makeInMemoryContainer() throws -> ModelContainer {
    let schema = Schema([
        DailyCheckIn.self,
        HealthSnapshot.self,
        WeeklyReview.self,
        MonthlyReport.self,
        ActionItemV2.self,
        UserProfile.self,
        Streak.self,
    ])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
    return try ModelContainer(for: schema, configurations: [config])
}

/// Main-actor box to count replyHandler invocations.
@MainActor
private final class CallBox {
    var count = 0
}

private func utcGregorian() -> Calendar {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "UTC")!
    return cal
}

// MARK: - TimePeriod date filtering (#14)

struct TimePeriodFilteringTests {

    @Test
    func windowDaysMapping() {
        #expect(TimePeriod.week.windowDays == 7)
        #expect(TimePeriod.month.windowDays == 30)
        #expect(TimePeriod.quarter.windowDays == 90)
        #expect(TimePeriod.year.windowDays == nil)
    }

    @Test
    func weekStartIsSixDaysBeforeInclusive() {
        let cal = utcGregorian()
        let ref = cal.date(from: DateComponents(year: 2026, month: 5, day: 28))!
        let start = TimePeriod.week.startDate(relativeTo: ref, calendar: cal)
        let expected = cal.startOfDay(for: cal.date(from: DateComponents(year: 2026, month: 5, day: 22))!)
        #expect(start == expected)
    }

    @Test
    func yearHasNoLowerBound() {
        let cal = utcGregorian()
        let ref = cal.date(from: DateComponents(year: 2026, month: 5, day: 28))!
        #expect(TimePeriod.year.startDate(relativeTo: ref, calendar: cal) == nil)
    }

    @MainActor
    @Test
    func weekFilterExcludesSparseOldCheckIns() {
        let vm = InsightsViewModel()
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let within = DailyCheckIn(date: cal.date(byAdding: .day, value: -2, to: today)!)
        let outside = DailyCheckIn(date: cal.date(byAdding: .day, value: -20, to: today)!)
        vm.allCheckIns = [outside, within]

        vm.selectedPeriod = .week
        #expect(vm.filteredCheckIns.count == 1)
        #expect(vm.filteredCheckIns.first?.id == within.id)

        vm.selectedPeriod = .year
        #expect(vm.filteredCheckIns.count == 2)
    }
}

// MARK: - Same-day check-in upsert (#6)
//
// CheckInViewModel was removed (dead code — the real save path lives in
// DailyCheckInView, which is a SwiftUI View). The same-day upsert contract is now
// verified through the shared persistence seam, WatchConnectivityService.handleCheckIn,
// which mirrors DailyCheckInView.saveCheckIn (fetch-by-start-of-day, then update-or-insert).

@MainActor
struct SameDayUpsertTests {

    @Test
    func savingTwiceSameDayKeepsOneRow() async throws {
        let container = try makeInMemoryContainer()
        let service = WatchConnectivityService(modelContainer: container)
        let context = container.mainContext

        _ = await withCheckedContinuation { continuation in
            service.handleCheckIn(["type": "checkIn", "energy": 8, "focus": 7, "stress": 3, "growth": 9]) { reply in
                continuation.resume(returning: reply)
            }
        }
        #expect(try context.fetch(FetchDescriptor<DailyCheckIn>()).count == 1)

        // Second save on the same day must UPDATE, not insert a duplicate.
        _ = await withCheckedContinuation { continuation in
            service.handleCheckIn(["type": "checkIn", "energy": 5, "focus": 5, "stress": 5, "growth": 5]) { reply in
                continuation.resume(returning: reply)
            }
        }

        let rows = try context.fetch(FetchDescriptor<DailyCheckIn>())
        #expect(rows.count == 1)
        #expect(rows.first?.energyScore == 5)
    }
}

// MARK: - WatchConnectivity replyHandler (#30)

@MainActor
struct WatchConnectivityReplyTests {

    @Test
    func validMessageRepliesWithScore() async throws {
        let container = try makeInMemoryContainer()
        let service = WatchConnectivityService(modelContainer: container)

        let reply: [String: Any] = await withCheckedContinuation { continuation in
            service.handleCheckIn(["type": "checkIn", "energy": 7, "focus": 8, "stress": 3, "growth": 6]) { reply in
                continuation.resume(returning: reply)
            }
        }
        #expect(reply["compositeScore"] as? Double != nil)
        #expect(!reply.keys.contains("error"))
    }

    @Test
    func missingFieldsStillRepliesWithError() async throws {
        let container = try makeInMemoryContainer()
        let service = WatchConnectivityService(modelContainer: container)
        let box = CallBox()

        let reply: [String: Any] = await withCheckedContinuation { continuation in
            // Missing "growth"
            service.handleCheckIn(["type": "checkIn", "energy": 7, "focus": 8, "stress": 3]) { reply in
                box.count += 1
                continuation.resume(returning: reply)
            }
        }
        #expect(box.count == 1)
        #expect(reply["error"] as? Bool == true)
    }
}

// MARK: - On-device sentiment (#21)

struct OnDeviceSentimentTests {

    @Test
    func sentimentIsInValidRange() {
        let score = OnDeviceAIService().analyzeSentiment("I had a wonderful, productive, energizing day.")
        #expect(score >= -1.0)
        #expect(score <= 1.0)
    }

    @Test
    func emptyNoteSentimentIsZero() {
        #expect(OnDeviceAIService().analyzeSentiment("") == 0.0)
    }
}

// MARK: - AIServiceRouter wiring (#9)

@MainActor
struct AIServiceRouterTests {

    private func makeRouter() -> AIServiceRouter {
        AIServiceRouter(onDeviceService: OnDeviceAIService(), geminiService: GeminiAIService())
    }

    @Test
    func dailyInsightIsNonEmpty() async throws {
        let insight = try await makeRouter().generateDailyInsight(checkIn: DailyCheckIn())
        #expect(!insight.isEmpty)
    }

    @Test
    func patternsHandleInsufficientData() async throws {
        let patterns = try await makeRouter().generatePatterns(from: [DailyCheckIn()])
        #expect(!patterns.isEmpty)
    }

    @Test
    func cloudPreferenceDefaultsOffAndReadsProfile() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let router = makeRouter()
        #expect(router.allowCloudAI == false)

        context.insert(UserProfile(allowCloudAI: true))
        try context.save()
        router.updateCloudAIPreference(from: context)
        #expect(router.allowCloudAI == true)
    }
}

// MARK: - Foundation Models fallback contract (M3)

@MainActor
struct FoundationModelsFallbackTests {

    // On the simulator / hosts without Apple Intelligence the model is unavailable, so
    // every FoundationModelsAIService method must degrade to the OnDeviceAIService
    // heuristics — non-empty, well-formed output, no crash. These assert the deterministic
    // fallback path only (never LLM-generated text).

    @Test
    func dailyInsightFallsBackNonEmpty() async throws {
        let insight = try await FoundationModelsAIService().generateDailyInsight(checkIn: DailyCheckIn())
        #expect(!insight.isEmpty)
    }

    @Test
    func patternsPreserveInsufficientDataGuard() async throws {
        let patterns = try await FoundationModelsAIService().generatePatterns(from: [DailyCheckIn()])
        #expect(patterns == ["Need at least 7 days of data to discover patterns."])
    }

    @Test
    func weeklySummaryFallsBackNonEmpty() async throws {
        let result = try await FoundationModelsAIService().generateWeeklySummary(conversation: [], checkIns: [DailyCheckIn()])
        #expect(!result.summary.isEmpty)
    }

    @Test
    func monthlyReportNumbersAreDeterministic() async throws {
        let checkIns: [DailyCheckIn] = []
        let health: [HealthSnapshot] = []
        let result = try await FoundationModelsAIService().generateMonthlyReport(checkIns: checkIns, health: health)
        // Correlation is not Equatable, so compare count against the deterministic source.
        let expected = AnalyticsService().detectCorrelations(checkIns: checkIns, health: health)
        #expect(result.correlations.count == expected.count)
        // avgComposite for empty check-ins is 3.0 — the LLM never alters this number.
        #expect(result.overallScore == 3.0)
    }
}

// MARK: - Versioned schema foundation (#12)

@MainActor
struct VersionedSchemaTests {

    @Test
    func v1EnumeratesSevenModels() {
        #expect(AppSchemaV1.models.count == 7)
        #expect(AppSchemaV1.versionIdentifier == Schema.Version(1, 0, 0))
        #expect(AppMigrationPlan.schemas.count == 1)
        #expect(AppMigrationPlan.stages.isEmpty)
    }

    @Test
    func containerBuildsAndRoundTripsUnderVersionedSchema() throws {
        let schema = Schema(versionedSchema: AppSchemaV1.self)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: schema, migrationPlan: AppMigrationPlan.self, configurations: [config])
        let context = container.mainContext
        context.insert(DailyCheckIn(energyScore: 4))
        try context.save()
        let rows = try context.fetch(FetchDescriptor<DailyCheckIn>())
        #expect(rows.count == 1)
        #expect(rows.first?.energyScore == 4)
    }
}

// MARK: - Mood ↔ Health connections (core differentiator)

/// Deterministic coverage of `generateConnections` / `generateTodayConnection`. The OnDevice
/// heuristic carries the real numbers (via ConnectionNarrator + AnalyticsService) and has no LLM
/// dependency, so these run identically everywhere. The dataset mirrors the UITEST_SEED logic so
/// the asserts double as a guarantee that seeded correlations actually surface.
@MainActor
struct MoodHealthConnectionTests {

    /// Builds 8 days of check-ins + correlated HealthSnapshots, matching `seedSampleData`.
    private func makeDataset() -> (checkIns: [DailyCheckIn], health: [HealthSnapshot]) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let days: [(Int, Int, Int, Int)] = [
            (3, 3, 2, 3), (3, 3, 4, 3), (2, 2, 2, 3), (4, 4, 4, 4),
            (3, 3, 3, 3), (4, 4, 4, 4), (4, 4, 4, 5), (5, 4, 5, 5),
        ]
        var checkIns: [DailyCheckIn] = []
        var health: [HealthSnapshot] = []
        for (i, s) in days.enumerated() {
            let date = cal.date(byAdding: .day, value: -(days.count - 1 - i), to: today) ?? today
            checkIns.append(DailyCheckIn(
                date: date, energyScore: s.0, focusScore: s.1, stressScore: s.2, growthScore: s.3
            ))
            let jitter = (i % 3) - 1
            health.append(HealthSnapshot(
                date: date,
                sleepMinutes: 300 + s.1 * 36 + jitter * 8,
                steps: 3000 + s.0 * 1500 + jitter * 300,
                activeCalories: 200 + s.0 * 60,
                exerciseMinutes: max(0, s.3 * 12 + jitter * 4),
                restingHeartRate: 74 - s.2 * 3 + jitter,
                runningDistanceMeters: Double(s.1 * 900 + jitter * 150)
            ))
        }
        return (checkIns, health)
    }

    @Test
    func seededDatasetSurfacesCorrelations() {
        let (checkIns, health) = makeDataset()
        let correlations = AnalyticsService().detectCorrelations(checkIns: checkIns, health: health)
        // Seed values are engineered so the |r| >= 0.3 gate is comfortably cleared on multiple axes.
        #expect(correlations.count >= 3)
    }

    @Test
    func connectionsAreNarratedAndHonest() async throws {
        let (checkIns, health) = makeDataset()
        let connections = try await OnDeviceAIService().generateConnections(checkIns: checkIns, health: health)

        #expect(!connections.isEmpty)
        #expect(connections.count <= 3)
        for sentence in connections {
            #expect(!sentence.isEmpty)
            // HONESTY: correlational language only — never causal.
            let lower = sentence.lowercased()
            #expect(!lower.contains("caused"))
            #expect(!lower.contains("because"))
            #expect(lower.contains("tends to") || lower.contains("line up") || lower.contains("lines up"))
        }
    }

    @Test
    func connectionsReturnEmptyWithoutEnoughData() async throws {
        // One day of data → AnalyticsService gates out → honest empty (UI shows waiting copy).
        let checkIn = DailyCheckIn(energyScore: 4, focusScore: 4, stressScore: 4, growthScore: 4)
        let health = [HealthSnapshot(sleepMinutes: 450, steps: 9000)]
        let connections = try await OnDeviceAIService().generateConnections(checkIns: [checkIn], health: health)
        #expect(connections.isEmpty)
    }

    @Test
    func todayConnectionUsesEstablishedCorrelation() async throws {
        let (checkIns, health) = makeDataset()
        let today = checkIns.last!
        let todayHealth = health.last!
        let correlations = AnalyticsService().detectCorrelations(checkIns: checkIns, health: health)

        let sentence = try await OnDeviceAIService().generateTodayConnection(
            checkIn: today,
            todayHealth: todayHealth,
            correlations: correlations
        )

        let unwrapped = try #require(sentence)
        #expect(!unwrapped.isEmpty)
        let lower = unwrapped.lowercased()
        #expect(!lower.contains("caused"))
        #expect(!lower.contains("because"))
        // Mentions today's mood band wording ("Today's <Dimension>: …") when leaning on a correlation.
        #expect(unwrapped.contains("Today's"))
    }

    @Test
    func todayConnectionFallsBackToParallelObservation() async throws {
        // Today health present but NO established correlations → neutral parallel observation.
        let today = DailyCheckIn(energyScore: 3, focusScore: 3, stressScore: 3, growthScore: 3)
        let todayHealth = HealthSnapshot(sleepMinutes: 443, steps: 8421)
        let sentence = try await OnDeviceAIService().generateTodayConnection(
            checkIn: today,
            todayHealth: todayHealth,
            correlations: []
        )
        let unwrapped = try #require(sentence)
        // Parallel observation references the concrete metrics without claiming causation.
        #expect(unwrapped.contains("Today you logged"))
        #expect(unwrapped.contains("alongside"))
        #expect(!unwrapped.lowercased().contains("because"))
    }

    @Test
    func todayConnectionIsNilWithoutHealthData() async throws {
        let today = DailyCheckIn(energyScore: 4, focusScore: 4, stressScore: 4, growthScore: 4)
        let sentence = try await OnDeviceAIService().generateTodayConnection(
            checkIn: today,
            todayHealth: nil,
            correlations: []
        )
        #expect(sentence == nil)
    }
}
