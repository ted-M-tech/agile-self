//
//  DailyCheckInView.swift
//  agile-self
//
//  Full-screen check-in editor with 4-axis scoring. Works for three cases, keyed by the
//  `targetDate` it is opened with:
//    • today, no entry yet  → "today-first" flow: save scores → AI reflection chat → confirmation
//    • any day with an entry → "edit"        flow: adjust scores + inline note, save, dismiss
//    • a past day, no entry  → "back-fill"    flow: enter scores + inline note, save, dismiss
//  The reflection chat is kept ONLY for the live first log of today; edits and back-fills are
//  deliberately low-friction (no chat, no celebratory overlay).
//

import SwiftUI
import SwiftData
import os

// MARK: - CheckInMode

/// Which of the three editor behaviours is active. Derived from the target day + whether a row
/// already exists for it; drives the title, the inline note field, the delete affordance, and
/// whether the post-save reflection/confirmation chain runs.
private enum CheckInMode {
    /// Today, and no entry exists yet — the original full flow (reflection chat → confirmation).
    case todayFirst
    /// An entry already exists for the target day (today or past) — quick scores + note edit.
    case edit
    /// A past day with no entry yet — back-fill scores + an optional note.
    case backfill
}

// MARK: - DailyCheckInView

struct DailyCheckInView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppContainer.self) private var appContainer

    /// The calendar day this editor reads from and writes to. Defaults to today; the History
    /// calendar passes a past day to edit or back-fill it.
    let targetDate: Date

    init(targetDate: Date = Date()) {
        self.targetDate = targetDate
        let day = Calendar.current.startOfDay(for: targetDate)
        // Seed the mode before the first render so a past day never flashes the today-first UI.
        // `loadExistingCheckIn` upgrades backfill/todayFirst → edit if a row turns up.
        let isToday = Calendar.current.isDateInToday(day)
        _mode = State(initialValue: isToday ? .todayFirst : .backfill)
    }

    @Query(sort: \DailyCheckIn.date, order: .reverse)
    private var recentCheckIns: [DailyCheckIn]

    // Scores (1–5; neutral default = 3)
    @State private var energyScore = 3
    @State private var focusScore = 3
    @State private var stressScore = 3
    @State private var growthScore = 3

    /// Inline note (edit / back-fill modes only — today-first captures its note via the chat).
    @State private var noteText = ""

    /// Which behaviour is active. Seeded in `init`, finalized in `loadExistingCheckIn`.
    @State private var mode: CheckInMode

    // Reflection (post-save AI chat) → confirmation — today-first flow only.
    @State private var showReflection = false
    @State private var showConfirmation = false
    /// The check-in row persisted by `saveCheckIn`, so the reflection step can attach its
    /// distilled note and the generated insight to it.
    @State private var savedCheckIn: DailyCheckIn?

    // Saving state
    @State private var isSaving = false
    @State private var generatedInsight: String?

    // Editor lifecycle
    /// Guards the one-time preload of the target day's saved check-in (so reopening the editor
    /// shows the SAVED scores/note, not 3/3/3/3, and never clobbers a prior entry).
    @State private var didLoadExisting = false
    /// Snapshot of the scores/note as they were loaded, used to detect unsaved edits
    /// for the discard guard.
    @State private var loadedSnapshot = EditorSnapshot()
    /// Whether the discard-confirmation dialog is showing.
    @State private var showDiscardDialog = false
    /// Whether the delete-confirmation dialog is showing (edit mode only).
    @State private var showDeleteDialog = false

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
            note: noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    private var hasUnsavedChanges: Bool {
        currentSnapshot != loadedSnapshot
    }

    // MARK: - Day Context

    /// The target day stripped to midnight — the key the upsert/preload/delete all use.
    private var dayStart: Date { Calendar.current.startOfDay(for: targetDate) }

    private var isToday: Bool { Calendar.current.isDateInToday(dayStart) }

    /// Whether the reflection chat + confirmation overlay should run after saving.
    private var runsFullFlow: Bool { mode == .todayFirst }

    private var navTitle: String {
        switch mode {
        case .todayFirst: return "Check In"
        case .edit: return "Edit Check-in"
        case .backfill: return "Add Check-in"
        }
    }

    /// Subtitle: the prompt for today, the spelled-out date for any other day.
    private var subtitle: String {
        if isToday {
            return "How are you doing today?"
        }
        return dayStart.formatted(.dateTime.weekday(.wide).month(.wide).day())
    }

    private var saveLabel: String {
        switch mode {
        case .todayFirst: return "Save Check-in"
        case .edit: return "Save Changes"
        case .backfill: return "Add Check-in"
        }
    }

    /// Short day reference for the delete dialog message.
    private var dayReference: String {
        isToday ? "today's" : "\(dayStart.formatted(.dateTime.month(.abbreviated).day()))'s"
    }

    /// Composite score of the most recent previous check-in, for the confirmation delta.
    /// Only consulted in the today-first flow, so excluding "today" stays correct.
    private var previousComposite: Double? {
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
            // when finished/skipped, hands off to the confirmation overlay. Today-first only.
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
        .confirmationDialog(
            "Delete this check-in?",
            isPresented: $showDeleteDialog,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) { deleteCheckIn() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently removes \(dayReference) scores and note.")
        }
    }

    // MARK: - Load Existing

    /// On first appearance, preloads the target day's saved check-in (if any) so the editor shows
    /// the SAVED values instead of resetting to 3/3/3/3 — and so a Save updates the row rather
    /// than overwriting it with defaults. Also finalizes `mode` (→ `.edit` when a row exists).
    /// Fetched by the same start-of-day predicate `saveCheckIn` upserts on. Runs once.
    private func loadExistingCheckIn() {
        guard !didLoadExisting else { return }
        didLoadExisting = true

        let day = dayStart
        let descriptor = FetchDescriptor<DailyCheckIn>(predicate: #Predicate { $0.date == day })
        guard let existing = try? modelContext.fetch(descriptor).first else {
            // No prior entry — record the default state as the baseline so an untouched editor
            // closes without a discard prompt. Mode stays todayFirst (today) / backfill (past).
            loadedSnapshot = currentSnapshot
            return
        }

        energyScore = existing.energyScore
        focusScore = existing.focusScore
        stressScore = existing.stressScore
        growthScore = existing.growthScore
        noteText = existing.note ?? ""
        mode = .edit
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
                Text(navTitle)
                    .font(Theme.Typography.title1)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text(subtitle)
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
                    // Keep the 32pt circle visually, but expand the tap target to the 44pt minimum.
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
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

                // Inline note + delete are shown for edit / back-fill (the chat is skipped there).
                if !runsFullFlow {
                    noteCard
                    if mode == .edit {
                        deleteButton
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.sm)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Inline Note (edit / back-fill)

    private var noteCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("NOTE")
                .font(Theme.Typography.caption)
                .fontWeight(.semibold)
                .tracking(1.2)
                .foregroundStyle(Theme.Colors.textTertiary)

            TextField("Add a note (optional)", text: $noteText, axis: .vertical)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textPrimary)
                .tint(Theme.Colors.accentStart)
                .lineLimit(3...6)
                .onChange(of: noteText) { _, newValue in
                    // Match the model's 280-character cap.
                    if newValue.count > 280 {
                        noteText = String(newValue.prefix(280))
                    }
                }
                .accessibilityLabel("Note")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            showDeleteDialog = true
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "trash")
                Text("Delete Check-in")
            }
            .font(Theme.Typography.callout)
            .foregroundStyle(Theme.Colors.error)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.sm)
        }
        .accessibilityHint("Permanently removes this day's check-in")
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
                    Text(saveLabel)
                }
            }
            .primaryButtonStyle()
        }
        .disabled(isSaving)
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md)
        .accessibilityHint("Saves your check-in scores and note")
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

        let day = dayStart
        let scoresChanged = energyScore != loadedSnapshot.energy
            || focusScore != loadedSnapshot.focus
            || stressScore != loadedSnapshot.stress
            || growthScore != loadedSnapshot.growth
        // The note feeds the insight too, so a note edit (incl. clearing it) is a content change.
        let noteChanged = currentSnapshot.note != loadedSnapshot.note

        // Upsert SCORES on the target day's start-of-day key. Mirrors
        // WatchConnectivityService.persistCheckIn so paths never create duplicate same-day rows.
        let descriptor = FetchDescriptor<DailyCheckIn>(predicate: #Predicate { $0.date == day })
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
                date: day,
                energyScore: energyScore,
                focusScore: focusScore,
                stressScore: stressScore,
                growthScore: growthScore
            )
            modelContext.insert(newCheckIn)
            checkIn = newCheckIn
        }
        AppLog.checkIn.notice("\(existing == nil ? "create" : "upsert", privacy: .public) day=\(day.timeIntervalSince1970, privacy: .public) composite=\(checkIn.compositeScore, privacy: .public) e=\(self.energyScore, privacy: .public) f=\(self.focusScore, privacy: .public) s=\(self.stressScore, privacy: .public) g=\(self.growthScore, privacy: .public)")

        // Edit / back-fill capture the note inline (today-first attaches it via the chat instead).
        if !runsFullFlow {
            let trimmed = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
            checkIn.note = trimmed.isEmpty ? nil : trimmed
            checkIn.sentimentScore = trimmed.isEmpty ? nil : appContainer.analyzeSentiment(trimmed)
        }

        // Persist before recompute, so the streak scan and report invalidation see this write.
        try? modelContext.save()

        // Streak: authoritative recompute from full history (correct for back-fill / past edits).
        appContainer.streakService.recompute(context: modelContext)
        // The widget mirrors TODAY's score only — a past-day write must not overwrite it.
        if isToday {
            WidgetSnapshotWriter.update(context: modelContext)
        }
        // A changed day can stale-out its month's generated report; let it regenerate.
        invalidateMonthlyReport(for: day)
        try? modelContext.save()

        // Persisted — no unsaved edits remain (closing must not trigger the discard prompt).
        loadedSnapshot = currentSnapshot
        savedCheckIn = checkIn

        if runsFullFlow {
            // Original today-first flow: reflection chat → confirmation (which generates insight).
            withAnimation(Theme.Animation.smooth) {
                isSaving = false
                showReflection = true
            }
        } else {
            // Edit / back-fill: (re)generate the insight whenever the content changed — scores or
            // note — or this is a brand-new row (so a back-fill never persists without an insight,
            // and a cleared/edited note never leaves a stale insight phrased around old text).
            if scoresChanged || noteChanged || existing == nil {
                regenerateInsight(for: checkIn)
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            isSaving = false
            dismiss()
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

    /// Fire-and-forget insight regeneration for an edit / back-fill. Mutates the persisted row,
    /// so it's safe to outlive this view (no view @State is touched).
    private func regenerateInsight(for checkIn: DailyCheckIn) {
        let aiService = appContainer.aiService
        let context = modelContext
        Task {
            if let insight = try? await aiService.generateDailyInsight(checkIn: checkIn) {
                checkIn.dailyInsight = insight
                try? context.save()
            }
        }
    }

    // MARK: - Delete

    private func deleteCheckIn() {
        let day = dayStart
        let descriptor = FetchDescriptor<DailyCheckIn>(predicate: #Predicate { $0.date == day })
        if let existing = try? modelContext.fetch(descriptor).first {
            modelContext.delete(existing)
            try? modelContext.save()
            AppLog.checkIn.notice("delete day=\(day.timeIntervalSince1970, privacy: .public)")

            // Streak/report must reflect the removed day; widget only when it was today.
            appContainer.streakService.recompute(context: modelContext)
            if isToday {
                WidgetSnapshotWriter.update(context: modelContext)
            }
            invalidateMonthlyReport(for: day)
            try? modelContext.save()
        }
        dismiss()
    }

    // MARK: - Monthly Report Invalidation

    /// Marks the generated MonthlyReport for `day`'s month as not-generated, so it regenerates
    /// the next time the report is opened. A no-op when no generated report exists for the month.
    private func invalidateMonthlyReport(for day: Date) {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month], from: day)
        guard let month = comps.month, let year = comps.year else { return }
        let descriptor = FetchDescriptor<MonthlyReport>(
            predicate: #Predicate { $0.month == month && $0.year == year }
        )
        if let report = try? modelContext.fetch(descriptor).first, report.isGenerated {
            report.isGenerated = false
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

#Preview("Back-fill a Past Day") {
    DailyCheckInView(targetDate: Calendar.current.date(byAdding: .day, value: -3, to: Date())!)
        .modelContainer(MockData.previewContainer)
        .environment(AppContainer(modelContainer: MockData.previewContainer))
        .preferredColorScheme(.dark)
}
