//
//  MainTabView.swift
//  agile-self
//
//  Created by Claude on 2025/11/30.
//

import SwiftUI
import SwiftData

/// Tab identifiers for the main navigation (3 tabs - Apple style)
enum Tab: String, CaseIterable {
    case home
    case actions
    case history

    var title: String {
        switch self {
        case .home: return "Home"
        case .actions: return "Actions"
        case .history: return "History"
        }
    }

    var iconName: String {
        switch self {
        case .home: return "house.fill"
        case .actions: return "checklist"
        case .history: return "clock.fill"
        }
    }
}

/// Main tab view with 3-tab navigation (Apple style)
struct MainTabView: View {
    @State private var selectedTab: Tab = .home
    @State private var showNewRetroSheet = false
    @State private var showSettings = false

    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            HomeView(
                onNewRetro: { showNewRetroSheet = true },
                onShowSettings: { showSettings = true }
            )
            .tabItem {
                Label(Tab.home.title, systemImage: Tab.home.iconName)
            }
            .tag(Tab.home)

            // Actions Tab
            ActionsListView()
                .tabItem {
                    Label(Tab.actions.title, systemImage: Tab.actions.iconName)
                }
                .tag(Tab.actions)

            // History Tab
            HistoryView()
                .tabItem {
                    Label(Tab.history.title, systemImage: Tab.history.iconName)
                }
                .tag(Tab.history)
        }
        .tint(Theme.KPTA.action)
        .sheet(isPresented: $showNewRetroSheet) {
            KPTAWizardView()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}

// MARK: - Preview

#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: ActionItem.self, Retrospective.self, KPTAItem.self, HealthSummary.self,
            configurations: config
        )
        return MainTabView()
            .modelContainer(container)
    } catch {
        return Text("Preview Error: \(error.localizedDescription)")
    }
}
