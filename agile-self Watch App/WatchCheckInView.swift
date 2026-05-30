//
//  WatchCheckInView.swift
//  agile-self Watch App
//
//  Tap-to-advance check-in flow: one full-screen card per dimension, a level (1..5) picked
//  by TAPPING a face (haptic + auto-advance), then a summary card with composite + Save.
//
//  NO Digital Crown, NO .focusable() / .digitalCrownRotation — tappable buttons only. The
//  crown-based flow did not respond on device; this replaces it.
//

import SwiftUI
import WatchKit

// MARK: - WatchCheckInView

struct WatchCheckInView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var connectivity: WatchConnectivityManager

    /// The current page: 0..3 are the four dimensions, 4 is the summary card.
    @State private var page = 0
    /// nil until the user picks a level for that dimension. Pre-filling would let an
    /// untouched dimension silently count as a "3" — keep intent explicit.
    @State private var scores: [Int?] = [nil, nil, nil, nil]
    @State private var showSuccess = false
    /// Bumped on success-appear to fire the checkmark bounce exactly once (and only when
    /// Reduce Motion is off). A value-change symbol effect needs a changing value to play.
    @State private var bounceTrigger = 0
    /// Cancellable timers so a fast user (or a dismiss) never fires a stale advance/dismiss.
    @State private var advanceTask: Task<Void, Never>?
    @State private var dismissTask: Task<Void, Never>?

    private let dimensions = WatchDimensionType.allCases
    private var summaryPage: Int { dimensions.count }       // 4
    private var totalPages: Int { dimensions.count + 1 }    // 5 (4 dims + summary)

    var body: some View {
        ZStack {
            WatchTheme.Colors.backgroundPrimary.ignoresSafeArea()

            if showSuccess {
                successView
                    .transition(.opacity)
            } else {
                TabView(selection: $page) {
                    ForEach(Array(dimensions.enumerated()), id: \.element.id) { index, dimension in
                        DimensionCard(
                            dimension: dimension,
                            selected: scores[index],
                            onPick: { level in pick(level, at: index) }
                        )
                        .tag(index)
                    }

                    SummaryCard(
                        dimensions: dimensions,
                        scores: scores,
                        composite: compositeScore,
                        canSave: allScored,
                        onSave: save
                    )
                    .tag(summaryPage)
                }
                .tabViewStyle(.verticalPage)
                .overlay(alignment: .top) { progressDots }
                .transition(.opacity)
            }
        }
        .onDisappear {
            advanceTask?.cancel()
            dismissTask?.cancel()
        }
    }

    // MARK: - Progress dots

    /// A persistent 5-step indicator pinned to the top across all pages (4 dimensions +
    /// summary), tinted by the current dimension's color (accent on the summary).
    private var progressDots: some View {
        HStack(spacing: 6) {
            ForEach(0 ..< totalPages, id: \.self) { dot in
                Circle()
                    .fill(dot <= page ? filledDotColor : WatchTheme.Colors.textTertiary)
                    .frame(width: 6, height: 6)
            }
        }
        .padding(.top, 4)
        .accessibilityHidden(true)
    }

    private var filledDotColor: Color {
        page < dimensions.count
            ? WatchTheme.Dimension.color(for: dimensions[page])
            : WatchTheme.Colors.accentStart
    }

    // MARK: - Success

    private var successView: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 42))
                .foregroundStyle(WatchTheme.Colors.success)
                .symbolEffect(.bounce, value: bounceTrigger)

            Text(watchCompositeWord(for: compositeScore))
                .font(.system(.headline, design: .rounded).weight(.semibold))
                .foregroundStyle(WatchTheme.Colors.textPrimary)

            Text(String(format: "%.1f", compositeScore))
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(WatchTheme.Colors.accentGradient)
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(format: "%@. Composite score %.1f out of 5. Saved.", watchCompositeWord(for: compositeScore), compositeScore))
        .onAppear {
            WKInterfaceDevice.current().play(.success)
            if !reduceMotion { bounceTrigger += 1 }   // play the checkmark bounce once
            // Brief linger so the confirmation registers, then dismiss back to Home.
            dismissTask?.cancel()
            dismissTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(1.3))
                guard !Task.isCancelled else { return }
                dismiss()
            }
        }
    }

    // MARK: - Actions

    private func pick(_ level: Int, at index: Int) {
        // Only auto-advance the FIRST time a dimension is scored. If the user swiped back to
        // correct an already-scored card, update the value + haptic but stay put.
        let isFirstSelection = scores[index] == nil
        scores[index] = level
        WKInterfaceDevice.current().play(.click)

        guard isFirstSelection else { return }

        let next = index + 1
        advanceTask?.cancel()
        if reduceMotion {
            page = next
        } else {
            // Tiny delay lets the selection "pop" register before the page slides.
            advanceTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(200))
                guard !Task.isCancelled else { return }
                withAnimation(.easeInOut(duration: 0.28)) { page = next }
            }
        }
    }

    private func save() {
        // scores are all non-nil here (Save is gated on `allScored`); default to 3 defensively.
        let e = scores[0] ?? 3
        let f = scores[1] ?? 3
        let c = scores[2] ?? 3
        let g = scores[3] ?? 3
        // Optimistically reflect the check-in locally so Home + the success screen agree even
        // if the phone never sends a reply (reachable-but-no-reply). handleReply later reconciles
        // with the phone's authoritative composite + streak. Idempotent; only touches local state.
        connectivity.applyLocalState(energy: e, focus: f, calm: c, growth: g)
        connectivity.sendCheckIn(energy: e, focus: f, calm: c, growth: g)
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) { showSuccess = true }
    }

    // MARK: - Helpers

    private var allScored: Bool { scores.allSatisfy { $0 != nil } }

    private var compositeScore: Double {
        let total = scores.reduce(0) { $0 + ($1 ?? 3) }
        return Double(total) / Double(dimensions.count)
    }
}

