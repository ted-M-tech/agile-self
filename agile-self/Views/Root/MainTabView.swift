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

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(AppTab.home.title, systemImage: AppTab.home.icon, value: .home) {
                HomeView(
                    onShowSettings: { showSettings = true },
                    onLogCheckIn: { showCheckIn = true }
                )
            }

            Tab(AppTab.insights.title, systemImage: AppTab.insights.icon, value: .insights) {
                InsightsView()
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
            SettingsPlaceholderView()
        }
        .fullScreenCover(isPresented: $showCheckIn) {
            DailyCheckInView()
        }
    }
}

// MARK: - Settings Placeholder

private struct SettingsPlaceholderView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.backgroundPrimary.ignoresSafeArea()
                Text("Settings Coming Soon")
                    .font(Theme.Typography.title2)
                    .foregroundStyle(Theme.Colors.textSecondary)
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
        .preferredColorScheme(.dark)
}
