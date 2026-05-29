//
//  ProfileView.swift
//  agile-self
//
//  Profile tab with user info, streak stats, action management, and settings.
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(AppContainer.self) private var appContainer
    @Environment(\.modelContext) private var modelContext

    // MARK: - ViewModel

    @State private var viewModel = ProfileViewModel()

    // MARK: - UI State

    @State private var showCompletedActions = false
    @State private var showAddAction = false
    @State private var showSettings = false
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    if let error = viewModel.errorMessage {
                        profileErrorView(message: error)
                    } else if viewModel.isLoading {
                        profileLoadingView
                    } else {
                        profileHeader
                        streakSection
                        activeActionsSection
                        completedActionsSection
                        settingsSection
                    }
                    Spacer(minLength: Theme.Spacing.xxl)
                }
                .padding(.horizontal, Theme.Spacing.md)
            }
            .background(Theme.Colors.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("Profile")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task {
                viewModel.configure(
                    streakService: appContainer.streakService,
                    subscriptionService: appContainer.subscriptionService
                )
                viewModel.loadData(context: modelContext)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddAction = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Theme.Colors.accentStart)
                    }
                    .accessibilityLabel("Add action")
                }
            }
            .sheet(isPresented: $showAddAction) {
                AddActionView { text, priority, deadline in
                    viewModel.addAction(text: text, priority: priority, deadline: deadline, context: modelContext)
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - Loading State

    private var profileLoadingView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer(minLength: 100)
            ProgressView()
                .tint(Theme.Colors.accentStart)
                .scaleEffect(1.2)
            Text("Loading profile...")
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Colors.textTertiary)
            Spacer(minLength: 100)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Error State

    private func profileErrorView(message: String) -> some View {
        VStack(spacing: Theme.Spacing.md) {
            Spacer(minLength: 80)
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(Theme.Colors.warning)

            Text("Something went wrong")
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Colors.textPrimary)

            Text(message)
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                viewModel.loadData(context: modelContext)
            } label: {
                Text("Try Again")
                    .secondaryButtonStyle()
            }
            Spacer(minLength: 80)
        }
        .frame(maxWidth: .infinity)
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
            Text(viewModel.profile?.displayName ?? "User")
                .font(Theme.Typography.title1)
                .foregroundStyle(Theme.Colors.textPrimary)

            // Subscription badge
            let tier = viewModel.profile?.subscriptionTier ?? .free
            Text(tier == .premium ? "Premium" : "Free")
                .pillStyle(
                    color: tier == .premium
                        ? Theme.Colors.accentStart
                        : Theme.Colors.textSecondary
                )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.lg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(viewModel.profile?.displayName ?? "User"), \(viewModel.profile?.subscriptionTier.rawValue ?? "free") plan")
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

                    Text("\(viewModel.streak?.currentStreak ?? 0)")
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
                .accessibilityLabel("Current streak: \(viewModel.streak?.currentStreak ?? 0) days")

                // Secondary stats
                VStack(spacing: Theme.Spacing.sm) {
                    streakMiniStat(
                        value: "\(viewModel.streak?.longestStreak ?? 0)",
                        label: "Longest",
                        icon: "trophy.fill",
                        color: Theme.Dimension.energy
                    )

                    streakMiniStat(
                        value: "\(viewModel.streak?.totalCheckIns ?? 0)",
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
            sectionHeader(title: "ACTIVE ACTIONS", count: viewModel.activeActions.count)

            if viewModel.activeActions.isEmpty {
                emptyActionsView
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.activeActions, id: \.id) { action in
                        ActionRow(action: action) {
                            withAnimation(Theme.Animation.smooth) {
                                viewModel.toggleAction(action)
                            }
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                withAnimation(Theme.Animation.smooth) {
                                    viewModel.deleteAction(action, context: modelContext)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }

                        if action.id != viewModel.activeActions.last?.id {
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
                    sectionHeader(title: "COMPLETED", count: viewModel.completedActions.count)

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.textTertiary)
                        .rotationEffect(.degrees(showCompletedActions ? 90 : 0))
                }
            }
            .buttonStyle(.plain)
            .disabled(viewModel.completedActions.isEmpty)
            .accessibilityLabel("Completed actions, \(viewModel.completedActions.count) items")
            .accessibilityHint(showCompletedActions ? "Double tap to collapse" : "Double tap to expand")

            if showCompletedActions && !viewModel.completedActions.isEmpty {
                VStack(spacing: 0) {
                    ForEach(viewModel.completedActions, id: \.id) { action in
                        ActionRow(action: action) {
                            withAnimation(Theme.Animation.smooth) {
                                viewModel.toggleAction(action)
                            }
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                withAnimation(Theme.Animation.smooth) {
                                    viewModel.deleteAction(action, context: modelContext)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }

                        if action.id != viewModel.completedActions.last?.id {
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
            sectionHeader(title: "PREFERENCES")

            VStack(spacing: 0) {
                settingsRow(icon: "heart.fill", label: "Health Data", iconColor: .red) { showSettings = true }
                settingsDivider
                settingsRow(icon: "iphone", label: "Screen Time", iconColor: .cyan) { showSettings = true }
                settingsDivider
                settingsRow(icon: "bell.fill", label: "Notifications", iconColor: Theme.Colors.warning) { showSettings = true }
                settingsDivider
                settingsRow(icon: "crown.fill", label: "Subscription", iconColor: Theme.Dimension.energy) { showPaywall = true }
                settingsDivider
                settingsRow(icon: "square.and.arrow.up", label: "Export Data", iconColor: Theme.Colors.success) { showSettings = true }
                settingsDivider
                settingsRow(icon: "info.circle", label: "About", iconColor: Theme.Colors.textSecondary) { showSettings = true }
            }
            .background(Theme.Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
        }
    }

    private func settingsRow(icon: String, label: String, iconColor: Color, action: @escaping () -> Void) -> some View {
        Button {
            action()
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
        .modelContainer(MockData.previewContainer)
        .environment(AppContainer(modelContainer: MockData.previewContainer))
        .preferredColorScheme(.dark)
}
