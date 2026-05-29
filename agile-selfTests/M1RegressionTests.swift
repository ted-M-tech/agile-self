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

// MARK: - CheckInViewModel upsert (#6)

@MainActor
struct CheckInViewModelUpsertTests {

    @Test
    func savingTwiceSameDayKeepsOneRow() async throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext

        let vm1 = CheckInViewModel()
        vm1.energyScore = 8
        vm1.focusScore = 7
        vm1.stressScore = 3
        vm1.growthScore = 9
        await vm1.saveCheckIn(context: context)
        #expect(try context.fetch(FetchDescriptor<DailyCheckIn>()).count == 1)

        // Second save on the same day must UPDATE, not insert a duplicate.
        let vm2 = CheckInViewModel()
        vm2.energyScore = 5
        await vm2.saveCheckIn(context: context)

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
        // avgComposite for empty check-ins is 5.0 — the LLM never alters this number.
        #expect(result.overallScore == 5.0)
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
        context.insert(DailyCheckIn(energyScore: 7))
        try context.save()
        let rows = try context.fetch(FetchDescriptor<DailyCheckIn>())
        #expect(rows.count == 1)
        #expect(rows.first?.energyScore == 7)
    }
}
