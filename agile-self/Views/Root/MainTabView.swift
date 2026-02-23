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
    @State private var selectedTab: AppTab = .home
    @State private var showSettings = false
    @State private var showCheckIn = false
    @State private var showWeeklyReview = false
    @State private var showMonthlyReport = false

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(AppTab.home.title, systemImage: AppTab.home.icon, value: .home) {
                HomeView(
                    onShowSettings: { showSettings = true },
                    onLogCheckIn: { showCheckIn = true }
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
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .fullScreenCover(isPresented: $showCheckIn) {
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

/// Manages the multi-screen weekly review flow.
private struct WeeklyReviewFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var phase: ReviewPhase = .intro

    enum ReviewPhase {
        case intro, conversation, summary
    }

    var body: some View {
        NavigationStack {
            Group {
                switch phase {
                case .intro:
                    WeeklyReviewIntroView(
                        onStartReview: { phase = .conversation },
                        onSkip: { phase = .summary }
                    )
                case .conversation:
                    WeeklyConversationView(
                        onComplete: { phase = .summary }
                    )
                case .summary:
                    WeeklySummaryView(onDismiss: { dismiss() })
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
}

// MARK: - Preview

#Preview {
    MainTabView()
        .modelContainer(MockData.previewContainer)
        .environment(AppContainer(modelContainer: MockData.previewContainer))
        .preferredColorScheme(.dark)
}