// MARK: - DimensionCard

/// One full-screen card: dimension header, a big tinted hero (face + large numeral) echoing
/// the current pick, and a row of five tappable faces. Tapping a face selects it (handled by
/// the parent: haptic + auto-advance). Scrollable + vertically centered so it stays balanced at
/// the default text size yet never clips at large Dynamic Type / accessibility sizes.
private struct DimensionCard: View {
    let dimension: WatchDimensionType
    let selected: Int?
    let onPick: (Int) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var color: Color { WatchTheme.Dimension.color(for: dimension) }

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 10) {
                    // Header: icon + bold typographic label.
                    HStack(spacing: 6) {
                        Image(systemName: dimension.icon)
                            .font(.body)
                            .foregroundStyle(color)
                        Text(dimension.label.uppercased())
                            .font(.system(.headline, design: .rounded).weight(.bold))
                            .tracking(1.5)
                            .foregroundStyle(WatchTheme.Colors.textPrimary)
                    }

                    // Hero: the selected level reads as a LARGE numeral beside its face. Before
                    // a pick, a neutral face + "–" hints at the scale.
                    HStack(spacing: 8) {
                        WatchFaceGlyph(level: selected ?? 3, lineWidth: 3)
                            .foregroundStyle(selected == nil ? WatchTheme.Colors.textSecondary : color)
                            .frame(width: 46, height: 46)

                        Text(selected.map(String.init) ?? "–")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundStyle(selected == nil ? WatchTheme.Colors.textTertiary : color)
                            .contentTransition(.numericText())
                            .frame(minWidth: 32)
                    }
                    .scaleEffect(selected == nil ? 1.0 : 1.06)
                    .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.6), value: selected)
                    .accessibilityHidden(true)

                    // The five tappable faces — each claims an equal share of the row so they
                    // never clip on the smallest (40mm) watch and breathe on the largest.
                    HStack(spacing: 4) {
                        ForEach(1 ... 5, id: \.self) { level in
                            FaceButton(
                                level: level,
                                isSelected: selected == level,
                                color: color,
                                dimensionLabel: dimension.label,
                                action: { onPick(level) }
                            )
                        }
                    }
                    .frame(maxWidth: .infinity)

                    // Scale legend.
                    HStack {
                        Text("Low")
                        Spacer()
                        Text("High")
                    }
                    .font(.system(size: 11))
                    .foregroundStyle(WatchTheme.Colors.textTertiary)
                    .padding(.horizontal, 4)
                }
                .padding(.horizontal, 6)
                .padding(.top, 18)   // headroom so content clears the overlaid progress dots
                .padding(.bottom, 6)
                .frame(maxWidth: .infinity, minHeight: proxy.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }
}

