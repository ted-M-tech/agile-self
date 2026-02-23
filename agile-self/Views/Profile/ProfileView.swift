//
//  ProfileView.swift
//  agile-self
//
//  Profile tab with user info, streak stats, action management, and settings.
//

import SwiftUI

struct ProfileView: View {
    private let profile = MockData.userProfile
    private let streak = MockData.streak
    @State private var actions = MockData.actionItems
    @State private var showCompletedActions = false

    private var activeActions: [ActionItemV2] {
        actions.filter { !$0.isCompleted }
    }

    private var completedActions: [ActionItemV2] {
        actions.filter { $0.isCompleted }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    profileHeader
                    streakSection
                    activeActionsSection
                    completedActionsSection
                    settingsSection
                    Spacer(minLength: Theme.Spacing.xxl)
                }
                .padding(.horizontal, Theme.Spacing.md)
            }
            .background(Theme.Colors.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("Profile")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Avatar
            Image(systemName: "person.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Theme.Colors.accentStart, Theme.Colors.accentEnd],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .accessibilityHidden(true)

            // Display name
            Text(profile.displayName ?? "User")
                .font(Theme.Typography.title1)
                .foregroundStyle(Theme.Colors.textPrimary)

            // Subscription badge
            Text(profile.subscriptionTier == .premium ? "Premium" : "Free")
                .pillStyle(
                    color: profile.subscriptionTier == .premium
                        ? Theme.Colors.accentStart
                        : Theme.Colors.textSecondary
                )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.lg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(profile.displayName ?? "User"), \(profile.subscriptionTier.rawValue) plan")
    }

    // MARK: - Streak Section

    private var streakSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            sectionHeader(title: "STREAK")

            HStack(spacing: Theme.Spacing.sm) {
                // Current streak (emphasized)
                VStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "flame.fill")
                        .font(.title2)
                        .foregroundStyle(Theme.Colors.warning)

                    Text("\(streak.currentStreak)")
                        .font(Theme.Typography.scoreLarge)
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Text("Current")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.lg)
                .background(Theme.Colors.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                        .stroke(Theme.Colors.warning.opacity(0.3), lineWidth: 1)
                )
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Current streak: \(streak.currentStreak) days")

                // Secondary stats
                VStack(spacing: Theme.Spacing.sm) {
                    streakMiniStat(
                        value: "\(streak.longestStreak)",
                        label: "Longest",
                        icon: "trophy.fill",
                        color: Theme.Dimension.energy
                    )

                    streakMiniStat(
                        value: "\(streak.totalCheckIns)",
                        label: "Total Check-ins",
                        icon: "checkmark.circle.fill",
                        color: Theme.Colors.success
                    )
                }
            }
        }
    }

    private func streakMiniStat(
        value: String,
        label: String,
        icon: String,
        color: Color
    ) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundStyle(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(Theme.Typography.scoreSmall)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text(label)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            Spacer()
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    // MARK: - Active Actions Section

    private var activeActionsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader(title: "ACTIVE ACTIONS", count: activeActions.count)

            if activeActions.isEmpty {
                emptyActionsView
            } else {
                VStack(spacing: 0) {
                    ForEach(activeActions, id: \.id) { action in
                        ActionRow(action: action) {
                            withAnimation(Theme.Animation.smooth) {
                                action.toggleCompletion()
                            }
                        }

                        if action.id != activeActions.last?.id {
                            Divider()
                                .overlay(Theme.Colors.divider)
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
                .background(Theme.Colors.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
            }
        }
    }

    private var emptyActionsView: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "checkmark.seal.fill")
                .font(.title)
                .foregroundStyle(Theme.Colors.success)

            Text("All caught up!")
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Colors.textPrimary)

            Text("No active actions right now.")
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.xl)
        .background(Theme.Colors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
    }

    // MARK: - Completed Actions Section

    private var completedActionsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Collapsible header
            Button {
                withAnimation(Theme.Animation.standard) {
                    showCompletedActions.toggle()
                }
            } label: {
                HStack {
                    sectionHeader(title: "COMPLETED", count: completedActions.count)

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.textTertiary)
                        .rotationEffect(.degrees(showCompletedActions ? 90 : 0))
                }
            }
            .buttonStyle(.plain)
            .disabled(completedActions.isEmpty)
            .accessibilityLabel("Completed actions, \(completedActions.count) items")
            .accessibilityHint(showCompletedActions ? "Double tap to collapse" : "Double tap to expand")

            if showCompletedActions && !completedActions.isEmpty {
                VStack(spacing: 0) {
                    ForEach(completedActions, id: \.id) { action in
                        ActionRow(action: action) {
                            withAnimation(Theme.Animation.smooth) {
                                action.toggleCompletion()
                            }
                        }

                        if action.id != completedActions.last?.id {
                            Divider()
                                .overlay(Theme.Colors.divider)
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
                .background(Theme.Colors.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Settings Section

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader(title: "SETTINGS")

            VStack(spacing: 0) {
                settingsRow(icon: "heart.fill", label: "Health Data", iconColor: .red)
                settingsDivider
                settingsRow(icon: "iphone", label: "Screen Time", iconColor: .cyan)
                settingsDivider
                settingsRow(icon: "bell.fill", label: "Notifications", iconColor: Theme.Colors.warning)
                settingsDivider
                settingsRow(icon: "crown.fill", label: "Subscription", iconColor: Theme.Dimension.energy)
                settingsDivider
                settingsRow(icon: "square.and.arrow.up", label: "Export Data", iconColor: Theme.Colors.success)
                settingsDivider
                settingsRow(icon: "info.circle", label: "About", iconColor: Theme.Colors.textSecondary)
            }
            .background(Theme.Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
        }
    }

    private func settingsRow(icon: String, label: String, iconColor: Color) -> some View {
        Button {
            // Navigation placeholder
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: icon)
                    .font(.callout)
                    .foregroundStyle(iconColor)
                    .frame(width: 24, height: 24)

                Text(label)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private var settingsDivider: some View {
        Divider()
            .overlay(Theme.Colors.divider)
            .padding(.leading, Theme.Spacing.md + 24 + Theme.Spacing.md) // Aligned past icon
    }

    // MARK: - Helpers

    private func sectionHeader(title: String, count: Int? = nil) -> some View {
        HStack(spacing: Theme.Spacing.xs) {
            Text(title)
                .font(Theme.Typography.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.Colors.textTertiary)
                .tracking(1.2)

            if let count {
                Text("\(count)")
                    .font(Theme.Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.Colors.accentStart)
            }

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    ProfileView()
        .preferredColorScheme(.dark)
}
