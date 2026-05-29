//
//  MainTabView.swift
//  agile-self
//
//  v2 - Premium dark themed 3-tab navigation.
//

import SwiftUI
import SwiftData

// MARK: - AppTab

enum AppTab: String, CaseIterable {
    case home
    case insights
    case profile

    var title: String {
        switch self {
        case .home: return "Home"
        case .insights: return "Insights"
        case .profile: return "Profile"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .insights: return "chart.line.uptrend.xyaxis"
        case .profile: return "person.fill"
        }
    }
}

// MARK: - MainTabView

struct MainTabView: View {
    /// One-shot deep-link from onboarding ("Start First Check-in"). Consumed once on first
    /// appear to auto-open the check-in, then cleared so it never re-opens.
    @Binding var openCheckInOnAppear: Bool

    @State private var selectedTab: AppTab = .home
    @State private var showSettings = false
    @State private var showCheckIn = false
    @State private var showWeeklyReview = false
    @State private var showMonthlyReport = false
    /// Bumped when the check-in cover dismisses so Home reloads (a full-screen cover does not
    /// remove Home underneath, so its `.task` never re-runs on its own).
    @State private var homeRefreshToken = 0

    init(openCheckInOnAppear: Binding<Bool> = .constant(false)) {
        _openCheckInOnAppear = openCheckInOnAppear
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(AppTab.home.title, systemImage: AppTab.home.icon, value: .home) {
                HomeView(
                    onShowSettings: { showSettings = true },
                    onLogCheckIn: { showCheckIn = true },
                    refreshToken: homeRefreshToken
                )
            }

            Tab(AppTab.insights.title, systemImage: AppTab.insights.icon, value: .insights) {
                InsightsView(
                    onShowWeeklyReview: { showWeeklyReview = true },
                    onShowMonthlyReport: { showMonthlyReport = true }
                )
            }

            Tab(AppTab.profile.title, systemImage: AppTab.profile.icon, value: .profile) {
                ProfileView()
            }
        }
        .tint(Theme.Colors.accentStart)
        .toolbarBackground(Theme.Colors.backgroundSecondary, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
        .onAppear {
            // Consume the onboarding deep-link exactly once: open the check-in, then clear
            // the flag so it never re-fires on subsequent appears.
            if openCheckInOnAppear {
                openCheckInOnAppear = false
                selectedTab = .home
                showCheckIn = true
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .fullScreenCover(isPresented: $showCheckIn, onDismiss: { homeRefreshToken += 1 }) {
            DailyCheckInView()
        }
        .sheet(isPresented: $showWeeklyReview) {
            WeeklyReviewFlowView()
        }
        .sheet(isPresented: $showMonthlyReport) {
            NavigationStack {
                MonthlyReportView(onDismiss: { showMonthlyReport = false })
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showMonthlyReport = false }
                                .foregroundStyle(Theme.Colors.accentStart)
                        }
                    }
            }
            .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Weekly Review Flow

/// Manages the multi-screen weekly review flow and owns its data: this week's
/// check-ins (via a stable week-of-year `@Query`) and the shared `WeeklyReview` model.
private struct WeeklyReviewFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppContainer.self) private var appContainer
    @Environment(\.modelContext) private var modelContext

    @Query private var weeklyCheckIns: [DailyCheckIn]
    @State private var phase: ReviewPhase = .intro
    @State private var review: WeeklyReview?
    @State private var summaryResult: WeeklySummaryResult?
    @State private var isGeneratingSummary = false

    enum ReviewPhase {
        case intro, conversation, summary
    }

    init() {
        // Stable week boundary (week-of-year) — used for BOTH the check-in window and
        // the fetch-or-create review key, so the review row is deterministic per week
        // (avoids duplicate rows from a rolling today-minus-6 anchor).
        let interval = Calendar.current.dateInterval(of: .weekOfYear, for: Date())
        let weekStart = interval?.start ?? Calendar.current.startOfDay(for: Date())
        let weekEnd = interval?.end ?? Date()
        _weeklyCheckIns = Query(
            filter: #Predicate<DailyCheckIn> { $0.date >= weekStart && $0.date < weekEnd },
            sort: \.date,
            order: .forward
        )
    }

    var body: some View {
        NavigationStack {
            Group {
                switch phase {
                case .intro:
                    WeeklyReviewIntroView(
                        checkIns: weeklyCheckIns,
                        onStartReview: {
                            ensureReview()
                            phase = .conversation
                        },
                        onSkip: { finishWithSummary() }
                    )
                case .conversation:
                    WeeklyConversationView(
                        checkIns: weeklyCheckIns,
                        review: review,
                        onComplete: { finishWithSummary() }
                    )
                case .summary:
                    WeeklySummaryView(
                        checkIns: weeklyCheckIns,
                        review: review,
                        result: summaryResult,
                        isLoading: isGeneratingSummary,
                        onDismiss: { dismiss() }
                    )
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.Colors.accentStart)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    /// Fetches or creates the WeeklyReview for the current week, eagerly, so the same
    /// model identity is shared with the conversation view's transcript writes.
    private func ensureReview() {
        guard review == nil else { return }
        let interval = Calendar.current.dateInterval(of: .weekOfYear, for: Date())
        let weekStart = interval?.start ?? Calendar.current.startOfDay(for: Date())
        let weekEndInclusive: Date = {
            guard let end = interval?.end else { return Date() }
            return Calendar.current.date(byAdding: .day, value: -1, to: end) ?? end
        }()

        let descriptor = FetchDescriptor<WeeklyReview>(
            predicate: #Predicate<WeeklyReview> { $0.weekStart == weekStart }
        )
        if let existing = try? modelContext.fetch(descriptor).first {
            review = existing
        } else {
            let created = WeeklyReview(weekStart: weekStart, weekEnd: weekEndInclusive)
            modelContext.insert(created)
            try? modelContext.save()
            review = created
        }
    }

    /// Generates the on-device weekly summary and persists it onto the review.
    private func finishWithSummary() {
        ensureReview()
        phase = .summary
        isGeneratingSummary = true
        Task {
            defer { isGeneratingSummary = false }
            do {
                let result = try await appContainer.aiService.generateWeeklySummary(
                    conversation: review?.conversations ?? [],
                    checkIns: weeklyCheckIns
                )
                summaryResult = result

                // Persist only if the summary has real content.
                if let review,
                   !result.wins.isEmpty || !result.challenges.isEmpty || !result.summary.isEmpty {
                    review.wins = result.wins
                    review.challenges = result.challenges
                    review.summary = result.summary
                    review.aiTakeaway = result.aiTakeaway
                    review.isCompleted = true
                    review.completedAt = Date()
                    try? modelContext.save()
                }
            } catch {
                // Degrade to whatever is persisted on the review; summaryResult stays nil.
            }
        }
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
        .modelContainer(MockData.previewContainer)
        .environment(AppContainer(modelContainer: MockData.previewContainer))
        .preferredColorScheme(.dark)
}
