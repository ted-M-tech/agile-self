//
//  KPTAWizardProgressBar.swift
//  agile-self
//
//  Created by Claude on 2025/12/01.
//

import SwiftUI

/// A minimal progress indicator showing wizard steps as dots
struct KPTAWizardProgressBar: View {
    let currentStep: KPTAWizardStep
    let onStepTap: (KPTAWizardStep) -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(KPTAWizardStep.allCases) { step in
                stepDot(for: step)
            }
        }
        .padding(.vertical, Theme.Spacing.sm)
    }

    @ViewBuilder
    private func stepDot(for step: KPTAWizardStep) -> some View {
        let isCompleted = step.rawValue < currentStep.rawValue
        let isCurrent = step == currentStep

        Button {
            if isCompleted {
                onStepTap(step)
            }
        } label: {
            Circle()
                .fill(dotColor(isCompleted: isCompleted, isCurrent: isCurrent, step: step))
                .frame(width: isCurrent ? 10 : 8, height: isCurrent ? 10 : 8)
                .animation(Theme.Animation.smooth, value: currentStep)
        }
        .buttonStyle(.plain)
        .disabled(!isCompleted)
        .accessibilityLabel("\(step.title), \(accessibilityStatus(isCompleted: isCompleted, isCurrent: isCurrent))")
        .accessibilityHint(isCompleted ? "Double tap to go back to this step" : "")
    }

    private func dotColor(isCompleted: Bool, isCurrent: Bool, step: KPTAWizardStep) -> Color {
        if isCurrent {
            return step.color
        } else if isCompleted {
            return step.color.opacity(0.5)
        } else {
            return Color(.systemGray4)
        }
    }

    private func accessibilityStatus(isCompleted: Bool, isCurrent: Bool) -> String {
        if isCurrent {
            return "current step"
        } else if isCompleted {
            return "completed"
        } else {
            return "not started"
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        ForEach(KPTAWizardStep.allCases) { step in
            VStack {
                Text("Step: \(step.title)")
                    .font(.caption)
                KPTAWizardProgressBar(currentStep: step) { _ in }
            }
        }
    }
    .padding()
}
