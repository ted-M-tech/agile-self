//
//  HistoryView.swift
//  agile-self
//
//  Created by Claude on 2025/11/30.
//

import SwiftUI
import SwiftData

/// View for browsing and searching past retrospectives
struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Retrospective.createdAt, order: .reverse)
    private var retrospectives: [Retrospective]

    @State private var searchText = ""
    @State private var selectedType: RetrospectiveType?
    @State private var sortOrder: HistorySortOrder = .newest

    var body: some View {
        NavigationStack {
            Group {
                if retrospectives.isEmpty {
                    emptyState
                } else {
                    retrospectivesList
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search retrospectives")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    sortMenu
                }

                ToolbarItem(placement: .secondaryAction) {
                    filterMenu
                }
            }
        }
    }

    // MARK: - Retrospectives List

    private var retrospectivesList: some View {
        List {
            // Stats Header
            if searchText.isEmpty && selectedType == nil {
                statsSection
            }

            // Group by month
            ForEach(groupedRetrospectives.keys.sorted(by: >), id: \.self) { month in
                Section {
                    ForEach(groupedRetrospectives[month] ?? []) { retro in
                        NavigationLink {
                            RetrospectiveDetailView(retrospective: retro)
                        } label: {
                            HistoryRowView(retrospective: retro)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                deleteRetrospective(retro)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    Text(month)
                        .font(Theme.Typography.headline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .animation(.easeInOut(duration: 0.2), value: searchText)
        .animation(.easeInOut(duration: 0.2), value: selectedType)
        .animation(.easeInOut(duration: 0.2), value: sortOrder)
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        Section {
            HStack(spacing: Theme.Spacing.lg) {
                statCard(
                    value: "\(retrospectives.count)",
                    label: "Total",
                    icon: "doc.text.fill",
                    color: Theme.KPTA.action
                )

                statCard(
                    value: "\(weeklyCount)",
                    label: "Weekly",
                    icon: "calendar",
                    color: Theme.KPTA.keep
                )

                statCard(
                    value: "\(monthlyCount)",
                    label: "Monthly",
                    icon: "calendar.badge.clock",
                    color: Theme.KPTA.try
                )
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
        }
    }

    private func statCard(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: Theme.Spacing.xs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(value)
                .font(Theme.Typography.title2)
                .foregroundStyle(.primary)

            Text(label)
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.md)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
    }

    // MARK: - Sort Menu

    private var sortMenu: some View {
        Menu {
            ForEach(HistorySortOrder.allCases) { order in
                Button {
                    withAnimation {
                        sortOrder = order
                    }
                } label: {
                    Label(order.displayName, systemImage: order.iconName)
                    if sortOrder == order {
                        Image(systemName: "checkmark")
                    }
                }
            }
        } label: {
            Label("Sort", systemImage: "arrow.up.arrow.down")
        }
    }

    // MARK: - Filter Menu

    private var filterMenu: some View {
        Menu {
            Button {
                withAnimation {
                    selectedType = nil
                }
            } label: {
                Label("All Types", systemImage: "square.grid.2x2")
                if selectedType == nil {
                    Image(systemName: "checkmark")
                }
            }

            Divider()

            ForEach(RetrospectiveType.allCases, id: \.self) { type in
                Button {
                    withAnimation {
                        selectedType = type
                    }
                } label: {
                    Label(
                        type.displayName,
                        systemImage: type == .weekly ? "calendar" : "calendar.badge.clock"
                    )
                    if selectedType == type {
                        Image(systemName: "checkmark")
                    }
                }
            }
        } label: {
            Label("Filter", systemImage: selectedType != nil ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Retrospectives", systemImage: "doc.text")
        } description: {
            Text("Your past retrospectives will appear here.")
        }
    }

    // MARK: - Computed Properties

    private var filteredRetrospectives: [Retrospective] {
        var results = retrospectives

        // Filter by type
        if let type = selectedType {
            results = results.filter { $0.type == type }
        }

        // Filter by search text
        if !searchText.isEmpty {
            results = results.filter { retro in
                retro.title.localizedCaseInsensitiveContains(searchText) ||
                retro.kptaItems.contains { $0.text.localizedCaseInsensitiveContains(searchText) } ||
                retro.actions.contains { $0.text.localizedCaseInsensitiveContains(searchText) }
            }
        }

        // Sort
        switch sortOrder {
        case .newest:
            results.sort { $0.createdAt > $1.createdAt }
        case .oldest:
            results.sort { $0.createdAt < $1.createdAt }
        case .mostActions:
            results.sort { $0.actions.count > $1.actions.count }
        }

        return results
    }

    private var groupedRetrospectives: [String: [Retrospective]] {
        Dictionary(grouping: filteredRetrospectives) { retro in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: retro.createdAt)
        }
    }

    private var weeklyCount: Int {
        retrospectives.filter { $0.type == .weekly }.count
    }

    private var monthlyCount: Int {
        retrospectives.filter { $0.type == .monthly }.count
    }

    // MARK: - Actions

    private func deleteRetrospective(_ retro: Retrospective) {
        withAnimation {
            modelContext.delete(retro)
        }
    }
}

// MARK: - History Sort Order

enum HistorySortOrder: String, CaseIterable, Identifiable {
    case newest = "Newest First"
    case oldest = "Oldest First"
    case mostActions = "Most Actions"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var iconName: String {
        switch self {
        case .newest: return "arrow.down"
        case .oldest: return "arrow.up"
        case .mostActions: return "checklist"
        }
    }
}

// MARK: - History Row View

struct HistoryRowView: View {
    let retrospective: Retrospective

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Type Icon
            ZStack {
                Circle()
                    .fill(Theme.KPTA.actionBackground)
                    .frame(width: 44, height: 44)

                Image(systemName: retrospective.type == .weekly ? "calendar" : "calendar.badge.clock")
                    .font(.body)
                    .foregroundStyle(Theme.KPTA.action)
            }

            // Content
            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text(retrospective.title)
                    .font(Theme.Typography.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: Theme.Spacing.sm) {
                    Text(relativeDateString)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.secondary)

                    Text("-")
                        .foregroundStyle(.tertiary)

                    kptaSummary
                }
            }

            Spacer()

            // Completion Badge
            if !retrospective.actions.isEmpty {
                completionBadge
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(retrospective.title), \(relativeDateString), \(retrospective.totalKPTACount) items")
    }

    private var kptaSummary: some View {
        HStack(spacing: Theme.Spacing.xxs) {
            Label("\(retrospective.keeps.count)", systemImage: "checkmark.circle")
                .foregroundStyle(Theme.KPTA.keep)

            Label("\(retrospective.problems.count)", systemImage: "exclamationmark.triangle")
                .foregroundStyle(Theme.KPTA.problem)

            Label("\(retrospective.tries.count)", systemImage: "lightbulb")
                .foregroundStyle(Theme.KPTA.try)
        }
        .font(Theme.Typography.caption)
        .labelStyle(.iconOnly)
    }

    private var completionBadge: some View {
        Text("\(retrospective.completedActionsCount)/\(retrospective.actions.count)")
            .font(Theme.Typography.caption)
            .foregroundStyle(completionColor)
            .padding(.horizontal, Theme.Spacing.xs)
            .padding(.vertical, 2)
            .background(completionColor.opacity(0.15))
            .clipShape(Capsule())
    }

    private var completionColor: Color {
        let rate = retrospective.actionCompletionRate
        if rate >= 1.0 {
            return Theme.Semantic.completed
        } else if rate >= 0.5 {
            return Theme.Semantic.warning
        } else {
            return .secondary
        }
    }

    private var relativeDateString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: retrospective.createdAt, relativeTo: Date())
    }
}

// MARK: - Preview

#Preview("With Data") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Retrospective.self, KPTAItem.self, ActionItem.self, HealthSummary.self,
        configurations: config
    )

    let context = container.mainContext

    // Add sample retrospectives
    for i in 0..<5 {
        let retro = Retrospective(
            title: i % 2 == 0 ? "Week of Nov \(25 - i * 7)" : "November 2024",
            type: i % 2 == 0 ? .weekly : .monthly,
            startDate: Calendar.current.date(byAdding: .day, value: -i * 7, to: Date())!,
            endDate: Date(),
            createdAt: Calendar.current.date(byAdding: .day, value: -i * 7, to: Date())!
        )

        let keep = KPTAItem(text: "Sample keep item", category: .keep)
        let problem = KPTAItem(text: "Sample problem", category: .problem)
        retro.kptaItems.append(keep)
        retro.kptaItems.append(problem)

        if i < 3 {
            let action = ActionItem(text: "Sample action", isCompleted: i % 2 == 0)
            retro.actions.append(action)
        }

        context.insert(retro)
    }

    return HistoryView()
        .modelContainer(container)
}

#Preview("Empty State") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Retrospective.self, KPTAItem.self, ActionItem.self, HealthSummary.self,
        configurations: config
    )

    return HistoryView()
        .modelContainer(container)
}
