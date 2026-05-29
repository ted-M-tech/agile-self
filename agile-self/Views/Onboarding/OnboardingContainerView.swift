//
//  OnboardingContainerView.swift
//  agile-self
//
//  5-screen onboarding flow: Welcome, Your Name, How It Works, Permissions, Ready.
//

import SwiftUI
import SwiftData
import UIKit

// MARK: - Onboarding Page

private enum OnboardingPage: Int, CaseIterable {
    case welcome = 0
    case yourName = 1
    case howItWorks = 2
    case permissions = 3
    case firstCheckIn = 4
}

// MARK: - OnboardingContainerView

struct OnboardingContainerView: View {
    /// Called when onboarding finishes. `openCheckIn == true` requests that the app
    /// open the daily check-in once it lands on Home (deep-link from "Start First Check-in").
    let onComplete: (_ openCheckIn: Bool) -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(AppContainer.self) private var appContainer
    @State private var currentPage: OnboardingPage = .welcome
    @State private var animateWelcome = false
    @State private var userName: String = ""

    init(onComplete: @escaping (_ openCheckIn: Bool) -> Void) {
        self.onComplete = onComplete
        // Page-control dots are near-invisible on the near-black background by default;
        // give them explicit Theme-tokened colors with adequate contrast.
        UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(Theme.Colors.accentStart)
        UIPageControl.appearance().pageIndicatorTintColor = UIColor(Theme.Colors.textTertiary)
    }

