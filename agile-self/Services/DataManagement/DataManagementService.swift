//
//  DataManagementService.swift
//  agile-self
//
//  Exports all user data as JSON and performs a full local data wipe.
//  Call on the main actor — it uses the main ModelContext (SwiftData is not
//  thread-safe across contexts).
//

import Foundation
import SwiftData

final class DataManagementService {

    // MARK: - Export

    /// Serializes every model in the store into a pretty-printed JSON bundle.
    func exportAllDataAsJSON(context: ModelContext) throws -> Data {
        let bundle = ExportBundle(
            schemaVersion: Self.schemaVersionString,
            exportedAt: Date(),
            checkIns: try context.fetch(FetchDescriptor<DailyCheckIn>()).map(CheckInDTO.init),
            health: try context.fetch(FetchDescriptor<HealthSnapshot>()).map(HealthDTO.init),
            weeklyReviews: try context.fetch(FetchDescriptor<WeeklyReview>()).map(WeeklyReviewDTO.init),
            monthlyReports: try context.fetch(FetchDescriptor<MonthlyReport>()).map(MonthlyReportDTO.init),
            actions: try context.fetch(FetchDescriptor<ActionItemV2>()).map(ActionDTO.init),
            profile: try context.fetch(FetchDescriptor<UserProfile>()).first.map(ProfileDTO.init),
            streak: try context.fetch(FetchDescriptor<Streak>()).first.map(StreakDTO.init)
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(bundle)
    }

    /// Convenience that wraps the JSON in a Transferable file for ShareLink. Returns nil on failure.
    func exportFile(context: ModelContext) -> ExportedDataFile? {
        guard let data = try? exportAllDataAsJSON(context: context) else { return nil }
        return ExportedDataFile(data: data)
    }

    // MARK: - Delete All

    /// Deletes the user's logged CONTENT and resets the streak, but PRESERVES the UserProfile
    /// (display name, reminder time, preferences) so "Delete All Data" clears your data without
    /// signing you out or forcing re-onboarding. The profile's scheduled reminder stays valid.
    func deleteAllData(context: ModelContext) {
        deleteAll(DailyCheckIn.self, context: context)
        deleteAll(HealthSnapshot.self, context: context)
        deleteAll(WeeklyReview.self, context: context)
        deleteAll(MonthlyReport.self, context: context)
        deleteAll(ActionItemV2.self, context: context)
        deleteAll(Streak.self, context: context)

        // Reset the streak counters to zero (a fresh Streak) but keep the profile intact.
        context.insert(Streak())
        try? context.save()
    }

    private func deleteAll<T: PersistentModel>(_ type: T.Type, context: ModelContext) {
        let items = (try? context.fetch(FetchDescriptor<T>())) ?? []
        for item in items {
            context.delete(item)
        }
    }

    // MARK: - Schema Version

    private static var schemaVersionString: String {
        let version = AppSchemaV1.versionIdentifier
        return "\(version.major).\(version.minor).\(version.patch)"
    }
}

// MARK: - Codable DTOs

private struct ExportBundle: Codable {
    let schemaVersion: String
    let exportedAt: Date
    let checkIns: [CheckInDTO]
    let health: [HealthDTO]
    let weeklyReviews: [WeeklyReviewDTO]
    let monthlyReports: [MonthlyReportDTO]
    let actions: [ActionDTO]
    let profile: ProfileDTO?
    let streak: StreakDTO?
}

private struct CheckInDTO: Codable {
    let date: Date
    let energyScore: Int
    let focusScore: Int
    let stressScore: Int
    let growthScore: Int
    let note: String?
    let dailyInsight: String?
    let createdAt: Date

