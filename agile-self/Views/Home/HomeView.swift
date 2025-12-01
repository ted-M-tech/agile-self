//
//  HomeView.swift
//  agile-self
//
//  Created by Claude on 2025/12/01.
//

import SwiftUI
import SwiftData

/// Clean, minimal home screen following Apple design guidelines
struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<ActionItem> { !$0.isCompleted },
           sort: [SortDescriptor(\ActionItem.deadline, order: .forward)])
    private var pendingActions: [ActionItem]

    @Query(sort: [SortDescriptor(\Retrospective.createdAt, order: .reverse)])
    private var retrospectives: [Retrospective]

    let onNewRetro: () -> Void
    let onShowSettings: () -> Void

    private var healthManager = HealthKitManager.shared

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Good night"
        }
    }

    private var overdueActions: [ActionItem] {
        pendingActions.filter { $0.isOverdue }
    }

    private var upcomingActions: [ActionItem] {
        Array(pendingActions.filter { !$0.isOverdue }.prefix(3))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    // New Retrospective CTA
                    newRetroCTA
                        .padding(.top, Theme.Spacing.sm)

                    // Health Data Section
                    healthSection

                    // Quick Stats
                    statsRow

                    // Overdue Actions (if any)
                    if !overdueActions.isEmpty {
                        overdueSection
                    }

                    // Upcoming Actions
                    if !upcomingActions.isEmpty {
                        upcomingSection
                    }

                    // Recent Retrospective
                    if let recent = retrospectives.first {
                        recentRetroSection(recent)
                    }

                    Spacer(minLength: Theme.Spacing.xxl)
                }
                .padding(.horizontal, Theme.Spacing.md)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(greeting)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        onShowSettings()
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .task {
                await healthManager.requestAuthorization()
            }
            .refreshable {
                await healthManager.fetchTodayData()
            }
        }
    }

    // MARK: - New Retro CTA

    private var newRetroCTA: some View {
        Button(action: onNewRetro) {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Theme.KPTA.action)

                VStack(alignment: .leading, spacing: 2) {
                    Text("New Retrospective")
                        .font(Theme.Typography.headline)
                        .foregroundStyle(.primary)

                    Text("Daily, Weekly, or Monthly")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(Theme.Spacing.md)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Health Section

    private var healthSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.red)
                Text("Today's Health")
                    .font(Theme.Typography.headline)
                Spacer()

                if healthManager.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }

            if healthManager.authorizationStatus == .unavailable {
                healthUnavailableView
            } else if healthManager.authorizationStatus == .denied {
                healthDeniedView
            } else {
                healthDataGrid
            }
        }
        .padding(Theme.Spacing.md)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
    }

    private var healthDataGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: Theme.Spacing.sm) {
            HealthMetricCard(
                icon: "bed.double.fill",
                value: healthManager.formattedTodaySleep,
                label: "Sleep",
                color: .indigo
            )

            HealthMetricCard(
                icon: "figure.walk",
                value: healthManager.formattedTodaySteps,
                label: "Steps",
                color: .orange
            )

            HealthMetricCard(
                icon: "flame.fill",
                value: healthManager.formattedTodayCalories,
                label: "Active Cal",
                color: .pink
            )

            HealthMetricCard(
                icon: "figure.run",
                value: healthManager.formattedTodayExercise,
                label: "Exercise",
                color: .green
            )
        }
    }

    private var healthUnavailableView: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(.secondary)
            Text("Health data not available on this device")
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.md)
    }

    private var healthDeniedView: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text("Health access not granted")
                .font(Theme.Typography.callout)
                .foregroundStyle(.secondary)
            Text("Enable in Settings > Privacy > Health")
                .font(Theme.Typography.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.md)
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: Theme.Spacing.sm) {
            StatCard(
                value: "\(retrospectives.count)",
                label: "Retros",
                icon: "doc.text.fill",
                color: Theme.KPTA.`try`
            )

            StatCard(
                value: "\(pendingActions.count)",
                label: "Pending",
                icon: "checklist",
                color: Theme.KPTA.action
            )

            StatCard(
                value: "\(completedThisWeek)",
                label: "Done",
                icon: "checkmark.circle.fill",
                color: Theme.KPTA.keep
            )
        }
    }

    private var completedThisWeek: Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()

        // This would need a separate query for completed actions
        // For now, return a placeholder
        return 0
    }

    // MARK: - Overdue Section

    private var overdueSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Theme.KPTA.problem)
                Text("Overdue")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.KPTA.problem)
                Spacer()
            }

            ForEach(overdueActions.prefix(3)) { action in
                ActionMiniRow(action: action)
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.KPTA.problemBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
    }

    // MARK: - Upcoming Section

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Upcoming Actions")
                .font(Theme.Typography.headline)
                .foregroundStyle(.primary)

            ForEach(upcomingActions) { action in
                ActionMiniRow(action: action)
            }
        }
        .padding(Theme.Spacing.md)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
    }

    // MARK: - Recent Retro Section

    private func recentRetroSection(_ retro: Retrospective) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text("Recent")
                    .font(Theme.Typography.headline)
                Spacer()
                Text(retro.type.displayName)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: Theme.Spacing.md) {
                KPTAMiniCount(count: retro.keeps.count, category: .keep)
                KPTAMiniCount(count: retro.problems.count, category: .problem)
                KPTAMiniCount(count: retro.tries.count, category: .try)
                Spacer()
                Text(retro.formattedDateRange)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(Theme.Spacing.md)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
    }
}

// MARK: - Health Metric Card

private struct HealthMetricCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(Theme.Typography.headline)
                    .fontWeight(.semibold)

                Text(label)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(Theme.Spacing.sm)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.small))
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(value)
                .font(Theme.Typography.title2)
                .fontWeight(.semibold)

            Text(label)
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.md)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
    }
}

// MARK: - Action Mini Row

private struct ActionMiniRow: View {
    let action: ActionItem

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Circle()
                .fill(action.isOverdue ? Theme.KPTA.problem : Theme.KPTA.action)
                .frame(width: 8, height: 8)

            Text(action.text)
                .font(Theme.Typography.body)
                .lineLimit(1)

            Spacer()

            if let deadline = action.deadline {
                Text(deadline, style: .date)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(action.isOverdue ? Theme.KPTA.problem : .secondary)
            }
        }
        .padding(.vertical, Theme.Spacing.xs)
    }
}

// MARK: - KPTA Mini Count

private struct KPTAMiniCount: View {
    let count: Int
    let category: KPTACategory

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(category.color)
                .frame(width: 8, height: 8)
            Text("\(count)")
                .font(Theme.Typography.callout)
                .fontWeight(.medium)
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
        return HomeView(onNewRetro: {}, onShowSettings: {})
            .modelContainer(container)
    } catch {
        return Text("Preview Error: \(error.localizedDescription)")
    }
}
