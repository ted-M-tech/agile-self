//
//  KPTAReviewStepView.swift
//  agile-self
//
//  Created by Claude on 2025/12/01.
//

import SwiftUI

/// A clean summary view showing all entries before saving
struct KPTAReviewStepView: View {
    let keeps: [DraftKPTAItem]
    let problems: [DraftKPTAItem]
    let tries: [DraftTryItem]
    @Binding var actions: [DraftTryItem]

    let onEditSection: (KPTAWizardStep) -> Void

    @State private var expandedSection: KPTACategory?

    private var validKeeps: [DraftKPTAItem] { keeps.filter { $0.isValid } }
    private var validProblems: [DraftKPTAItem] { problems.filter { $0.isValid } }
    private var validTries: [DraftTryItem] { tries.filter { $0.isValid } }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                // Header
                stepHeader
                    .padding(.top, Theme.Spacing.lg)
                    .padding(.bottom, Theme.Spacing.md)

                // Summary cards
                VStack(spacing: Theme.Spacing.sm) {
                    SummaryCard(
                        category: .keep,
                        items: validKeeps.map { $0.text },
                        isExpanded: expandedSection == .keep,
                        onToggle: { toggleSection(.keep) },
                        onEdit: { onEditSection(.keep) }
                    )

                    SummaryCard(
                        category: .problem,
                        items: validProblems.map { $0.text },
                        isExpanded: expandedSection == .problem,
                        onToggle: { toggleSection(.problem) },
                        onEdit: { onEditSection(.problem) }
                    )

                    SummaryCard(
                        category: .try,
                        items: validTries.map { $0.text },
                        isExpanded: expandedSection == .try,
                        onToggle: { toggleSection(.try) },
                        onEdit: { onEditSection(.tryStep) }
                    )
                }
                .padding(.horizontal, Theme.Spacing.md)

                // Actions section
                if !validTries.isEmpty {
                    actionsSection
                        .padding(.horizontal, Theme.Spacing.md)
                }

                Spacer(minLength: Theme.Spacing.xxl)
            }
        }
    }

    // MARK: - Header

    private var stepHeader: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Theme.KPTA.action.opacity(0.3))

            Text("Review")
                .font(.title)
                .fontWeight(.bold)

            Text(summaryText)
                .font(Theme.Typography.callout)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, Theme.Spacing.lg)
    }

    private var summaryText: String {
        let total = validKeeps.count + validProblems.count + validTries.count
        return "\(total) items ready to save"
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Image(systemName: "checklist")
                    .foregroundStyle(Theme.KPTA.action)
                Text("Actions")
                    .font(Theme.Typography.headline)
                Spacer()
            }
            .padding(.top, Theme.Spacing.md)

            Text("Each Try becomes an Action item")
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)

            ForEach($actions) { $item in
                if item.isValid {
                    ActionPreviewCard(item: $item)
                }
            }
        }
    }

    private func toggleSection(_ category: KPTACategory) {
        withAnimation(Theme.Animation.smooth) {
            if expandedSection == category {
                expandedSection = nil
            } else {
                expandedSection = category
            }
        }
    }
}

// MARK: - Summary Card

private struct SummaryCard: View {
    let category: KPTACategory
    let items: [String]
    let isExpanded: Bool
    let onToggle: () -> Void
    let onEdit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header row
            Button(action: onToggle) {
                HStack(spacing: Theme.Spacing.sm) {
                    Circle()
                        .fill(category.color)
                        .frame(width: 10, height: 10)

                    Text(category.displayName)
                        .font(Theme.Typography.headline)

                    Spacer()

                    Text("\(items.count)")
                        .font(Theme.Typography.callout)
                        .foregroundStyle(.secondary)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(Theme.Spacing.md)
            }
            .buttonStyle(.plain)

            // Expanded content
            if isExpanded {
                Divider()
                    .padding(.horizontal, Theme.Spacing.md)

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    ForEach(items, id: \.self) { item in
                        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                            Circle()
                                .fill(category.color.opacity(0.3))
                                .frame(width: 6, height: 6)
                                .padding(.top, 6)

                            Text(item)
                                .font(Theme.Typography.body)
                                .foregroundStyle(.primary)
                        }
                    }

                    // Edit button
                    Button(action: onEdit) {
                        HStack {
                            Image(systemName: "pencil")
                            Text("Edit")
                        }
                        .font(Theme.Typography.callout)
                        .foregroundStyle(category.color)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, Theme.Spacing.xs)
                }
                .padding(Theme.Spacing.md)
                .padding(.top, 0)
            }
        }
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
    }
}

// MARK: - Action Preview Card

private struct ActionPreviewCard: View {
    @Binding var item: DraftTryItem
    @State private var showDeadlinePicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Action text
            Text(item.text)
                .font(Theme.Typography.body)

            // Deadline row
            HStack {
                Button {
                    showDeadlinePicker.toggle()
                } label: {
                    HStack(spacing: Theme.Spacing.xxs) {
                        Image(systemName: item.actionDeadline != nil ? "calendar.badge.checkmark" : "calendar.badge.plus")
                            .foregroundStyle(Theme.KPTA.action)

                        if let deadline = item.actionDeadline {
                            Text(formattedDate(deadline))
                                .font(Theme.Typography.caption)
                        } else {
                            Text("Add deadline")
                                .font(Theme.Typography.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                if item.actionDeadline != nil {
                    Button {
                        item.actionDeadline = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            if showDeadlinePicker {
                DatePicker(
                    "Deadline",
                    selection: Binding(
                        get: { item.actionDeadline ?? Date() },
                        set: { item.actionDeadline = $0 }
                    ),
                    in: Date()...,
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
                .labelsHidden()
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.KPTA.actionBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.small))
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    KPTAReviewStepView(
        keeps: [
            DraftKPTAItem(text: "Completed daily standups", category: .keep),
            DraftKPTAItem(text: "Good sleep schedule", category: .keep)
        ],
        problems: [
            DraftKPTAItem(text: "Struggled with focus", category: .problem)
        ],
        tries: [
            DraftTryItem(text: "Use Pomodoro technique"),
            DraftTryItem(text: "Morning exercise routine")
        ],
        actions: .constant([
            DraftTryItem(text: "Use Pomodoro technique", actionDeadline: Date()),
            DraftTryItem(text: "Morning exercise routine")
        ]),
        onEditSection: { _ in }
    )
}
