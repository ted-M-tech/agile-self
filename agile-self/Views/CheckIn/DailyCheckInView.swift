//
//  DailyCheckInView.swift
//  agile-self
//
//  Full-screen check-in sheet with 4-axis scoring and optional note.
//

import SwiftUI
import SwiftData
import os

// MARK: - DailyCheckInView

struct DailyCheckInView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppContainer.self) private var appContainer

    @Query(sort: \DailyCheckIn.date, order: .reverse)
    private var recentCheckIns: [DailyCheckIn]

    // Scores (1–5; neutral default = 3)
    @State private var energyScore = 3
    @State private var focusScore = 3
    @State private var stressScore = 3
    @State private var growthScore = 3

    // Reflection (post-save AI chat) → confirmation
    @State private var showReflection = false
    @State private var showConfirmation = false
    /// The check-in row persisted by `saveCheckIn`, so the reflection step can attach its
    /// distilled note and the generated insight to it.
    @State private var savedCheckIn: DailyCheckIn?

    // Saving state
    @State private var isSaving = false
    @State private var generatedInsight: String?

    // Editor lifecycle
    /// Guards the one-time preload of today's saved check-in (so reopening the editor
    /// shows the SAVED scores, not 5/5/5/5, and never clobbers a prior same-day entry).
    @State private var didLoadExisting = false
    /// Snapshot of the scores/note as they were loaded, used to detect unsaved edits
    /// for the discard guard.
    @State private var loadedSnapshot = EditorSnapshot()
    /// Whether the discard-confirmation dialog is showing.
    @State private var showDiscardDialog = false

    /// Captures the editable fields so we can tell whether the user changed anything.
    private struct EditorSnapshot: Equatable {
        var energy = 3
        var focus = 3
        var stress = 3
        var growth = 3
    }

    private var currentSnapshot: EditorSnapshot {
        EditorSnapshot(
            energy: energyScore,
            focus: focusScore,
            stress: stressScore,
            growth: growthScore
        )
    }

    private var hasUnsavedChanges: Bool {
        currentSnapshot != loadedSnapshot
    }

    /// Composite score of the most recent previous check-in, for delta display.
    private var previousComposite: Double? {
        // Skip the first entry if it is from today (current session might have saved one)
        let previous = recentCheckIns.first { checkIn in
            !Calendar.current.isDateInToday(checkIn.date)
        }
        return previous?.compositeScore
    }

    var body: some View {
        ZStack {
            Theme.Colors.backgroundPrimary
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                scrollContent
                saveButton
            }

            // Post-save reflection chat (on-device AI). Captures a "moment worth keeping" and,
            // when finished/skipped, hands off to the confirmation overlay.
            if showReflection, let savedCheckIn {
                ReflectionChatView(
                    checkIn: savedCheckIn,
                    reflectionService: appContainer.reflectionService,
                    onFinish: { note in finishReflection(note: note) }
                )
                .transition(.opacity)
            }

            if showConfirmation {
                CheckInConfirmationView(
                    energyScore: energyScore,
                    focusScore: focusScore,
                    stressScore: stressScore,
                    growthScore: growthScore,
                    previousComposite: previousComposite,
                    // Bind to the @State so the overlay re-renders the moment the
                    // async insight task completes (it starts nil and updates in place).
                    insight: $generatedInsight,
                    onDismiss: {
                        showConfirmation = false
                        dismiss()
                    }
                )
                .transition(.opacity)
            }
        }
        .task {
            loadExistingCheckIn()
        }
        .confirmationDialog(
            "Discard this check-in?",
            isPresented: $showDiscardDialog,
            titleVisibility: .visible
        ) {
            Button("Discard", role: .destructive) { dismiss() }
            Button("Keep editing", role: .cancel) {}
        } message: {
            Text("Your changes haven't been saved yet.")
        }
    }

    // MARK: - Load Existing

    /// On first appearance, preloads today's saved check-in (if any) so the editor shows
    /// the SAVED values instead of resetting to 5/5/5/5 — and so a Save updates the row
    /// rather than silently overwriting it with defaults. Fetched by the same
    /// start-of-day predicate `saveCheckIn` upserts on. Runs once per presentation.
    private func loadExistingCheckIn() {
        guard !didLoadExisting else { return }
        didLoadExisting = true

        let today = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<DailyCheckIn>(predicate: #Predicate { $0.date == today })
        guard let existing = try? modelContext.fetch(descriptor).first else {
            // No prior entry today — record the default state as the baseline so an
            // untouched editor closes without a discard prompt.
            loadedSnapshot = currentSnapshot
            return
        }

        energyScore = existing.energyScore
        focusScore = existing.focusScore
        stressScore = existing.stressScore
        growthScore = existing.growthScore
        loadedSnapshot = currentSnapshot
    }

    /// Handles the close (X) button: prompts before discarding unsaved edits, but closes
    /// immediately when nothing changed (the common case).
    private func handleClose() {
        if hasUnsavedChanges {
            showDiscardDialog = true
        } else {
            dismiss()
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            // Title
            VStack(alignment: .leading, spacing: 2) {
                Text("Check In")
                    .font(Theme.Typography.title1)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text("How are you doing today?")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            Spacer()

            // Dismiss button
            Button {
                handleClose()
            } label: {
                Image(systemName: "xmark")
                    .font(.body.weight(.medium))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(Theme.Colors.backgroundTertiary)
                    .clipShape(Circle())
            }
            .accessibilityLabel("Close")
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.top, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.sm)
    }

    // MARK: - Scroll Content

    private var scrollContent: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.md) {
                // Dimension pickers
                ForEach(Array(DimensionType.allCases.enumerated()), id: \.element) { index, dimension in
                    ScoreDimensionPicker(
                        dimension: dimension,
                        score: binding(for: dimension)
                    )
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .animation(Theme.Animation.springStagger(index: index), value: true)
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.sm)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            saveCheckIn()
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                if isSaving {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Save Check-in")
                }
            }
            .primaryButtonStyle()
        }
        .disabled(isSaving)
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md)
        .accessibilityHint("Saves your check-in scores and note")
    }

    // MARK: - Timer

    // MARK: - Score Bindings

    private func binding(for dimension: DimensionType) -> Binding<Int> {
        switch dimension {
        case .energy: return $energyScore
        case .focus: return $focusScore
        case .stress: return $stressScore
        case .growth: return $growthScore
        }
    }

    // MARK: - Save

    private func saveCheckIn() {
        isSaving = true

        let today = Calendar.current.startOfDay(for: Date())

        // Upsert SCORES only — the reflection step attaches any note afterward. Mirrors
        // WatchConnectivityService.persistCheckIn so the phone and watch never create
        // duplicate rows for the same day (fixes the duplicate check-in bug).
        let descriptor = FetchDescriptor<DailyCheckIn>(predicate: #Predicate { $0.date == today })
        let existing = try? modelContext.fetch(descriptor).first
        let checkIn: DailyCheckIn
        if let existing {
            existing.energyScore = energyScore
            existing.focusScore = focusScore
            existing.stressScore = stressScore
            existing.growthScore = growthScore
            checkIn = existing
        } else {
            let newCheckIn = DailyCheckIn(
                date: today,
                energyScore: energyScore,
                focusScore: focusScore,
                stressScore: stressScore,
                growthScore: growthScore
            )
            modelContext.insert(newCheckIn)
            checkIn = newCheckIn
        }
        AppLog.checkIn.notice("\(existing == nil ? "create" : "upsert", privacy: .public) composite=\(checkIn.compositeScore, privacy: .public) e=\(self.energyScore, privacy: .public) f=\(self.focusScore, privacy: .public) s=\(self.stressScore, privacy: .public) g=\(self.growthScore, privacy: .public)")

        // Streak + widget reflect the saved scores immediately.
        appContainer.streakService.recordCheckIn(context: modelContext)
        WidgetSnapshotWriter.update(context: modelContext)

        // Persisted — no unsaved edits remain (closing must not trigger the discard prompt).
        loadedSnapshot = currentSnapshot
        savedCheckIn = checkIn

        // Hand off to the reflection chat. It attaches a distilled note (if any) and then
        // `finishReflection` runs sentiment + the daily insight and shows the confirmation.
        withAnimation(Theme.Animation.smooth) {
            isSaving = false
            showReflection = true
        }
    }

    /// Called when the reflection chat finishes or is skipped. Attaches the distilled note (if
    /// any), runs on-device sentiment, generates the daily insight, then shows the confirmation.
    private func finishReflection(note: String?) {
        if let checkIn = savedCheckIn,
           let note,
           !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
            checkIn.note = trimmed
            checkIn.sentimentScore = appContainer.analyzeSentiment(trimmed)
        }

        // Generate the AI insight asynchronously. The confirmation overlay binds to
        // `generatedInsight`, showing a graceful placeholder until this completes.
        generatedInsight = nil
        if let checkIn = savedCheckIn {
            Task {
                do {
                    let insight = try await appContainer.aiService.generateDailyInsight(checkIn: checkIn)
                    checkIn.dailyInsight = insight
                    generatedInsight = insight
                } catch {
                    // AI insight generation failed -- continue without it
                }
            }
        }

        withAnimation(Theme.Animation.smooth) {
            showReflection = false
            showConfirmation = true
        }
    }
}

// MARK: - Preview

#Preview("Check-in Entry") {
    DailyCheckInView()
        .modelContainer(MockData.previewContainer)
        .environment(AppContainer(modelContainer: MockData.previewContainer))
        .preferredColorScheme(.dark)
}

#Preview("Check-in Entry - Sheet") {
    ZStack {
        Theme.Colors.backgroundPrimary.ignoresSafeArea()
        Text("Home Screen")
            .foregroundStyle(Theme.Colors.textSecondary)
    }
    .sheet(isPresented: .constant(true)) {
        DailyCheckInView()
            .modelContainer(MockData.previewContainer)
            .environment(AppContainer(modelContainer: MockData.previewContainer))
            .preferredColorScheme(.dark)
    }
}
