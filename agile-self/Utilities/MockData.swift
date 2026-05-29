//
//  MockData.swift
//  agile-self
//
//  Mock data for SwiftUI Previews (Phase 0 prototype).
//

import Foundation
import SwiftData

// MARK: - MockData

enum MockData {

    // MARK: - Static Instances (for prototype Views)

    static let userProfile: UserProfile = {
        UserProfile(
            displayName: "Tetsuya",
            checkInReminderHour: 21,
            checkInReminderMinute: 0,
            weeklyReviewDay: 6,
            subscriptionTier: .premium,
            allowCloudAI: true,
            hasCompletedOnboarding: true
        )
    }()

    static let streak: Streak = {
        Streak(
            currentStreak: 12,
            longestStreak: 23,
            lastCheckInDate: Calendar.current.startOfDay(for: Date()),
            totalCheckIns: 87
        )
    }()

    /// 7 days of check-ins ending today.
    static let weeklyCheckIns: [DailyCheckIn] = {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // 3rd value is Calm (high = calm/good), stored under stressScore. Scores are 1–5.
        let scores: [(energy: Int, focus: Int, calm: Int, growth: Int, note: String?, insight: String?)] = [
            (3, 3, 3, 3, nil, nil),
            (4, 3, 4, 3, nil, nil),
            (3, 4, 3, 4, nil, nil),
            (3, 3, 3, 3, nil, nil),
            (4, 4, 4, 4, nil, nil),
            (4, 4, 4, 4, nil, nil),
            (4, 4, 5, 5,
             "Great day! Finished the design spec and went for a run.",
             "Your focus tends to dip on Wednesdays. Consider a midweek reset ritual."),
        ]

        return scores.enumerated().map { index, s in
            let date = calendar.date(byAdding: .day, value: -(6 - index), to: today)!
            return DailyCheckIn(
                date: date,
                energyScore: s.energy,
                focusScore: s.focus,
                stressScore: s.calm,
                growthScore: s.growth,
                note: s.note,
                dailyInsight: s.insight,
                createdAt: date
            )
        }
    }()

