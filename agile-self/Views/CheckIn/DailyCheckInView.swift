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

    // Note
    @State private var noteText = ""
    @State private var showNote = false

    // Timer
    @State private var elapsedSeconds = 0
    @State private var timerTask: Task<Void, Never>?

    // Confirmation
    @State private var showConfirmation = false

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

    private let noteMaxLength = 280

    /// Captures the editable fields so we can tell whether the user changed anything.
    private struct EditorSnapshot: Equatable {
        var energy = 3
        var focus = 3
        var stress = 3
        var growth = 3
        var note = ""
    }

    private var currentSnapshot: EditorSnapshot {
        EditorSnapshot(
            energy: energyScore,
            focus: focusScore,
            stress: stressScore,
            growth: growthScore,
            note: showNote ? noteText : ""
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

            if showConfirmation {
                CheckInConfirmationView(
                    energyScore: energyScore,
                    focusScore: focusScore,
                    stressScore: stressScore,
                    growthScore: growthScore,
                    elapsedSeconds: elapsedSeconds,
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
            startTimer()
        }
        .onDisappear {
            timerTask?.cancel()
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
        if let note = existing.note, !note.isEmpty {
            noteText = note
            showNote = true
        }
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

            // Timer badge
            timerBadge

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

    private var timerBadge: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: "stopwatch")
                .font(.caption2)
            Text("\(elapsedSeconds)s")
                .font(Theme.Typography.caption)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .foregroundStyle(Theme.Colors.textTertiary)
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
        .background(Theme.Colors.backgroundTertiary)
        .clipShape(Capsule())
        .padding(.trailing, Theme.Spacing.sm)
        .accessibilityLabel("Elapsed time \(elapsedSeconds) seconds")
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

                // Note section
                noteSection
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.sm)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Note Section

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Button {
                withAnimation(Theme.Animation.smooth) {
                    showNote.toggle()
                }
            } label: {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: showNote ? "minus.circle" : "plus.circle")
                        .font(.body)
                        .foregroundStyle(Theme.Colors.accentStart)

                    Text(showNote ? "Remove note" : "Add a note")
                        .font(Theme.Typography.callout)
                        .foregroundStyle(Theme.Colors.accentStart)

                    Spacer()
                }
            }
            .buttonStyle(.plain)
            .accessibilityHint(showNote ? "Collapse the note field" : "Expand to add a note")

            if showNote {
                VStack(alignment: .trailing, spacing: Theme.Spacing.xs) {
                    TextEditor(text: $noteText)
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 80, maxHeight: 140)
                        .padding(Theme.Spacing.sm)
                        .background(Theme.Colors.backgroundTertiary)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
                        .onChange(of: noteText) { _, newValue in
                            if newValue.count > noteMaxLength {
                                noteText = String(newValue.prefix(noteMaxLength))
                            }
                        }

                    Text("\(noteText.count)/\(noteMaxLength)")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(
                            noteText.count > noteMaxLength - 20
                                ? Theme.Colors.warning
                                : Theme.Colors.textTertiary
                        )
                        .monospacedDigit()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
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

    private func startTimer() {
        timerTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { break }
                withAnimation(.linear(duration: 0.2)) {
                    elapsedSeconds += 1
                }
            }
        }
    }

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
        timerTask?.cancel()

        let today = Calendar.current.startOfDay(for: Date())
        let note = showNote && !noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? noteText.trimmingCharacters(in: .whitespacesAndNewlines)
            : nil

        // Upsert: update today's check-in if it exists, otherwise insert. Mirrors
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
            existing.note = note
            checkIn = existing
        } else {
            let newCheckIn = DailyCheckIn(
                date: today,
                energyScore: energyScore,
                focusScore: focusScore,
                stressScore: stressScore,
                growthScore: growthScore,
                note: note
            )
            modelContext.insert(newCheckIn)
            checkIn = newCheckIn
        }
        AppLog.checkIn.notice("\(existing == nil ? "create" : "upsert", privacy: .public) composite=\(checkIn.compositeScore, privacy: .public) e=\(self.energyScore, privacy: .public) f=\(self.focusScore, privacy: .public) s=\(self.stressScore, privacy: .public) g=\(self.growthScore, privacy: .public) note=\(note != nil, privacy: .public)")

        // Persist on-device sentiment of the note (-1.0...1.0) so Insights can
        // correlate it later. Routed through the DI container's shared on-device
        // service (a fast, nonisolated NaturalLanguage call) rather than a throwaway
        // instance. Set to nil when there's no note so an edited check-in clears a
        // stale score.
        if let note {
            checkIn.sentimentScore = appContainer.analyzeSentiment(note)
        } else {
            checkIn.sentimentScore = nil
        }

        // Record check-in for streak tracking
        appContainer.streakService.recordCheckIn(context: modelContext)

        // Publish the latest state to the home-screen widget via the App Group.
        WidgetSnapshotWriter.update(context: modelContext)

        // Now that the row is persisted, the editor has no unsaved edits — closing the
        // confirmation must not trigger the discard prompt.
        loadedSnapshot = currentSnapshot

        // Generate the AI insight asynchronously via the injected service. The
        // confirmation overlay binds to `generatedInsight`, so it shows a graceful
        // placeholder first and re-renders the moment this completes.
        generatedInsight = nil
        Task {
            do {
                let insight = try await appContainer.aiService.generateDailyInsight(checkIn: checkIn)
                checkIn.dailyInsight = insight
                generatedInsight = insight
            } catch {
                // AI insight generation failed -- continue without it
            }
        }

        withAnimation(Theme.Animation.smooth) {
            isSaving = false
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
