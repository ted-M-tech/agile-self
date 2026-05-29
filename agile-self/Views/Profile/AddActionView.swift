//
//  AddActionView.swift
//  agile-self
//
//  Modal sheet for creating a manual action item. Reports the new action via a
//  callback; does not touch SwiftData directly.
//

import SwiftUI

struct AddActionView: View {
    var onAdd: (String, ActionPriority, Date?) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var text: String = ""
    @State private var priority: ActionPriority = .medium
    @State private var hasDeadline: Bool = false
    @State private var deadline: Date = Date()

    /// Cap action text so a single action stays a short, actionable line (and the row never
    /// has to render an essay).
    private let maxLength = 120

    private var isValid: Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= maxLength
    }

    /// Earliest selectable deadline — today (a deadline already in the past makes no sense).
    private var earliestDeadline: Date {
        Calendar.current.startOfDay(for: Date())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    actionTextSection
                    prioritySection
                    deadlineSection
                }
                .padding(Theme.Spacing.md)
            }
            .background(Theme.Colors.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("New Action")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        onAdd(text, priority, hasDeadline ? deadline : nil)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Action Text

    private var actionTextSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionLabel("ACTION")

            TextField("What do you want to do?", text: $text, axis: .vertical)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textPrimary)
                .lineLimit(2...5)
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
                .accessibilityLabel("Action text")
                .onChange(of: text) { _, newValue in
                    if newValue.count > maxLength {
                        text = String(newValue.prefix(maxLength))
                    }
                }

            // Character counter — turns warning-colored as the user nears the cap.
            Text("\(text.count)/\(maxLength)")
                .font(Theme.Typography.caption)
                .foregroundStyle(text.count >= maxLength ? Theme.Colors.warning : Theme.Colors.textTertiary)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .accessibilityHidden(true)
        }
    }

    // MARK: - Priority

    private var prioritySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionLabel("PRIORITY")

            Picker("Priority", selection: $priority) {
                ForEach(ActionPriority.allCases, id: \.self) { priority in
                    Text(priority.displayName).tag(priority)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Deadline

    private var deadlineSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Toggle(isOn: $hasDeadline) {
                Text("Set a deadline")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textPrimary)
            }
            .tint(Theme.Colors.accentStart)

            if hasDeadline {
                DatePicker(
                    "Deadline",
                    selection: $deadline,
                    in: earliestDeadline...,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .tint(Theme.Colors.accentStart)
            }
        }
    }

    // MARK: - Helpers

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(Theme.Typography.caption)
            .fontWeight(.semibold)
            .foregroundStyle(Theme.Colors.textTertiary)
            .tracking(1.2)
    }
}

// MARK: - Preview

#Preview {
    AddActionView { _, _, _ in }
        .preferredColorScheme(.dark)
}