    var body: some View {
        ZStack {
            Theme.Colors.backgroundPrimary
                .ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    welcomeScreen
                        .tag(OnboardingPage.welcome)

                    yourNameScreen
                        .tag(OnboardingPage.yourName)

                    howItWorksScreen
                        .tag(OnboardingPage.howItWorks)

                    permissionsScreen
                        .tag(OnboardingPage.permissions)

                    firstCheckInScreen
                        .tag(OnboardingPage.firstCheckIn)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
            }
        }
        .overlay(alignment: .topLeading) { backButton }
        .preferredColorScheme(.dark)
    }

    /// Small Back chevron, hidden on the first page. Lets users correct a tap without
    /// only relying on the swipe gesture.
    @ViewBuilder
    private var backButton: some View {
        if currentPage != .welcome {
            Button {
                nameFieldFocused = false
                withAnimation(Theme.Animation.smooth) {
                    currentPage = OnboardingPage(rawValue: currentPage.rawValue - 1) ?? .welcome
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .padding(Theme.Spacing.md)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")
        }
    }

    // MARK: - Screen 1: Welcome

    private var welcomeScreen: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            // Logo area with 4-color particles
            ZStack {
                // Particle accents
                ForEach(Array(DimensionType.allCases.enumerated()), id: \.offset) { index, dimension in
                    Circle()
                        .fill(Theme.Dimension.color(for: dimension))
                        .frame(width: 12, height: 12)
                        .offset(particleOffset(index: index, total: 4, radius: animateWelcome ? 48 : 20))
                        .opacity(animateWelcome ? 0.9 : 0.3)
                        .blur(radius: animateWelcome ? 0 : 4)
                }

                Image(systemName: "sparkles")
                    .font(.system(size: 64))
                    .foregroundStyle(Theme.Colors.accentGradient)
                    .scaleEffect(animateWelcome ? 1.0 : 0.8)
            }
            .frame(width: 120, height: 120)
            .onAppear {
                withAnimation(Theme.Animation.ringFill) {
                    animateWelcome = true
                }
            }

            VStack(spacing: Theme.Spacing.sm) {
                Text("AGILE SELF")
                    .font(Theme.Typography.display)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .tracking(2)
                    .accessibilityAddTraits(.isHeader)

                Text("Turn Reflection Into Action")
                    .font(Theme.Typography.title3)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            Spacer()

            Button {
                withAnimation(Theme.Animation.smooth) {
                    currentPage = .yourName
                }
            } label: {
                Text("Get Started")
                    .primaryButtonStyle()
            }
            .buttonStyle(.plain)
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.xxl)
            .accessibilityHint("Proceed to enter your name")
        }
    }

    // MARK: - Screen 2: Your Name

    @FocusState private var nameFieldFocused: Bool

    private var yourNameScreen: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 56))
                .foregroundStyle(Theme.Colors.accentGradient)
                .accessibilityHidden(true)

            VStack(spacing: Theme.Spacing.sm) {
                Text("What's your name?")
                    .font(Theme.Typography.title1)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .accessibilityAddTraits(.isHeader)

                Text("We'll use this to personalize your experience.")
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            TextField("Your name", text: $userName)
                .font(Theme.Typography.title2)
                .foregroundStyle(Theme.Colors.textPrimary)
                .multilineTextAlignment(.center)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.words)
                .focused($nameFieldFocused)
                .submitLabel(.continue)
                .onSubmit { advanceFromName() }
                .padding(.vertical, Theme.Spacing.md)
                .padding(.horizontal, Theme.Spacing.lg)
                .background(Theme.Colors.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
                .padding(.horizontal, Theme.Spacing.xl)
                .onAppear { nameFieldFocused = true }
                .accessibilityLabel("Your name")

            Spacer()

            Button {
                advanceFromName()
            } label: {
                Text("Continue")
                    .primaryButtonStyle()
            }
            .buttonStyle(.plain)
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.xxl)
            .accessibilityHint("Save your name and continue")
        }
    }

    /// Dismisses the keyboard, saves the entered name, and advances to How It Works.
    /// Shared by the Continue button and the keyboard return key.
    private func advanceFromName() {
        nameFieldFocused = false
        saveUserName()
        withAnimation(Theme.Animation.smooth) {
            currentPage = .howItWorks
        }
    }

    private func saveUserName() {
        let descriptor = FetchDescriptor<UserProfile>()
        guard let profile = try? modelContext.fetch(descriptor).first else { return }
        profile.displayName = userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : userName.trimmingCharacters(in: .whitespacesAndNewlines)
        try? modelContext.save()
    }

    /// Requests the permissions the user toggled on, then persists the notification
    /// preference (and schedules reminders) to the singleton UserProfile.
    private func requestSelectedPermissions() async {
        if healthEnabled {
            try? await appContainer.healthKitService.requestAuthorization()
        }

        let descriptor = FetchDescriptor<UserProfile>()
        guard let profile = try? modelContext.fetch(descriptor).first else { return }

        if notificationsEnabled {
            let granted = await appContainer.notificationService.requestAuthorization()
            profile.notificationsEnabled = granted
            if granted {
                appContainer.notificationService.scheduleDailyReminder(
                    hour: profile.checkInReminderHour,
                    minute: profile.checkInReminderMinute
                )
                appContainer.notificationService.scheduleWeeklyReview(dayOfWeek: profile.weeklyReviewDay)
            }
        } else {
            profile.notificationsEnabled = false
            appContainer.notificationService.cancelAll()
        }

        try? modelContext.save()
    }

    /// Finishes onboarding by handing control back to RootView. RootView is the SINGLE
    /// writer of the completion flag (the @AppStorage gate AND the persisted profile flag,
    /// written together so they can never diverge). `openCheckIn` deep-links into the
    /// daily check-in once Home appears.
    private func completeOnboarding(openCheckIn: Bool) {
        onComplete(openCheckIn)
    }

    // MARK: - Screen 3: How It Works

    private var howItWorksScreen: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            Text("How It Works")
                .font(Theme.Typography.title1)
                .foregroundStyle(Theme.Colors.textPrimary)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: Theme.Spacing.md) {
                howItWorksCard(
                    icon: "sun.max.fill",
                    title: "Daily",
                    subtitle: "15 seconds",
                    description: "Score your energy, focus, calm, and growth each day.",
                    accentColor: Theme.Dimension.energy
                )

                // Connection line
                connectionLine

                howItWorksCard(
                    icon: "bubble.left.and.bubble.right.fill",
                    title: "Weekly",
                    subtitle: "3-5 minutes",
                    description: "AI-guided review to discover patterns and set actions.",
                    accentColor: Theme.Dimension.focus
                )

                connectionLine

                howItWorksCard(
                    icon: "chart.bar.doc.horizontal.fill",
                    title: "Monthly",
                    subtitle: "Automatic",
                    description: "AI-generated report with trends and correlations.",
                    accentColor: Theme.Dimension.growth
                )
            }
            .padding(.horizontal, Theme.Spacing.lg)

            Spacer()

            Button {
                withAnimation(Theme.Animation.smooth) {
                    currentPage = .permissions
                }
            } label: {
                Text("Continue")
                    .primaryButtonStyle()
            }
            .buttonStyle(.plain)
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.xxl)
        }
    }

    private func howItWorksCard(
        icon: String,
        title: String,
        subtitle: String,
        description: String,
        accentColor: Color
    ) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(accentColor)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                HStack(spacing: Theme.Spacing.sm) {
                    Text(title)
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Text(subtitle)
                        .pillStyle(color: accentColor)
                }

                Text(description)
                    .font(Theme.Typography.footnote)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .colorBorderCard(accentColor)
        .accessibilityElement(children: .combine)
    }

    private var connectionLine: some View {
        Rectangle()
            .fill(Theme.Colors.divider)
            .frame(width: 2, height: 16)
            .padding(.leading, Theme.Spacing.lg + 20)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Screen 4: Permissions

    private var permissionsScreen: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            VStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 48))
                    .foregroundStyle(Theme.Colors.accentGradient)

                Text("Permissions")
                    .font(Theme.Typography.title1)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .accessibilityAddTraits(.isHeader)

                Text("Connect your data for deeper insights. Turning a switch on will ask the system for permission when you continue.")
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 0) {
                permissionRow(
                    icon: "heart.fill",
                    title: "Apple Health",
                    description: "Sleep, steps, heart rate, exercise",
                    iconColor: .red,
                    isOn: $healthEnabled
                )

                Divider().overlay(Theme.Colors.divider)

                permissionRow(
                    icon: "bell.fill",
                    title: "Notifications",
                    description: "Daily reminders and insights",
                    iconColor: Theme.Colors.warning,
                    isOn: $notificationsEnabled
                )
            }
            .background(Theme.Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
            .padding(.horizontal, Theme.Spacing.lg)

            Text("Each switch triggers a system prompt. You can change these later in Settings.")
                .font(Theme.Typography.footnote)
                .foregroundStyle(Theme.Colors.textTertiary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Theme.Spacing.lg)

            Spacer()

            Button {
                isRequestingPermissions = true
                Task {
                    await requestSelectedPermissions()
                    isRequestingPermissions = false
                    withAnimation(Theme.Animation.smooth) {
                        currentPage = .firstCheckIn
                    }
                }
            } label: {
                Group {
                    if isRequestingPermissions {
                        HStack(spacing: Theme.Spacing.sm) {
                            ProgressView().tint(.white)
                            Text("Requesting…")
                        }
                    } else {
                        Text("Continue")
                    }
                }
                .primaryButtonStyle()
            }
            .buttonStyle(.plain)
            .disabled(isRequestingPermissions)
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.xxl)
            .accessibilityHint("All permissions are optional. Tap to proceed.")
        }
    }

    // Apple Health is the page's headline value-add, so it defaults ON. Notifications also
    // default ON. Each row binds to its own explicit @State (no fragile title-string switch).
    @State private var healthEnabled = true
    @State private var notificationsEnabled = true
    @State private var isRequestingPermissions = false

    private func permissionRow(
        icon: String,
        title: String,
        description: String,
        iconColor: Color,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(iconColor)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text(description)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Theme.Colors.accentStart)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(description)")
    }

    // MARK: - Screen 5: Ready

    @State private var sparklePhase = false

    /// 4 dimension colors (same source the Welcome screen uses) + the two accent tones,
    /// so the Ready sparkles match the rest of onboarding instead of a stale Stress token.
    private var sparklePalette: [Color] {
        DimensionType.allCases.map { Theme.Dimension.color(for: $0) }
            + [Theme.Colors.accentStart, Theme.Colors.accentEnd]
    }

    private var firstCheckInScreen: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            // Sparkle animation area
            ZStack {
                let palette = sparklePalette
                ForEach(0..<6, id: \.self) { i in
                    Image(systemName: "sparkle")
                        .font(.system(size: CGFloat.random(in: 16...28)))
                        .foregroundStyle(palette[i % palette.count])
                        .offset(sparkleOffset(index: i))
                        .opacity(sparklePhase ? 1.0 : 0.3)
                        .scaleEffect(sparklePhase ? 1.0 : 0.6)
                }

                Image(systemName: "pencil.and.list.clipboard")
                    .font(.system(size: 56))
                    .foregroundStyle(Theme.Colors.accentGradient)
            }
            .frame(width: 160, height: 160)
            .onAppear {
                withAnimation(Theme.Animation.ctaPulse) {
                    sparklePhase = true
                }
            }

            VStack(spacing: Theme.Spacing.sm) {
                Text("Ready to Start?")
                    .font(Theme.Typography.title1)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .accessibilityAddTraits(.isHeader)

                Text("Your first check-in takes just 15 seconds.")
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            VStack(spacing: Theme.Spacing.md) {
                Button {
                    completeOnboarding(openCheckIn: true)
                } label: {
                    HStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: "pencil.line")
                        Text("Start First Check-in")
                    }
                    .primaryButtonStyle()
                }
                .buttonStyle(.plain)
                .accessibilityHint("Opens the daily check-in form")

                Button {
                    completeOnboarding(openCheckIn: false)
                } label: {
                    Text("Skip for now")
                        .ghostButtonStyle()
                }
                .buttonStyle(.plain)
                .accessibilityHint("Skip the first check-in and go to the home screen")
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.xxl)
        }
    }

    // MARK: - Helpers

    private func particleOffset(index: Int, total: Int, radius: CGFloat) -> CGSize {
        let angle = (Double(index) / Double(total)) * 2 * .pi - .pi / 2
        return CGSize(
            width: Foundation.cos(angle) * radius,
            height: Foundation.sin(angle) * radius
        )
    }

    private func sparkleOffset(index: Int) -> CGSize {
        let offsets: [CGSize] = [
            CGSize(width: -50, height: -40),
            CGSize(width: 55, height: -30),
            CGSize(width: -40, height: 35),
            CGSize(width: 50, height: 40),
            CGSize(width: -20, height: -55),
            CGSize(width: 25, height: 55),
        ]
        return offsets[index % offsets.count]
    }
}

// MARK: - Preview

#Preview {
    OnboardingContainerView(onComplete: { _ in })
        .modelContainer(MockData.previewContainer)
        .environment(AppContainer(modelContainer: MockData.previewContainer))
        .preferredColorScheme(.dark)
}
