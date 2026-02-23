//
//  DailyCheckInView.swift
//  agile-self
//
//  Full-screen check-in sheet with 4-axis scoring and optional note.
//

import SwiftUI
import SwiftData

// MARK: - DailyCheckInView

struct DailyCheckInView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \DailyCheckIn.date, order: .reverse)
    private var recentCheckIns: [DailyCheckIn]

    // Scores
    @State private var energyScore = 5
    @State private var focusScore = 5
    @State private var stressScore = 5
    @State private var growthScore = 5

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

    private let noteMaxLength = 280

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
                    onDismiss: {
                        showConfirmation = false
                        dismiss()
                    }
                )
                .transition(.opacity)
            }
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timerTask?.cancel()
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
                dismiss()
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

        let checkIn = DailyCheckIn(
            energyScore: energyScore,
            focusScore: focusScore,
            stressScore: stressScore,
            growthScore: growthScore,
            note: showNote && !noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? noteText.trimmingCharacters(in: .whitespacesAndNewlines)
                : nil
        )

        modelContext.insert(checkIn)

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
            .preferredColorScheme(.dark)
    }
}