    /// 30 days of check-ins for monthly views.
    static let monthlyCheckIns: [DailyCheckIn] = {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return (0..<30).map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -(29 - daysAgo), to: today)!
            // Generate plausible 1–5 scores with some variance. baseCalm is the Calm axis
            // (high = good), stored under stressScore.
            let baseEnergy = 3 + (daysAgo % 2)
            let baseFocus = 2 + (daysAgo % 3)
            let baseCalm = 3 + (daysAgo % 2)
            let baseGrowth = 3 + (daysAgo % 2)
            return DailyCheckIn(
                date: date,
                energyScore: min(baseEnergy, 5),
                focusScore: min(baseFocus, 5),
                stressScore: min(baseCalm, 5),
                growthScore: min(baseGrowth, 5),
                createdAt: date
            )
        }
    }()

    /// Today's check-in (last item from weeklyCheckIns).
    static let todayCheckIn: DailyCheckIn = weeklyCheckIns.last!

    /// Today's health snapshot.
    static let todayHealth: HealthSnapshot = {
        HealthSnapshot(
            date: Calendar.current.startOfDay(for: Date()),
            sleepMinutes: 443,
            steps: 8421,
            activeCalories: 420,
            exerciseMinutes: 45,
            restingHeartRate: 62,
            runningDistanceMeters: 5200,
            screenTimeMinutes: 192
        )
    }()

    /// Monthly report with correlations.
    static let monthlyReport: MonthlyReport = {
        let report = MonthlyReport(
            month: 2,
            year: 2026,
            executiveSummary: "February has been a month of steady growth. Your composite score climbed from 3.6 (Week 1) to 4.1 (Week 4), driven by more consistent exercise and better sleep. The biggest opportunity is staying calm on meeting-heavy days.",
            topInsight: "Running 3+ times per week lines up with a 23% higher focus score and steadier calm.",
            overallScore: 4.1,
            isGenerated: true,
            generatedAt: Date()
        )
        report.setCorrelations([
            Correlation(factor1: "Sleep", factor2: "Focus", coefficient: 0.72, description: "Sleep\u{2191} = Focus\u{2191}"),
            Correlation(factor1: "Exercise", factor2: "Energy", coefficient: 0.68, description: "Exercise\u{2191} = Energy\u{2191}"),
            Correlation(factor1: "Screen Time", factor2: "Calm", coefficient: -0.54, description: "Screen Time\u{2191} = Calm\u{2193}"),
            Correlation(factor1: "Running", factor2: "Growth", coefficient: 0.61, description: "Running\u{2191} = Growth\u{2191}"),
        ])
        return report
    }()

    /// Action items for profile/action views.
    static let actionItems: [ActionItemV2] = {
        let calendar = Calendar.current
        return [
            ActionItemV2(
                text: "Block 30min no-meeting time on Wednesdays",
                deadline: calendar.date(byAdding: .day, value: 3, to: Date()),
                priority: .high,
                source: .weeklyReview
            ),
            ActionItemV2(
                text: "Run at least 3 times this week",
                deadline: calendar.date(byAdding: .day, value: 5, to: Date()),
                priority: .high,
                source: .aiSuggested
            ),
            ActionItemV2(
                text: "Try a 5-minute meditation before bed",
                priority: .medium,
                source: .weeklyReview
            ),
            ActionItemV2(
                text: "Set Screen Time limit to 2.5 hours",
                isCompleted: true,
                completedAt: calendar.date(byAdding: .day, value: -1, to: Date()),
                priority: .medium,
                source: .manual
            ),
            ActionItemV2(
                text: "Write a weekly reflection note on Friday",
                deadline: calendar.date(byAdding: .day, value: 6, to: Date()),
                priority: .low,
                source: .manual
            ),
        ]
    }()

    // MARK: - Preview ModelContainer

    @MainActor
    static var previewContainer: ModelContainer {
        let schema = Schema([
            DailyCheckIn.self,
            HealthSnapshot.self,
            WeeklyReview.self,
            MonthlyReport.self,
            ActionItemV2.self,
            UserProfile.self,
            Streak.self,
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])

        let context = container.mainContext

        // Insert user profile
        let profile = UserProfile(
            displayName: "Tetsuya",
            checkInReminderHour: 21,
            checkInReminderMinute: 0,
            weeklyReviewDay: 6,
            subscriptionTier: .premium,
            allowCloudAI: true,
            hasCompletedOnboarding: true
        )
        context.insert(profile)

        // Insert streak
        let streak = Streak(
            currentStreak: 12,
            longestStreak: 23,
            lastCheckInDate: Calendar.current.startOfDay(for: Date()),
            totalCheckIns: 87
        )
        context.insert(streak)

        // Insert check-ins (last 7 days)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // 3rd value is Calm (high = calm/good), stored under stressScore. Scores are 1–5.
        let scores: [(energy: Int, focus: Int, calm: Int, growth: Int)] = [
            (3, 3, 3, 3),
            (4, 3, 4, 3),
            (3, 4, 3, 4),
            (3, 3, 3, 3),
            (4, 4, 4, 4),
            (4, 4, 4, 4),
            (4, 4, 5, 5),
        ]

        for (index, s) in scores.enumerated() {
            let date = calendar.date(byAdding: .day, value: -(6 - index), to: today)!
            let checkIn = DailyCheckIn(
                date: date,
                energyScore: s.energy,
                focusScore: s.focus,
                stressScore: s.calm,
                growthScore: s.growth,
                note: index == 6 ? "Great day! Finished the design spec and went for a run." : nil,
                dailyInsight: index == 6 ? "Your focus tends to dip on Wednesdays. Consider a midweek reset ritual." : nil,
                createdAt: date
            )
            context.insert(checkIn)
        }

        // Insert health snapshots
        let healthData: [(sleep: Int, steps: Int, cal: Int, ex: Int, hr: Int, run: Double, screen: Int)] = [
            (420, 7200, 380, 30, 65, 0, 210),
            (390, 9100, 450, 55, 63, 5800, 185),
            (450, 6800, 350, 25, 64, 0, 240),
            (410, 8500, 410, 40, 62, 0, 195),
            (380, 10200, 520, 60, 61, 7200, 175),
            (460, 7800, 400, 35, 63, 0, 220),
            (443, 8421, 420, 45, 62, 5200, 192),
        ]

        for (index, d) in healthData.enumerated() {
            let date = calendar.date(byAdding: .day, value: -(6 - index), to: today)!
            let snapshot = HealthSnapshot(
                date: date,
                sleepMinutes: d.sleep,
                steps: d.steps,
                activeCalories: d.cal,
                exerciseMinutes: d.ex,
                restingHeartRate: d.hr,
                runningDistanceMeters: d.run,
                screenTimeMinutes: d.screen
            )
            context.insert(snapshot)
        }

        // Insert monthly report
        let report = MonthlyReport(
            month: 2,
            year: 2026,
            executiveSummary: "February has been a month of steady growth. Your composite score climbed from 3.6 (Week 1) to 4.1 (Week 4), driven by more consistent exercise and better sleep. The biggest opportunity is staying calm on meeting-heavy days.",
            topInsight: "Running 3+ times per week lines up with a 23% higher focus score and steadier calm.",
            overallScore: 4.1,
            isGenerated: true,
            generatedAt: Date()
        )

        let correlations: [Correlation] = [
            Correlation(factor1: "Sleep", factor2: "Focus", coefficient: 0.72, description: "Sleep\u{2191} = Focus\u{2191}"),
            Correlation(factor1: "Exercise", factor2: "Energy", coefficient: 0.68, description: "Exercise\u{2191} = Energy\u{2191}"),
            Correlation(factor1: "Screen Time", factor2: "Calm", coefficient: -0.54, description: "Screen Time\u{2191} = Calm\u{2193}"),
            Correlation(factor1: "Running", factor2: "Growth", coefficient: 0.61, description: "Running\u{2191} = Growth\u{2191}"),
        ]
        report.setCorrelations(correlations)
        context.insert(report)

        // Insert action items
        let action1 = ActionItemV2(
            text: "Block 30min no-meeting time on Wednesdays",
            deadline: calendar.date(byAdding: .day, value: 3, to: Date()),
            priority: .high,
            source: .weeklyReview
        )
        context.insert(action1)

        let action2 = ActionItemV2(
            text: "Run at least 3 times this week",
            deadline: calendar.date(byAdding: .day, value: 5, to: Date()),
            priority: .high,
            source: .aiSuggested
        )
        context.insert(action2)

        let action3 = ActionItemV2(
            text: "Try a 5-minute meditation before bed",
            priority: .medium,
            source: .weeklyReview
        )
        context.insert(action3)

        let action4 = ActionItemV2(
            text: "Set Screen Time limit to 2.5 hours",
            isCompleted: true,
            completedAt: calendar.date(byAdding: .day, value: -1, to: Date()),
            priority: .medium,
            source: .manual
        )
        context.insert(action4)

        let action5 = ActionItemV2(
            text: "Write a weekly reflection note on Friday",
            deadline: calendar.date(byAdding: .day, value: 6, to: Date()),
            priority: .low,
            source: .manual
        )
        context.insert(action5)

        try? context.save()

        return container
    }
}
