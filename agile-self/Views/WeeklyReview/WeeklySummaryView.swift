//
//  WeeklySummaryView.swift
//  agile-self
//
//  Weekly summary with Wins, Challenges, Actions, and AI Takeaway sections.
//

import SwiftUI

// MARK: - WeeklySummaryView

struct WeeklySummaryView: View {
    let onDismiss: () -> Void

    @State private var actionCompleted: Set<String> = []
    @State private var animateContent = false

    private let wins = [
        "Maintained a 12-day check-in streak",
        "Focus scores improved by 18% vs last week",
        "Ran 3 times this week (11km total)",
    ]

    private let challenges = [
        "Stress spiked on Wednesday - back-to-back meetings",
        "Screen time exceeded 3h on 4 of 7 days",
    ]

    private let actions = [
        "Block 30min no-meeting time on Wednesdays",
        "Run at least 3 times this week",
        "Try a 5-minute meditation before bed",
    ]

    private let aiTakeaway = "Try blocking 30 minutes of no-meeting time on Wednesdays. Your data shows a clear focus-stress correlation on meeting-heavy days."

    var body: some View {
        ZStack {
            Theme.Colors.backgroundPrimary
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

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
        let checkIns = MockData.weeklyCheckIns
        guard let first = checkIns.first, let last = checkIns.last else { return "" }
        let startStr = first.date.formatted(.dateTime.month(.abbreviated).day())
        let endStr = last.date.formatted(.dateTime.month(.abbreviated).day())
        return "\(startStr) - \(endStr)"
    }

    // MARK: - Wins Section

    private var winsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader(title: "WINS", icon: "trophy.fill", color: Theme.Colors.success)

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

    // MARK: - Share Button

    private var shareButton: some View {
        Button {
            // Share action placeholder
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "square.and.arrow.up")
                Text("Share Summary")
            }
            .secondaryButtonStyle()
        }
        .buttonStyle(.plain)
        .accessibilityHint("Share the weekly summary via the share sheet")
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
    WeeklySummaryView(onDismiss: {})
}
