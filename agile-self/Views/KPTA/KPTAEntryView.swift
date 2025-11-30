//
//  KPTAEntryView.swift
//  agile-self
//
//  Created by Claude on 2025/11/30.
//

import SwiftUI
import SwiftData

/// Main view for creating a new KPTA retrospective
struct KPTAEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = KPTAEntryViewModel()
    @State private var showDiscardAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    // Date Range Picker
                    DateRangePickerView(viewModel: viewModel)

                    // KPTA Sections
                    kptaSections

                    // Summary Card
                    if viewModel.totalItemCount > 0 {
                        summaryCard
                    }

                    // Save Button
                    saveButton
                        .padding(.bottom, Theme.Spacing.xl)
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.md)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("New Retrospective")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        handleCancel()
                    }
                }

                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") {
                            hideKeyboard()
                        }
                    }
                }
            }
            .alert("Discard Changes?", isPresented: $showDiscardAlert) {
                Button("Discard", role: .destructive) {
                    dismiss()
                }
                Button("Keep Editing", role: .cancel) {}
            } message: {
                Text("You have unsaved changes. Are you sure you want to discard them?")
            }
            .alert("Error", isPresented: $viewModel.showValidationError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.validationErrorMessage)
            }
            .onChange(of: viewModel.showSuccessMessage) { _, showSuccess in
                if showSuccess {
                    dismiss()
                }
            }
        }
    }

    // MARK: - KPTA Sections

    private var kptaSections: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Keep Section
            KPTASectionView(
                category: .keep,
                items: $viewModel.keeps,
                onAdd: viewModel.addKeep,
                onRemove: viewModel.removeKeep
            )

            // Problem Section
            KPTASectionView(
                category: .problem,
                items: $viewModel.problems,
                onAdd: viewModel.addProblem,
                onRemove: viewModel.removeProblem
            )

            // Try Section (with action creation)
            TrySectionView(
                items: $viewModel.tries,
                onAdd: viewModel.addTry,
                onRemove: viewModel.removeTry,
                onToggleAction: viewModel.toggleActionForTry
            )
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Summary")
                .font(Theme.Typography.headline)
                .foregroundStyle(.secondary)

            HStack(spacing: Theme.Spacing.lg) {
                summaryItem(
                    count: viewModel.validKeeps.count,
                    label: "Keep",
                    color: Theme.KPTA.keep
                )

                summaryItem(
                    count: viewModel.validProblems.count,
                    label: "Problem",
                    color: Theme.KPTA.problem
                )

                summaryItem(
                    count: viewModel.validTries.count,
                    label: "Try",
                    color: Theme.KPTA.try
                )

                if viewModel.actionCount > 0 {
                    summaryItem(
                        count: viewModel.actionCount,
                        label: "Action",
                        color: Theme.KPTA.action
                    )
                }
            }
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(summaryAccessibilityLabel)
    }

    private func summaryItem(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: Theme.Spacing.xxs) {
            Text("\(count)")
                .font(Theme.Typography.title2)
                .foregroundStyle(color)

            Text(label)
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(count) \(label) items")
    }

    private var summaryAccessibilityLabel: String {
        var parts: [String] = []
        if viewModel.validKeeps.count > 0 {
            parts.append("\(viewModel.validKeeps.count) keep items")
        }
        if viewModel.validProblems.count > 0 {
            parts.append("\(viewModel.validProblems.count) problem items")
        }
        if viewModel.validTries.count > 0 {
            parts.append("\(viewModel.validTries.count) try items")
        }
        if viewModel.actionCount > 0 {
            parts.append("\(viewModel.actionCount) action items")
        }
        return "Summary: " + parts.joined(separator: ", ")
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            Task {
                await saveRetrospective()
            }
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                if viewModel.isSaving {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                }

                Text(viewModel.isSaving ? "Saving..." : "Save Retrospective")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)
            .background(viewModel.canSave ? Theme.KPTA.action : Color.gray)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
        }
        .disabled(!viewModel.canSave)
        .animation(.easeInOut(duration: 0.2), value: viewModel.canSave)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isSaving)
        .accessibilityLabel(viewModel.isSaving ? "Saving retrospective" : "Save retrospective")
        .accessibilityHint(viewModel.canSave ? "Double tap to save your retrospective" : "Add at least one item to enable saving")
    }

    // MARK: - Actions

    private func handleCancel() {
        if viewModel.totalItemCount > 0 {
            showDiscardAlert = true
        } else {
            dismiss()
        }
    }

    private func saveRetrospective() async {
        let success = await viewModel.save(using: modelContext)
        if success {
            // Success handling is done via onChange of showSuccessMessage
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

// MARK: - Preview

#Preview("Empty State") {
    KPTAEntryView()
        .modelContainer(for: [
            Retrospective.self,
            KPTAItem.self,
            ActionItem.self,
            HealthSummary.self
        ], inMemory: true)
}

#Preview("With Content") {
    let viewModel = KPTAEntryViewModel()
    viewModel.keeps = [
        DraftKPTAItem(text: "Completed all daily standups", category: .keep),
        DraftKPTAItem(text: "Maintained good sleep schedule", category: .keep)
    ]
    viewModel.problems = [
        DraftKPTAItem(text: "Struggled with focus in afternoons", category: .problem)
    ]
    viewModel.tries = [
        DraftTryItem(
            text: "Use Pomodoro technique",
            createAction: true,
            actionText: "Set up Pomodoro timer and use daily"
        )
    ]

    return NavigationStack {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                DateRangePickerView(viewModel: viewModel)

                KPTASectionView(
                    category: .keep,
                    items: .constant(viewModel.keeps),
                    onAdd: {},
                    onRemove: { _ in }
                )

                KPTASectionView(
                    category: .problem,
                    items: .constant(viewModel.problems),
                    onAdd: {},
                    onRemove: { _ in }
                )

                TrySectionView(
                    items: .constant(viewModel.tries),
                    onAdd: {},
                    onRemove: { _ in },
                    onToggleAction: { _ in }
                )
            }
            .padding()
        }
        .navigationTitle("New Retrospective")
    }
}
