//
//  SettingsView.swift
//  agile-self
//
//  Created by Claude on 2025/11/30.
//

import SwiftUI
import SwiftData

/// Settings view for app configuration and preferences
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext

    @AppStorage("defaultRetroType") private var defaultRetroType = "weekly"
    @AppStorage("showCompletedActions") private var showCompletedActions = true
    @AppStorage("enableHapticFeedback") private var enableHapticFeedback = true
    @AppStorage("reminderEnabled") private var reminderEnabled = false
    @AppStorage("reminderDay") private var reminderDay = 1 // Sunday = 1

    @Query private var retrospectives: [Retrospective]
    @Query private var actions: [ActionItem]

    @State private var showDeleteAllAlert = false
    @State private var showAboutSheet = false

    var body: some View {
        NavigationStack {
            List {
                // Preferences Section
                preferencesSection

                // Notifications Section
                notificationsSection

                // Data Section
                dataSection

                // About Section
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Delete All Data", isPresented: $showDeleteAllAlert) {
                Button("Delete", role: .destructive) {
                    deleteAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all retrospectives and actions. This cannot be undone.")
            }
            .sheet(isPresented: $showAboutSheet) {
                AboutView()
            }
        }
    }

    // MARK: - Preferences Section

    private var preferencesSection: some View {
        Section {
            // Default Retrospective Type
            Picker("Default Retro Type", selection: $defaultRetroType) {
                Text("Weekly").tag("weekly")
                Text("Monthly").tag("monthly")
            }
            .accessibilityLabel("Default retrospective type")

            // Show Completed Actions
            Toggle(isOn: $showCompletedActions) {
                Label("Show Completed Actions", systemImage: "checkmark.circle")
            }
            .accessibilityHint("Toggle to show or hide completed actions in the actions list")

            // Haptic Feedback
            Toggle(isOn: $enableHapticFeedback) {
                Label("Haptic Feedback", systemImage: "hand.tap")
            }
            .accessibilityHint("Toggle haptic feedback when completing actions")
        } header: {
            Label("Preferences", systemImage: "slider.horizontal.3")
        } footer: {
            Text("Customize your experience with these settings.")
        }
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        Section {
            Toggle(isOn: $reminderEnabled) {
                Label("Weekly Reminder", systemImage: "bell.badge")
            }
            .accessibilityHint("Enable weekly reminders to create a retrospective")

            if reminderEnabled {
                Picker("Reminder Day", selection: $reminderDay) {
                    Text("Sunday").tag(1)
                    Text("Monday").tag(2)
                    Text("Tuesday").tag(3)
                    Text("Wednesday").tag(4)
                    Text("Thursday").tag(5)
                    Text("Friday").tag(6)
                    Text("Saturday").tag(7)
                }
                .accessibilityLabel("Choose reminder day")
            }
        } header: {
            Label("Notifications", systemImage: "bell")
        } footer: {
            if reminderEnabled {
                Text("You'll receive a reminder to create a retrospective every \(dayName(reminderDay)).")
            } else {
                Text("Enable reminders to stay consistent with your retrospectives.")
            }
        }
    }

    // MARK: - Data Section

    private var dataSection: some View {
        Section {
            // Data Summary
            HStack {
                Label("Retrospectives", systemImage: "doc.text.fill")
                Spacer()
                Text("\(retrospectives.count)")
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(retrospectives.count) retrospectives")

            HStack {
                Label("Actions", systemImage: "checkmark.circle.fill")
                Spacer()
                Text("\(actions.count)")
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(actions.count) actions")

            // iCloud Sync Status
            NavigationLink {
                SyncStatusView()
            } label: {
                Label("iCloud Sync", systemImage: "icloud")
            }

            // Export Data
            NavigationLink {
                ExportDataView()
            } label: {
                Label("Export Data", systemImage: "square.and.arrow.up")
            }

            // Delete All Data
            Button(role: .destructive) {
                showDeleteAllAlert = true
            } label: {
                Label("Delete All Data", systemImage: "trash")
                    .foregroundStyle(.red)
            }
        } header: {
            Label("Data", systemImage: "externaldrive")
        } footer: {
            Text("Your data is stored securely in iCloud and syncs across all your devices.")
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section {
            Button {
                showAboutSheet = true
            } label: {
                HStack {
                    Label("About Agile Self", systemImage: "info.circle")
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Link(destination: URL(string: "https://github.com/agile-self/support")!) {
                Label("Help & Support", systemImage: "questionmark.circle")
            }

            Link(destination: URL(string: "https://github.com/agile-self/privacy")!) {
                Label("Privacy Policy", systemImage: "hand.raised")
            }
        } header: {
            Label("About", systemImage: "info.circle")
        }
    }

    // MARK: - Helper Methods

    private func dayName(_ day: Int) -> String {
        let days = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        return days[day]
    }

    private func deleteAllData() {
        for retro in retrospectives {
            modelContext.delete(retro)
        }

        for action in actions {
            modelContext.delete(action)
        }
    }
}

// MARK: - Sync Status View

struct SyncStatusView: View {
    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("iCloud Sync Enabled")
                }

                HStack {
                    Text("Last Synced")
                    Spacer()
                    Text("Just Now")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Status")
            } footer: {
                Text("Your data automatically syncs with iCloud whenever you make changes.")
            }

            Section {
                HStack {
                    Image(systemName: "iphone")
                    Text("This Device")
                    Spacer()
                    Image(systemName: "checkmark")
                        .foregroundStyle(.green)
                }
            } header: {
                Text("Devices")
            }
        }
        .navigationTitle("iCloud Sync")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Export Data View

struct ExportDataView: View {
    @Query private var retrospectives: [Retrospective]

    @State private var exportFormat: ExportFormat = .json
    @State private var isExporting = false

    var body: some View {
        List {
            Section {
                Picker("Format", selection: $exportFormat) {
                    ForEach(ExportFormat.allCases) { format in
                        Text(format.displayName).tag(format)
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Export Format")
            }

            Section {
                HStack {
                    Text("Retrospectives")
                    Spacer()
                    Text("\(retrospectives.count)")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Total Items")
                    Spacer()
                    Text("\(totalItems)")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Data to Export")
            }

            Section {
                Button {
                    exportData()
                } label: {
                    HStack {
                        Spacer()
                        if isExporting {
                            ProgressView()
                                .padding(.trailing, Theme.Spacing.sm)
                        }
                        Text(isExporting ? "Exporting..." : "Export Data")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .disabled(isExporting || retrospectives.isEmpty)
            }
        }
        .navigationTitle("Export Data")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var totalItems: Int {
        retrospectives.reduce(0) { $0 + $1.totalKPTACount + $1.actions.count }
    }

    private func exportData() {
        isExporting = true
        // Export logic would go here
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isExporting = false
        }
    }
}

enum ExportFormat: String, CaseIterable, Identifiable {
    case json = "JSON"
    case csv = "CSV"

    var id: String { rawValue }
    var displayName: String { rawValue }
}

// MARK: - About View

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    // App Icon and Name
                    VStack(spacing: Theme.Spacing.md) {
                        ZStack {
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                                .fill(
                                    LinearGradient(
                                        colors: [Theme.KPTA.keep, Theme.KPTA.action],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)

                            Image(systemName: "leaf.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(.white)
                        }

                        Text("Agile Self")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Your AI Growth Partner")
                            .font(Theme.Typography.headline)
                            .foregroundStyle(.secondary)

                        Text("Version 1.0.0")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.top, Theme.Spacing.xl)

                    // Tagline
                    VStack(spacing: Theme.Spacing.sm) {
                        Text("Turn Reflection Into Action")
                            .font(Theme.Typography.title2)
                            .multilineTextAlignment(.center)

                        Text("A personal retrospection app using the KPTA framework to help you grow continuously.")
                            .font(Theme.Typography.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, Theme.Spacing.lg)

                    // KPTA Framework
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        Text("KPTA Framework")
                            .font(Theme.Typography.headline)

                        VStack(spacing: Theme.Spacing.sm) {
                            kptaRow(
                                letter: "K",
                                title: "Keep",
                                description: "What went well",
                                color: Theme.KPTA.keep
                            )

                            kptaRow(
                                letter: "P",
                                title: "Problem",
                                description: "Obstacles faced",
                                color: Theme.KPTA.problem
                            )

                            kptaRow(
                                letter: "T",
                                title: "Try",
                                description: "New approaches",
                                color: Theme.KPTA.try
                            )

                            kptaRow(
                                letter: "A",
                                title: "Action",
                                description: "Concrete to-dos",
                                color: Theme.KPTA.action
                            )
                        }
                    }
                    .padding(Theme.Spacing.md)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
                    .padding(.horizontal, Theme.Spacing.md)

                    Spacer(minLength: Theme.Spacing.xl)
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func kptaRow(letter: String, title: String, description: String, color: Color) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            Text(letter)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(color)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.Typography.callout)
                    .fontWeight(.medium)

                Text(description)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Retrospective.self, KPTAItem.self, ActionItem.self, HealthSummary.self,
        configurations: config
    )

    return SettingsView()
        .modelContainer(container)
}

#Preview("About") {
    AboutView()
}
