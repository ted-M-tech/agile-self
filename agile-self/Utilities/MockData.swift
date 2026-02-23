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

        let scores: [(energy: Int, focus: Int, stress: Int, growth: Int, note: String?, insight: String?)] = [
            (6, 5, 6, 5, nil, nil),
            (7, 6, 4, 6, nil, nil),
            (5, 7, 5, 7, nil, nil),
            (6, 6, 5, 6, nil, nil),
            (8, 7, 3, 8, nil, nil),
            (7, 8, 4, 7, nil, nil),
            (8, 7, 3, 9,
             "Great day! Finished the design spec and went for a run.",
             "Your focus tends to dip on Wednesdays. Consider a midweek reset ritual."),
        ]

        return scores.enumerated().map { index, s in
            let date = calendar.date(byAdding: .day, value: -(6 - index), to: today)!
            return DailyCheckIn(
                date: date,
                energyScore: s.energy,
                focusScore: s.focus,
                stressScore: s.stress,
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
            // Generate plausible scores with some variance
            let baseEnergy = 6 + (daysAgo % 3)
            let baseFocus = 5 + (daysAgo % 4)
            let baseStress = 3 + (daysAgo % 5)
            let baseGrowth = 6 + (daysAgo % 3)
            return DailyCheckIn(
                date: date,
                energyScore: min(baseEnergy, 10),
                focusScore: min(baseFocus, 10),
                stressScore: min(baseStress, 10),
                growthScore: min(baseGrowth, 10),
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
            executiveSummary: "February has been a month of steady growth. Your composite score improved from 6.2 (Week 1) to 7.4 (Week 4), driven primarily by increased exercise frequency and better sleep consistency. The biggest area for improvement remains stress management, particularly on meeting-heavy days.",
            topInsight: "Running 3+ times per week correlates with a 23% higher focus score and 31% lower stress.",
            overallScore: 7.1,
            isGenerated: true,
            generatedAt: Date()
        )
        report.setCorrelations([
            Correlation(factor1: "Sleep", factor2: "Focus", coefficient: 0.72, description: "Sleep\u{2191} = Focus\u{2191}"),
            Correlation(factor1: "Exercise", factor2: "Energy", coefficient: 0.68, description: "Exercise\u{2191} = Energy\u{2191}"),
            Correlation(factor1: "Screen Time", factor2: "Stress", coefficient: 0.54, description: "Screen Time\u{2191} = Stress\u{2191}"),
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

        let scores: [(energy: Int, focus: Int, stress: Int, growth: Int)] = [
            (6, 5, 6, 5),
            (7, 6, 4, 6),
            (5, 7, 5, 7),
            (6, 6, 5, 6),
            (8, 7, 3, 8),
            (7, 8, 4, 7),
            (8, 7, 3, 9),
        ]

        for (index, s) in scores.enumerated() {
            let date = calendar.date(byAdding: .day, value: -(6 - index), to: today)!
            let checkIn = DailyCheckIn(
                date: date,
                energyScore: s.energy,
                focusScore: s.focus,
                stressScore: s.stress,
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

        // Insert weekly review
        let weekStart = calendar.date(byAdding: .day, value: -6, to: today)!
        let weekEnd = today

        let review = WeeklyReview(
            weekStart: weekStart,
            weekEnd: weekEnd,
            wins: [
                "Maintained a 12-day check-in streak",
                "Focus scores improved by 18% vs last week",
                "Ran 3 times this week (11km total)",
            ],
            challenges: [
                "Stress spiked on Wednesday - back-to-back meetings",
                "Screen time exceeded 3h on 4 of 7 days",
            ],
            summary: "A strong week overall. Your consistency is paying off with steady improvements across all dimensions. The midweek stress spike is a pattern worth addressing.",
            aiTakeaway: "Try blocking 30 minutes of no-meeting time on Wednesdays. Your data shows a clear focus-stress correlation on meeting-heavy days.",
            isCompleted: true,
            completedAt: Date()
        )

        let messages: [ConversationMessage] = [
            ConversationMessage(role: .assistant, content: "Great week, Tetsuya! Your overall score averaged 7.4 - that's up from 6.8 last week. What do you think drove the improvement?"),
            ConversationMessage(role: .user, content: "I think running regularly helped my energy a lot"),
            ConversationMessage(role: .assistant, content: "The data supports that. On days you ran, your energy was 1.8 points higher on average. Your focus also improved by 1.2 points on run days. Want to set a running target for next week?"),
            ConversationMessage(role: .user, content: "Yes, I'd like to run at least 3 times"),
            ConversationMessage(role: .assistant, content: "Perfect. I noticed your stress peaked on Wednesday (7/10). What happened?"),
            ConversationMessage(role: .user, content: "Back-to-back meetings all day, no breaks"),
        ]
        review.setConversations(messages)
        context.insert(review)

        // Insert monthly report
        let report = MonthlyReport(
            month: 2,
            year: 2026,
            executiveSummary: "February has been a month of steady growth. Your composite score improved from 6.2 (Week 1) to 7.4 (Week 4), driven primarily by increased exercise frequency and better sleep consistency. The biggest area for improvement remains stress management, particularly on meeting-heavy days.",
            topInsight: "Running 3+ times per week correlates with a 23% higher focus score and 31% lower stress.",
            overallScore: 7.1,
            isGenerated: true,
            generatedAt: Date()
        )

        let correlations: [Correlation] = [
            Correlation(factor1: "Sleep", factor2: "Focus", coefficient: 0.72, description: "Sleep\u{2191} = Focus\u{2191}"),
            Correlation(factor1: "Exercise", factor2: "Energy", coefficient: 0.68, description: "Exercise\u{2191} = Energy\u{2191}"),
            Correlation(factor1: "Screen Time", factor2: "Stress", coefficient: 0.54, description: "Screen Time\u{2191} = Stress\u{2191}"),
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
