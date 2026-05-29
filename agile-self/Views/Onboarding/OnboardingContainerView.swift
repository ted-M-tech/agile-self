//
//  OnboardingContainerView.swift
//  agile-self
//
//  4-screen onboarding flow: Welcome, How It Works, Permissions, First Check-in.
//

import SwiftUI
import SwiftData

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
    let onComplete: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var currentPage: OnboardingPage = .welcome
    @State private var animateWelcome = false
    @State private var userName: String = ""

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
        .preferredColorScheme(.dark)
    }

    // MARK: - Screen 1: Welcome

    private var welcomeScreen: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            // Logo area with 4-color particles
            ZStack {
                // Particle accents
                ForEach(Array(DimensionType.allCases.enumerated()), id: \.element) { index, dimension in
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
                .padding(.vertical, Theme.Spacing.md)
                .padding(.horizontal, Theme.Spacing.lg)
                .background(Theme.Colors.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
                .padding(.horizontal, Theme.Spacing.xl)
                .onAppear { nameFieldFocused = true }
                .accessibilityLabel("Your name")

            Spacer()

            Button {
                saveUserName()
                withAnimation(Theme.Animation.smooth) {
                    currentPage = .howItWorks
                }
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

    private func saveUserName() {
        let descriptor = FetchDescriptor<UserProfile>()
        guard let profile = try? modelContext.fetch(descriptor).first else { return }
        profile.displayName = userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : userName.trimmingCharacters(in: .whitespacesAndNewlines)
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
                    description: "Score your energy, focus, stress, and growth each day.",
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

    // MARK: - Screen 3: Permissions

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

                Text("Connect your data for deeper insights")
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            VStack(spacing: 0) {
                permissionRow(
                    icon: "heart.fill",
                    title: "Apple Health",
                    description: "Sleep, steps, heart rate, exercise",
                    iconColor: .red
                )

                Divider().overlay(Theme.Colors.divider)

                permissionRow(
                    icon: "bell.fill",
                    title: "Notifications",
                    description: "Daily reminders and insights",
                    iconColor: Theme.Colors.warning
                )
            }
            .background(Theme.Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
            .padding(.horizontal, Theme.Spacing.lg)

            Text("You can change these later in Settings")
                .font(Theme.Typography.footnote)
                .foregroundStyle(Theme.Colors.textTertiary)

            Spacer()

            Button {
                withAnimation(Theme.Animation.smooth) {
                    currentPage = .firstCheckIn
                }
            } label: {
                Text("Continue")
                    .primaryButtonStyle()
            }
            .buttonStyle(.plain)
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.xxl)
            .accessibilityHint("All permissions are optional. Tap to proceed.")
        }
    }

    @State private var healthEnabled = false
    @State private var notificationsEnabled = false

    private func permissionRow(
        icon: String,
        title: String,
        description: String,
        iconColor: Color
    ) -> some View {
        let binding: Binding<Bool> = {
            switch title {
            case "Apple Health": return $healthEnabled
            default: return $notificationsEnabled
            }
        }()

        return HStack(spacing: Theme.Spacing.md) {
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

            Toggle("", isOn: binding)
                .labelsHidden()
                .tint(Theme.Colors.accentStart)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(description)")
    }

    // MARK: - Screen 4: First Check-in

    @State private var sparklePhase = false

    private var firstCheckInScreen: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            // Sparkle animation area
            ZStack {
                ForEach(0..<6, id: \.self) { i in
                    Image(systemName: "sparkle")
                        .font(.system(size: CGFloat.random(in: 16...28)))
                        .foregroundStyle(
                            [Theme.Dimension.energy, Theme.Dimension.focus,
                             Theme.Dimension.stress, Theme.Dimension.growth,
                             Theme.Colors.accentStart, Theme.Colors.accentEnd][i]
                        )
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
                    onComplete()
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
                    onComplete()
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
    OnboardingContainerView(onComplete: {})
        .preferredColorScheme(.dark)
}
