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
    @State private var showCheckIn = false
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
                    onLogCheckIn: { showCheckIn = true },
                    refreshToken: homeRefreshToken
                )
            }

            Tab(AppTab.insights.title, systemImage: AppTab.insights.icon, value: .insights) {
                InsightsView(
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
        .fullScreenCover(isPresented: $showCheckIn, onDismiss: { homeRefreshToken += 1 }) {
            DailyCheckInView()
        }
        .sheet(isPresented: $showMonthlyReport) {
            // MonthlyReportView owns its own top bar (with a close button) and dark scheme,
            // so it is presented bare — no NavigationStack/Done wrapper (that produced a
            // duplicate close affordance).
            MonthlyReportView(onDismiss: { showMonthlyReport = false })
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
