//
//  AddActionView.swift
//  agile-self
//
//  Created by Claude on 2025/11/30.
//

import SwiftUI
import SwiftData

/// A sheet view for quickly adding a new action item
struct AddActionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var actionText: String = ""
    @State private var priority: ActionPriority = .medium
    @State private var hasDeadline: Bool = false
    @State private var deadline: Date = Date()
    @State private var showPriorityPicker = false
    @State private var isSaving = false

    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Main Input Area
                inputArea

                Divider()

                // Options Bar
                optionsBar

                Spacer()
            }
            .navigationTitle("New Action")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        saveAction()
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Add")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(!canSave)
                }

                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") {
                            isTextFieldFocused = false
                        }
                    }
                }
            }
            .onAppear {
                // Set default deadline to tomorrow
                deadline = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                // Auto-focus the text field
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(500))
                    isTextFieldFocused = true
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Input Area

    private var inputArea: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Action Text Field
            HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                Image(systemName: "circle")
                    .font(.title2)
                    .foregroundStyle(Theme.KPTA.action.opacity(0.5))
                    .padding(.top, 2)

                TextField(
                    "What do you want to accomplish?",
                    text: $actionText,
                    axis: .vertical
                )
                .lineLimit(1...5)
                .font(Theme.Typography.body)
                .focused($isTextFieldFocused)
                .submitLabel(.done)
                .accessibilityLabel("Action text")
            }

            // Deadline Display (if set)
            if hasDeadline {
                deadlineDisplay
            }
        }
        .padding(Theme.Spacing.md)
    }

    // MARK: - Deadline Display

    private var deadlineDisplay: some View {
        HStack {
            Image(systemName: "calendar")
                .foregroundStyle(Theme.KPTA.action)

            Text("Due: \(formattedDeadline)")
                .font(Theme.Typography.callout)
                .foregroundStyle(.primary)

            Spacer()

            Button {
                withAnimation {
                    hasDeadline = false
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove deadline")
        }
        .padding(Theme.Spacing.sm)
        .background(Theme.KPTA.actionBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.small))
    }

    // MARK: - Options Bar

    private var optionsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.md) {
                // Priority Button
                priorityButton

                // Deadline Button
                deadlineButton
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
        }
    }

    // MARK: - Priority Button

    private var priorityButton: some View {
        Menu {
            ForEach(ActionPriority.allCases, id: \.self) { priorityOption in
                Button {
                    withAnimation {
                        priority = priorityOption
                    }
                } label: {
                    Label(priorityOption.displayName, systemImage: priorityOption.iconName)
                    if priority == priorityOption {
                        Image(systemName: "checkmark")
                    }
                }
            }
        } label: {
            HStack(spacing: Theme.Spacing.xxs) {
                Image(systemName: priority.iconName)
                    .foregroundStyle(priority.color)
                Text(priority.displayName)
                    .font(Theme.Typography.callout)
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(.regularMaterial)
            .clipShape(Capsule())
        }
        .accessibilityLabel("Priority: \(priority.displayName)")
        .accessibilityHint("Double tap to change priority")
    }

    // MARK: - Deadline Button

    private var deadlineButton: some View {
        Menu {
            // Quick Options
            Button {
                setDeadline(.today)
            } label: {
                Label("Today", systemImage: "sun.max")
            }

            Button {
                setDeadline(.tomorrow)
            } label: {
                Label("Tomorrow", systemImage: "sunrise")
            }

            Button {
                setDeadline(.nextWeek)
            } label: {
                Label("Next Week", systemImage: "calendar.badge.plus")
            }

            Divider()

            // Custom Date Picker
            Button {
                // Show date picker - for now just set to next week
                setDeadline(.custom(Date()))
            } label: {
                Label("Pick a Date...", systemImage: "calendar")
            }

            if hasDeadline {
                Divider()

                Button(role: .destructive) {
                    withAnimation {
                        hasDeadline = false
                    }
                } label: {
                    Label("Remove Deadline", systemImage: "xmark.circle")
                }
            }
        } label: {
            HStack(spacing: Theme.Spacing.xxs) {
                Image(systemName: hasDeadline ? "calendar.badge.checkmark" : "calendar")
                    .foregroundStyle(hasDeadline ? Theme.KPTA.action : .secondary)
                Text(hasDeadline ? formattedDeadline : "Add Deadline")
                    .font(Theme.Typography.callout)
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .foregroundStyle(hasDeadline ? .primary : .secondary)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(.regularMaterial)
            .clipShape(Capsule())
        }
        .accessibilityLabel(hasDeadline ? "Deadline: \(formattedDeadline)" : "Add deadline")
        .accessibilityHint("Double tap to set a deadline")
    }

    // MARK: - Computed Properties

    private var canSave: Bool {
        !actionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSaving
    }

    private var formattedDeadline: String {
        let calendar = Calendar.current

        if calendar.isDateInToday(deadline) {
            return "Today"
        } else if calendar.isDateInTomorrow(deadline) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE, MMM d"
            return formatter.string(from: deadline)
        }
    }

    // MARK: - Actions

    private enum DeadlineOption {
        case today
        case tomorrow
        case nextWeek
        case custom(Date)
    }

    private func setDeadline(_ option: DeadlineOption) {
        withAnimation {
            hasDeadline = true

            switch option {
            case .today:
                deadline = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: Date()) ?? Date()
            case .tomorrow:
                deadline = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            case .nextWeek:
                deadline = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date()) ?? Date()
            case .custom(let date):
                deadline = date
            }
        }
    }

    private func saveAction() {
        guard canSave else { return }

        isSaving = true

        let newAction = ActionItem(
            text: actionText.trimmingCharacters(in: .whitespacesAndNewlines),
            deadline: hasDeadline ? deadline : nil,
            priority: priority
        )

        modelContext.insert(newAction)

        // Dismiss after a brief delay for visual feedback
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            dismiss()
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
        return AddActionView()
            .modelContainer(container)
    } catch {
        return Text("Preview Error: \(error.localizedDescription)")
    }
}
