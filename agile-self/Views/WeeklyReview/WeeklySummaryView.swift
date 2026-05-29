//
//  WeeklySummaryView.swift
//  agile-self
//
//  Weekly summary with Wins, Challenges, Actions, and AI Takeaway sections.
//

import SwiftUI

// MARK: - WeeklySummaryView

struct WeeklySummaryView: View {
    let checkIns: [DailyCheckIn]
    let review: WeeklyReview?
    let result: WeeklySummaryResult?
    let isLoading: Bool
    let onDismiss: () -> Void

    @State private var actionCompleted: Set<String> = []
    @State private var animateContent = false

    // Prefer the freshly generated result, then the persisted review, then empty.
    private var wins: [String] { result?.wins ?? review?.wins ?? [] }
    private var challenges: [String] { result?.challenges ?? review?.challenges ?? [] }
    /// Suggested actions are ephemeral for M2 (shown live; not persisted on the review).
    private var actions: [String] { result?.suggestedActions ?? [] }
    private var aiTakeaway: String { result?.aiTakeaway ?? review?.aiTakeaway ?? "" }

    var body: some View {
        ZStack {
            Theme.Colors.backgroundPrimary
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                if isLoading {
                    loadingState
                } else {
                    ScrollView {
                        VStack(spacing: Theme.Spacing.lg) {
                            winsSection
                            challengesSection
                            actionsSection
                            aiTakeawaySection
                            shareButton
                            Spacer(minLength: Theme.Spacing.xxl)
                        }
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.top, Theme.Spacing.sm)
                    }
                    .scrollIndicators(.hidden)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(Theme.Animation.smooth.delay(0.2)) {
                animateContent = true
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Weekly Summary")
                    .font(Theme.Typography.title2)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .accessibilityAddTraits(.isHeader)

                Text(weekDateRange)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            Spacer()

            Button(action: onDismiss) {
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
        .padding(.vertical, Theme.Spacing.md)
    }

    private var weekDateRange: String {
        let start: Date?
        let end: Date?
        if let review {
            start = review.weekStart
            end = review.weekEnd
        } else {
            start = checkIns.map(\.date).min()
            end = checkIns.map(\.date).max()
        }
        guard let start, let end else { return "" }
        let startStr = start.formatted(.dateTime.month(.abbreviated).day())
        let endStr = end.formatted(.dateTime.month(.abbreviated).day())
        return "\(startStr) - \(endStr)"
    }

    // MARK: - Wins Section

    private var winsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader(title: "WINS", icon: "trophy.fill", color: Theme.Colors.success)

            if wins.isEmpty {
                sectionEmptyText("No standout wins recorded this week.")
            }
            ForEach(Array(wins.enumerated()), id: \.offset) { index, win in
                HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.callout)
                        .foregroundStyle(Theme.Colors.success)

                    Text(win)
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .colorBorderCard(Theme.Dimension.growth)
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 10)
                .animation(Theme.Animation.springStagger(index: index), value: animateContent)
            }
        }
    }

    // MARK: - Challenges Section

    private var challengesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader(title: "CHALLENGES", icon: "exclamationmark.triangle.fill", color: Theme.Colors.warning)

            if challenges.isEmpty {
                sectionEmptyText("No notable challenges this week.")
            }
            ForEach(Array(challenges.enumerated()), id: \.offset) { index, challenge in
                HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.callout)
                        .foregroundStyle(Theme.Colors.warning)

                    Text(challenge)
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .colorBorderCard(Theme.Dimension.stress)
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 10)
                .animation(Theme.Animation.springStagger(index: index + wins.count), value: animateContent)
            }
        }
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader(title: "ACTIONS", icon: "list.bullet.circle.fill", color: Theme.Dimension.focus)

            if actions.isEmpty {
                sectionEmptyText("No suggested actions yet.")
            }
            ForEach(Array(actions.enumerated()), id: \.offset) { index, action in
                Button {
                    withAnimation(Theme.Animation.smooth) {
                        if actionCompleted.contains(action) {
                            actionCompleted.remove(action)
                        } else {
                            actionCompleted.insert(action)
                        }
                    }
                } label: {
                    HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                        Image(systemName: actionCompleted.contains(action)
                              ? "checkmark.square.fill"
                              : "square")
                            .font(.title3)
                            .foregroundStyle(
                                actionCompleted.contains(action)
                                    ? Theme.Colors.success
                                    : Theme.Colors.textTertiary
                            )

                        Text(action)
                            .font(Theme.Typography.body)
                            .foregroundStyle(
                                actionCompleted.contains(action)
                                    ? Theme.Colors.textTertiary
                                    : Theme.Colors.textPrimary
                            )
                            .strikethrough(actionCompleted.contains(action))
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)

                        Spacer(minLength: 0)
                    }
                    .colorBorderCard(Theme.Dimension.focus)
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.selection, trigger: actionCompleted.contains(action))
                .accessibilityLabel(action)
                .accessibilityValue(actionCompleted.contains(action) ? "completed" : "not completed")
                .accessibilityHint("Double tap to toggle completion")
            }
        }
    }

    // MARK: - AI Takeaway

    private var aiTakeawaySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader(title: "AI TAKEAWAY", icon: "brain.head.profile.fill", color: Theme.Colors.accentStart)

            if aiTakeaway.isEmpty {
                sectionEmptyText("Your AI takeaway will appear here after the review.")
            } else {
                HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                    Image(systemName: "lightbulb.fill")
                        .font(.callout)
                        .foregroundStyle(Theme.Colors.accentStart)

                    Text(aiTakeaway)
                        .font(Theme.Typography.body)
                        .italic()
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(4)
                }
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.backgroundTertiary)
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                        .stroke(Theme.Colors.accentGradient, lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Share Button

    @ViewBuilder
    private var shareButton: some View {
        if let review {
            ShareLink(
                item: ShareContentBuilder.weeklySummaryText(review),
                subject: Text("My Weekly Summary")
            ) {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Summary")
                }
                .secondaryButtonStyle()
            }
            .accessibilityHint("Share the weekly summary via the share sheet")
        }
    }

    // MARK: - Loading / Empty Helpers

    private var loadingState: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            ProgressView()
                .tint(Theme.Colors.accentStart)
                .scaleEffect(1.2)
            Text("Summarizing your week...")
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Colors.textTertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func sectionEmptyText(_ text: String) -> some View {
        Text(text)
            .font(Theme.Typography.callout)
            .foregroundStyle(Theme.Colors.textTertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Theme.Spacing.md)
    }

    // MARK: - Helpers

    private func sectionHeader(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .font(.footnote)
                .foregroundStyle(color)

            Text(title)
                .font(Theme.Typography.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.Colors.textTertiary)
                .tracking(1.2)

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    WeeklySummaryView(
        checkIns: MockData.weeklyCheckIns,
        review: nil,
        result: WeeklySummaryResult(
            wins: ["Maintained a 12-day check-in streak", "Focus improved 18% vs last week"],
            challenges: ["Stress spiked on Wednesday"],
            summary: "A strong week overall.",
            aiTakeaway: "Block 30 minutes of no-meeting time on Wednesdays.",
            suggestedActions: ["Block no-meeting time on Wednesdays", "Run 3 times this week"]
        ),
        isLoading: false,
        onDismiss: {}
    )
}
