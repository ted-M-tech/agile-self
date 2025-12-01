//
//  KPTAWizardView.swift
//  agile-self
//
//  Created by Claude on 2025/12/01.
//

import SwiftUI
import SwiftData

/// A clean, step-by-step wizard for creating KPTA retrospectives
struct KPTAWizardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = KPTAEntryViewModel()
    @State private var currentStep: KPTAWizardStep = .setup
    @State private var showDiscardAlert = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress bar
                KPTAWizardProgressBar(currentStep: currentStep) { step in
                    withAnimation(Theme.Animation.smooth) {
                        currentStep = step
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)

                // Step content
                stepContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Bottom navigation
                bottomNavigation
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        handleCancel()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text("Step \(currentStep.rawValue + 1) of \(KPTAWizardStep.allCases.count)")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.secondary)
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
        .interactiveDismissDisabled(viewModel.totalItemCount > 0)
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        Group {
            switch currentStep {
            case .setup:
                KPTASetupStepView(
                    retroType: $viewModel.retroType,
                    startDate: $viewModel.startDate,
                    endDate: $viewModel.endDate,
                    onSelectPreviousPeriod: viewModel.selectPreviousPeriod,
                    onSelectNextPeriod: viewModel.selectNextPeriod,
                    onSelectCurrentPeriod: viewModel.selectCurrentPeriod
                )

            case .keep:
                KPTAInputStepView(
                    step: .keep,
                    items: $viewModel.keeps,
                    onAddItem: viewModel.addKeep,
                    onRemoveItem: viewModel.removeKeep
                )

            case .problem:
                KPTAInputStepView(
                    step: .problem,
                    items: $viewModel.problems,
                    onAddItem: viewModel.addProblem,
                    onRemoveItem: viewModel.removeProblem
                )

            case .tryStep:
                KPTATryInputStepView(
                    step: .tryStep,
                    items: $viewModel.tries,
                    onAddItem: viewModel.addTry,
                    onRemoveItem: viewModel.removeTry
                )

            case .review:
                KPTAReviewStepView(
                    keeps: viewModel.keeps,
                    problems: viewModel.problems,
                    tries: viewModel.tries,
                    actions: $viewModel.tries,
                    onEditSection: { step in
                        withAnimation(Theme.Animation.smooth) {
                            currentStep = step
                        }
                    }
                )
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }

    // MARK: - Bottom Navigation

    private var bottomNavigation: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Back button
            if !currentStep.isFirst {
                Button {
                    goToPreviousStep()
                } label: {
                    HStack(spacing: Theme.Spacing.xxs) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(Theme.Typography.body)
                    .foregroundStyle(.primary)
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.vertical, Theme.Spacing.sm)
                }
                .buttonStyle(.plain)
            } else {
                Spacer()
            }

            Spacer()

            // Next/Save button
            Button {
                if currentStep.isLast {
                    saveRetrospective()
                } else {
                    goToNextStep()
                }
            } label: {
                HStack(spacing: Theme.Spacing.xxs) {
                    if viewModel.isSaving {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(currentStep.isLast ? "Save" : "Next")
                        if !currentStep.isLast {
                            Image(systemName: "chevron.right")
                        }
                    }
                }
                .font(Theme.Typography.body.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, Theme.Spacing.sm)
                .background(nextButtonColor)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(!canProceed || viewModel.isSaving)
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md)
        .background(.ultraThinMaterial)
    }

    // MARK: - Navigation Logic

    private var canProceed: Bool {
        switch currentStep {
        case .setup:
            return true
        case .keep, .problem, .tryStep:
            return true // Allow proceeding even with empty items
        case .review:
            return viewModel.canSave
        }
    }

    private var nextButtonColor: Color {
        if currentStep.isLast {
            return viewModel.canSave ? Theme.KPTA.action : Color.gray
        }
        return currentStep.color
    }

    private func goToNextStep() {
        guard let next = currentStep.next else { return }
        withAnimation(Theme.Animation.smooth) {
            currentStep = next
        }
    }

    private func goToPreviousStep() {
        guard let previous = currentStep.previous else { return }
        withAnimation(Theme.Animation.smooth) {
            currentStep = previous
        }
    }

    private func handleCancel() {
        if viewModel.totalItemCount > 0 {
            showDiscardAlert = true
        } else {
            dismiss()
        }
    }

    private func saveRetrospective() {
        Task {
            _ = await viewModel.save(using: modelContext)
        }
    }
}

// MARK: - Preview

#Preview("Setup Step") {
    KPTAWizardView()
        .modelContainer(for: [
            Retrospective.self,
            KPTAItem.self,
            ActionItem.self,
            HealthSummary.self
        ], inMemory: true)
}
