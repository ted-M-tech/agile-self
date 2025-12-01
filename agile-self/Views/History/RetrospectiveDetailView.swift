//
//  RetrospectiveDetailView.swift
//  agile-self
//
//  Created by Claude on 2025/12/01.
//

import SwiftUI
import SwiftData

/// Detail view for viewing a retrospective
struct RetrospectiveDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let retrospective: Retrospective

    @State private var showDeleteAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                // Header
                headerSection

                // KPTA Sections
                if !retrospective.keeps.isEmpty {
                    kptaSection(
                        title: "Keep",
                        items: retrospective.keeps,
                        color: Theme.KPTA.keep,
                        icon: "checkmark.circle.fill"
                    )
                }

                if !retrospective.problems.isEmpty {
                    kptaSection(
                        title: "Problem",
                        items: retrospective.problems,
                        color: Theme.KPTA.problem,
                        icon: "exclamationmark.triangle.fill"
                    )
                }

                if !retrospective.tries.isEmpty {
                    kptaSection(
                        title: "Try",
                        items: retrospective.tries,
                        color: Theme.KPTA.`try`,
                        icon: "lightbulb.fill"
                    )
                }

                // Actions
                if !retrospective.actions.isEmpty {
                    actionsSection
                }

                Spacer(minLength: Theme.Spacing.xxl)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.top, Theme.Spacing.md)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(retrospective.type.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
            }
        }
        .alert("Delete Retrospective?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                modelContext.delete(retrospective)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            // Type badge
            Text(retrospective.type.displayName)
                .font(Theme.Typography.caption)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, Theme.Spacing.xxs)
                .background(Theme.KPTA.action)
                .clipShape(Capsule())

            // Title
            Text(retrospective.title)
                .font(Theme.Typography.title2)
                .multilineTextAlignment(.center)

            // Date range
            Text(retrospective.formattedDateRange)
                .font(Theme.Typography.callout)
                .foregroundStyle(.secondary)

            // Stats row
            HStack(spacing: Theme.Spacing.lg) {
                statItem(count: retrospective.keeps.count, label: "K", color: Theme.KPTA.keep)
                statItem(count: retrospective.problems.count, label: "P", color: Theme.KPTA.problem)
                statItem(count: retrospective.tries.count, label: "T", color: Theme.KPTA.`try`)
                statItem(count: retrospective.actions.count, label: "A", color: Theme.KPTA.action)
            }
            .padding(.top, Theme.Spacing.sm)
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
    }

    private func statItem(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(Theme.Typography.title3)
                .fontWeight(.semibold)
                .foregroundStyle(color)
            Text(label)
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - KPTA Section

    private func kptaSection(title: String, items: [KPTAItem], color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Header
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(Theme.Typography.headline)
                Spacer()
                Text("\(items.count)")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
            }

            // Items
            ForEach(items) { item in
                HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                        .padding(.top, 6)

                    Text(item.text)
                        .font(Theme.Typography.body)
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Header
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "checklist")
                    .foregroundStyle(Theme.KPTA.action)
                Text("Actions")
                    .font(Theme.Typography.headline)
                Spacer()
                Text("\(retrospective.actions.count)")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
            }

            // Items
            ForEach(retrospective.actions) { action in
                HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                    Image(systemName: action.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(action.isCompleted ? Theme.KPTA.keep : Theme.KPTA.action)
                        .font(.body)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(action.text)
                            .font(Theme.Typography.body)
                            .strikethrough(action.isCompleted)
                            .foregroundStyle(action.isCompleted ? .secondary : .primary)

                        if let deadline = action.deadline {
                            Text(deadline, style: .date)
                                .font(Theme.Typography.caption)
                                .foregroundStyle(action.isOverdue ? Theme.KPTA.problem : .secondary)
                        }
                    }
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
    }
}

// MARK: - Preview

#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Retrospective.self, KPTAItem.self, ActionItem.self, HealthSummary.self,
            configurations: config
        )

        let retro = Retrospective(
            title: "Week of Dec 1",
            type: .weekly,
            startDate: Date(),
            endDate: Date()
        )

        return NavigationStack {
            RetrospectiveDetailView(retrospective: retro)
        }
        .modelContainer(container)
    } catch {
        return Text("Preview Error: \(error.localizedDescription)")
    }
}
