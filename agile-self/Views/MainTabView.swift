//
//  MainTabView.swift
//  agile-self
//
//  Created by Claude on 2025/11/30.
//

import SwiftUI

enum Tab: String, CaseIterable {
    case dashboard
    case new
    case actions
    case history
    case settings

    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .new: return "New"
        case .actions: return "Actions"
        case .history: return "History"
        case .settings: return "Settings"
        }
    }

    var iconName: String {
        switch self {
        case .dashboard: return "chart.bar.fill"
        case .new: return "plus.circle.fill"
        case .actions: return "checklist"
        case .history: return "clock.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab: Tab = .dashboard

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardPlaceholderView()
                .tabItem {
                    Label(Tab.dashboard.title, systemImage: Tab.dashboard.iconName)
                }
                .tag(Tab.dashboard)

            NewRetroPlaceholderView()
                .tabItem {
                    Label(Tab.new.title, systemImage: Tab.new.iconName)
                }
                .tag(Tab.new)

            ActionsPlaceholderView()
                .tabItem {
                    Label(Tab.actions.title, systemImage: Tab.actions.iconName)
                }
                .tag(Tab.actions)

            HistoryPlaceholderView()
                .tabItem {
                    Label(Tab.history.title, systemImage: Tab.history.iconName)
                }
                .tag(Tab.history)

            SettingsPlaceholderView()
                .tabItem {
                    Label(Tab.settings.title, systemImage: Tab.settings.iconName)
                }
                .tag(Tab.settings)
        }
    }
}

// MARK: - Placeholder Views

struct DashboardPlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.lg) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary)

                Text("Dashboard")
                    .font(Theme.Typography.title)

                Text("Your wellbeing score, recent retrospectives, and insights will appear here.")
                    .font(Theme.Typography.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.xl)
            }
            .navigationTitle("Dashboard")
        }
    }
}

struct NewRetroPlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.lg) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Theme.KPTA.action)

                Text("New Retrospective")
                    .font(Theme.Typography.title)

                Text("Create a new weekly or monthly retrospective using the KPTA framework.")
                    .font(Theme.Typography.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.xl)

                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    KPTALegendRow(category: .keep, description: "What went well")
                    KPTALegendRow(category: .problem, description: "Obstacles faced")
                    KPTALegendRow(category: .try, description: "New approaches")
                    HStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: "checkmark.square.fill")
                            .foregroundStyle(Theme.KPTA.action)
                        Text("Action")
                            .fontWeight(.medium)
                        Text("- Concrete to-dos")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(Theme.Spacing.md)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
            }
            .navigationTitle("New")
        }
    }
}

struct KPTALegendRow: View {
    let category: KPTACategory
    let description: String

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: category.iconName)
                .foregroundStyle(category.color)
            Text(category.displayName)
                .fontWeight(.medium)
            Text("- \(description)")
                .foregroundStyle(.secondary)
        }
    }
}

struct ActionsPlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.lg) {
                Image(systemName: "checklist")
                    .font(.system(size: 60))
                    .foregroundStyle(Theme.KPTA.action)

                Text("Actions")
                    .font(Theme.Typography.title)

                Text("Track and complete your action items from retrospectives.")
                    .font(Theme.Typography.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.xl)
            }
            .navigationTitle("Actions")
        }
    }
}

struct HistoryPlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.lg) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary)

                Text("History")
                    .font(Theme.Typography.title)

                Text("Browse and search your past retrospectives.")
                    .font(Theme.Typography.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.xl)
            }
            .navigationTitle("History")
        }
    }
}

struct SettingsPlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.lg) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary)

                Text("Settings")
                    .font(Theme.Typography.title)

                Text("Configure reminders, manage data, and customize your experience.")
                    .font(Theme.Typography.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.xl)
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    MainTabView()
}