// MARK: - FaceButton

/// A single tappable 1..5 face. Pops (scale + full opacity) when selected; dims when not.
/// Expands to an equal share of the row (`maxWidth: .infinity`) so five fit any watch size.
private struct FaceButton: View {
    let level: Int
    let isSelected: Bool
    let color: Color
    let dimensionLabel: String
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            WatchFaceGlyph(level: level)
                .foregroundStyle(isSelected ? color : WatchTheme.Colors.textSecondary)
                .frame(width: 22, height: 22)
                .padding(3)
                .background {
                    Circle()
                        .fill(color.opacity(isSelected ? 0.18 : 0))
                        .overlay(
                            Circle().stroke(color, lineWidth: isSelected ? 1.5 : 0)
                        )
                }
                .scaleEffect(isSelected ? 1.12 : 1.0)
                .opacity(isSelected ? 1.0 : 0.75)
                .frame(maxWidth: .infinity)
                .animation(reduceMotion ? nil : .spring(response: 0.28, dampingFraction: 0.6), value: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(dimensionLabel) level \(level) of 5")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - SummaryCard

/// Final card: a word headline + composite score, the four dimension faces in a tinted row,
/// and Save. Until every dimension is scored, the composite and any unscored face render as a
/// neutral "–" — never a fabricated value the user didn't enter.
private struct SummaryCard: View {
    let dimensions: [WatchDimensionType]
    let scores: [Int?]
    let composite: Double
    let canSave: Bool
    let onSave: () -> Void

    var body: some View {
        // Centered + sized to fit a single screen so the summary never scrolls at the normal
        // text size. The ScrollView is a safety net for very large Dynamic Type only — bounce
        // is disabled while the content fits, so it reads as a static screen.
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 5) {
                    // Word-first headline mapped from the 1–5 composite (matches iOS).
                    Text(canSave ? watchCompositeWord(for: composite) : "Your day")
                        .font(.system(.caption2, design: .rounded).weight(.bold))
                        .tracking(1.6)
                        .textCase(.uppercase)
                        .foregroundStyle(WatchTheme.Colors.textTertiary)

                    // Composite numeral — only once every dimension is scored; otherwise a
                    // neutral placeholder so we never show a number the user didn't produce.
                    Text(canSave ? String(format: "%.1f", composite) : "–")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(canSave
                            ? AnyShapeStyle(WatchTheme.Colors.accentGradient)
                            : AnyShapeStyle(WatchTheme.Colors.textTertiary))
                        .contentTransition(.numericText())

                    // Four faces in a row, tinted by dimension color. Unscored = neutral "–".
                    HStack(spacing: 4) {
                        ForEach(Array(dimensions.enumerated()), id: \.element.id) { index, dim in
                            let value = scores[index]
                            VStack(spacing: 2) {
                                WatchFaceGlyph(level: value ?? 3)
                                    .foregroundStyle(value == nil ? WatchTheme.Colors.textTertiary : WatchTheme.Dimension.color(for: dim))
                                    .frame(width: 22, height: 22)
                                    .opacity(value == nil ? 0.5 : 1)
                                Text(value.map(String.init) ?? "–")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundStyle(value == nil ? WatchTheme.Colors.textTertiary : WatchTheme.Colors.textPrimary)
                            }
                            .frame(maxWidth: .infinity)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel(value == nil ? "\(dim.label) not scored" : "\(dim.label) \(value!) of 5")
                        }
                    }
                    .padding(.top, 2)

                    Button(action: onSave) {
                        Text("Save")
                            .font(.footnote.bold())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .background(
                                WatchTheme.Colors.accentGradient,
                                in: Capsule()
                            )
                            .opacity(canSave ? 1.0 : 0.4)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 2)
                    .disabled(!canSave)
                    .accessibilityHint(canSave ? "Saves today's check-in" : "Score every dimension first")

                    if !canSave {
                        Text("Score every dimension to save")
                            .font(.system(size: 11))
                            .foregroundStyle(WatchTheme.Colors.textTertiary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.top, 16)   // headroom so content clears the overlaid progress dots
                .padding(.bottom, 6)
                .frame(maxWidth: .infinity, minHeight: proxy.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }
}

// MARK: - Preview

#Preview {
    WatchCheckInView(connectivity: WatchConnectivityManager())
        .preferredColorScheme(.dark)
}