    init(_ m: DailyCheckIn) {
        date = m.date
        energyScore = m.energyScore
        focusScore = m.focusScore
        stressScore = m.stressScore
        growthScore = m.growthScore
        note = m.note
        dailyInsight = m.dailyInsight
        createdAt = m.createdAt
    }
}

private struct HealthDTO: Codable {
    let date: Date
    let sleepMinutes: Int?
    let steps: Int?
    let activeCalories: Int?
    let exerciseMinutes: Int?
    let restingHeartRate: Int?
    let runningDistanceMeters: Double?
    let screenTimeMinutes: Int?

    init(_ m: HealthSnapshot) {
        date = m.date
        sleepMinutes = m.sleepMinutes
        steps = m.steps
        activeCalories = m.activeCalories
        exerciseMinutes = m.exerciseMinutes
        restingHeartRate = m.restingHeartRate
        runningDistanceMeters = m.runningDistanceMeters
        screenTimeMinutes = m.screenTimeMinutes
    }
}

private struct WeeklyReviewDTO: Codable {
    let weekStart: Date
    let weekEnd: Date
    let conversations: [ConversationMessage]
    let wins: [String]
    let challenges: [String]
    let summary: String?
    let aiTakeaway: String?
    let isCompleted: Bool
    let createdAt: Date
    let completedAt: Date?

    init(_ m: WeeklyReview) {
        weekStart = m.weekStart
        weekEnd = m.weekEnd
        conversations = m.conversations
        wins = m.wins
        challenges = m.challenges
        summary = m.summary
        aiTakeaway = m.aiTakeaway
        isCompleted = m.isCompleted
        createdAt = m.createdAt
        completedAt = m.completedAt
    }
}

private struct MonthlyReportDTO: Codable {
    let month: Int
    let year: Int
    let executiveSummary: String?
    let topInsight: String?
    let overallScore: Double?
    let correlations: [Correlation]
    let isGenerated: Bool
    let createdAt: Date
    let generatedAt: Date?

    init(_ m: MonthlyReport) {
        month = m.month
        year = m.year
        executiveSummary = m.executiveSummary
        topInsight = m.topInsight
        overallScore = m.overallScore
        correlations = m.correlations
        isGenerated = m.isGenerated
        createdAt = m.createdAt
        generatedAt = m.generatedAt
    }
}

private struct ActionDTO: Codable {
    let text: String
    let isCompleted: Bool
    let deadline: Date?
    let completedAt: Date?
    let priority: ActionPriority
    let source: ActionSource
    let notes: String?
    let createdAt: Date
    let updatedAt: Date

    init(_ m: ActionItemV2) {
        text = m.text
        isCompleted = m.isCompleted
        deadline = m.deadline
        completedAt = m.completedAt
        priority = m.priority
        source = m.source
        notes = m.notes
        createdAt = m.createdAt
        updatedAt = m.updatedAt
    }
}

private struct ProfileDTO: Codable {
    let displayName: String?
    let checkInReminderHour: Int
    let checkInReminderMinute: Int
    let weeklyReviewDay: Int
    let subscriptionTier: SubscriptionTier
    let allowCloudAI: Bool
    let notificationsEnabled: Bool
    let hasCompletedOnboarding: Bool
    let createdAt: Date

    init(_ m: UserProfile) {
        displayName = m.displayName
        checkInReminderHour = m.checkInReminderHour
        checkInReminderMinute = m.checkInReminderMinute
        weeklyReviewDay = m.weeklyReviewDay
        subscriptionTier = m.subscriptionTier
        allowCloudAI = m.allowCloudAI
        notificationsEnabled = m.notificationsEnabled
        hasCompletedOnboarding = m.hasCompletedOnboarding
        createdAt = m.createdAt
    }
}

private struct StreakDTO: Codable {
    let currentStreak: Int
    let longestStreak: Int
    let totalCheckIns: Int
    let lastCheckInDate: Date?

    init(_ m: Streak) {
        currentStreak = m.currentStreak
        longestStreak = m.longestStreak
        totalCheckIns = m.totalCheckIns
        lastCheckInDate = m.lastCheckInDate
    }
}
