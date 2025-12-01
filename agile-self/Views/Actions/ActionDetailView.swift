//
//  ActionDetailView.swift
//  agile-self
//
//  Created by Claude on 2025/11/30.
//

import SwiftUI
import SwiftData

/// Detail view for viewing and editing an action item
struct ActionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var action: ActionItem

    @State private var editedText: String = ""
    @State private var editedPriority: ActionPriority = .medium
    @State private var editedDeadline: Date = Date()
    @State private var hasDeadline: Bool = false
    @State private var editedNotes: String = ""
    @State private var showDeleteAlert = false
    @State private var hasChanges = false

    var body: some View {
        NavigationStack {
            Form {
                // Action Text Section
                actionTextSection

                // Priority Section
                prioritySection

                // Deadline Section
                deadlineSection

                // Notes Section
                notesSection

                // Source Section
                if action.fromTryItem || action.retrospective != nil {
                    sourceSection
                }

                // Completion Status Section
                completionSection

                // Delete Section
                deleteSection
            }
            .navigationTitle("Action Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                    .disabled(!canSave)
                    .fontWeight(.semibold)
                }
            }
            .alert("Delete Action", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    deleteAction()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this action? This cannot be undone.")
            }
            .onAppear {
                loadCurrentValues()
            }
            .onChange(of: editedText) { _, _ in checkForChanges() }
            .onChange(of: editedPriority) { _, _ in checkForChanges() }
            .onChange(of: editedDeadline) { _, _ in checkForChanges() }
            .onChange(of: hasDeadline) { _, _ in checkForChanges() }
            .onChange(of: editedNotes) { _, _ in checkForChanges() }
        }
    }

    // MARK: - Action Text Section

    private var actionTextSection: some View {
        Section {
            TextField("Action", text: $editedText, axis: .vertical)
                .lineLimit(1...5)
                .font(Theme.Typography.body)
                .accessibilityLabel("Action text")
        } header: {
            Label("Action", systemImage: "text.alignleft")
        }
    }

    // MARK: - Priority Section

    private var prioritySection: some View {
        Section {
            Picker("Priority", selection: $editedPriority) {
                ForEach(ActionPriority.allCases, id: \.self) { priority in
                    HStack {
                        Image(systemName: priority.iconName)
                            .foregroundStyle(priority.color)
                        Text(priority.displayName)
                    }
                    .tag(priority)
                }
            }
            .pickerStyle(.menu)
            .accessibilityLabel("Priority")
        } header: {
            Label("Priority", systemImage: "exclamationmark.3")
        }
    }

    // MARK: - Deadline Section

    private var deadlineSection: some View {
        Section {
            Toggle(isOn: $hasDeadline.animation()) {
                Label("Set Deadline", systemImage: "calendar")
            }

            if hasDeadline {
                DatePicker(
                    "Due Date",
                    selection: $editedDeadline,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .accessibilityLabel("Due date")

                if isDeadlineOverdue {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Theme.Semantic.overdue)
                        Text("This deadline is in the past")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Semantic.overdue)
                    }
                }
            }
        } header: {
            Label("Deadline", systemImage: "calendar")
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        Section {
            TextField("Add notes...", text: $editedNotes, axis: .vertical)
                .lineLimit(3...8)
                .font(Theme.Typography.body)
                .accessibilityLabel("Notes")
        } header: {
            Label("Notes", systemImage: "note.text")
        } footer: {
            Text("Add any additional context or details for this action.")
        }
    }

    // MARK: - Source Section

    private var sourceSection: some View {
        Section {
            if action.fromTryItem {
                HStack {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundStyle(Theme.KPTA.try)
                    Text("Created from a Try item")
                        .font(Theme.Typography.body)
                }
            }

            if let retrospective = action.retrospective {
                NavigationLink {
                    // TODO: Navigate to retrospective detail view
                    Text("Retrospective: \(retrospective.title)")
                } label: {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .foregroundStyle(Theme.KPTA.action)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("From Retrospective")
                                .font(Theme.Typography.body)
                            Text(retrospective.title)
                                .font(Theme.Typography.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        } header: {
            Label("Source", systemImage: "link")
        }
    }

    // MARK: - Completion Section

    private var completionSection: some View {
        Section {
            HStack {
                Label(
                    action.isCompleted ? "Completed" : "Not Completed",
                    systemImage: action.isCompleted ? "checkmark.circle.fill" : "circle"
                )
                .foregroundStyle(action.isCompleted ? Theme.Semantic.completed : .primary)

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        if action.isCompleted {
                            action.markIncomplete()
                        } else {
                            action.markCompleted()
                        }
                    }
                } label: {
                    Text(action.isCompleted ? "Mark Incomplete" : "Mark Complete")
                        .font(Theme.Typography.callout)
                }
                .buttonStyle(.bordered)
                .tint(action.isCompleted ? .orange : .green)
            }

            if action.isCompleted, let completedAt = action.completedAt {
                HStack {
                    Text("Completed on")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(formattedDate(completedAt))
                        .foregroundStyle(.secondary)
                }
                .font(Theme.Typography.caption)
            }

            HStack {
                Text("Created on")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(formattedDate(action.createdAt))
                    .foregroundStyle(.secondary)
            }
            .font(Theme.Typography.caption)
        } header: {
            Label("Status", systemImage: "checkmark.circle")
        }
    }

    // MARK: - Delete Section

    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                showDeleteAlert = true
            } label: {
                HStack {
                    Spacer()
                    Label("Delete Action", systemImage: "trash")
                    Spacer()
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var canSave: Bool {
        !editedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var isDeadlineOverdue: Bool {
        hasDeadline && editedDeadline < Date()
    }

    // MARK: - Helper Methods

    private func loadCurrentValues() {
        editedText = action.text
        editedPriority = action.priority
        editedNotes = action.notes ?? ""
        hasDeadline = action.deadline != nil
        if let deadline = action.deadline {
            editedDeadline = deadline
        } else {
            // Default to tomorrow for new deadlines
            editedDeadline = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        }
    }

    private func checkForChanges() {
        let textChanged = editedText != action.text
        let priorityChanged = editedPriority != action.priority
        let notesChanged = editedNotes != (action.notes ?? "")
        let deadlineChanged: Bool = {
            if hasDeadline && action.deadline != nil {
                return editedDeadline != action.deadline
            } else if hasDeadline != (action.deadline != nil) {
                return true
            }
            return false
        }()

        hasChanges = textChanged || priorityChanged || notesChanged || deadlineChanged
    }

    private func saveChanges() {
        action.updateText(editedText)
        action.priority = editedPriority
        action.notes = editedNotes.isEmpty ? nil : editedNotes
        action.deadline = hasDeadline ? editedDeadline : nil
        action.updatedAt = Date()
    }

    private func deleteAction() {
        modelContext.delete(action)
        dismiss()
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview("Active Action") {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: ActionItem.self, Retrospective.self, KPTAItem.self, HealthSummary.self,
            configurations: config
        )

        let action = ActionItem(
            text: "Set up Pomodoro timer and use daily for focused work sessions",
            deadline: Calendar.current.date(byAdding: .day, value: 2, to: Date()),
            fromTryItem: true,
            priority: .high,
            notes: "Need to find a good timer app first"
        )

        container.mainContext.insert(action)

        return ActionDetailView(action: action)
            .modelContainer(container)
    } catch {
        return Text("Preview Error: \(error.localizedDescription)")
    }
}

#Preview("Completed Action") {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: ActionItem.self, Retrospective.self, KPTAItem.self, HealthSummary.self,
            configurations: config
        )

        let action = ActionItem(
            text: "Review weekly goals every Monday morning",
            isCompleted: true,
            completedAt: Date(),
            priority: .medium
        )

        container.mainContext.insert(action)

        return ActionDetailView(action: action)
            .modelContainer(container)
    } catch {
        return Text("Preview Error: \(error.localizedDescription)")
    }
}
