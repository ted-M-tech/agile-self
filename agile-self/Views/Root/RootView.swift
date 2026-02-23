//
//  RootView.swift
//  agile-self
//
//  Root wrapper that gates onboarding vs main app.
//

import SwiftUI
import SwiftData

// MARK: - RootView

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true

    var body: some View {
        ZStack {
            Theme.Colors.backgroundPrimary
                .ignoresSafeArea()

            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingPlaceholderView {
                    hasCompletedOnboarding = true
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - OnboardingPlaceholderView

/// Temporary placeholder until the real onboarding flow is built.
private struct OnboardingPlaceholderView: View {
    var onSkip: () -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 56))
                .foregroundStyle(Theme.Colors.accentGradient)

            Text("Onboarding Coming Soon")
                .font(Theme.Typography.title1)
                .foregroundStyle(Theme.Colors.textPrimary)

            Text("Set up your profile, connect Health, and personalize your experience.")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.xl)

            Spacer()

            Button(action: onSkip) {
                Text("Skip for Now")
            }
            .primaryButtonStyle()
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.xl)
        }
    }
}

// MARK: - Preview

#Preview("Main App") {
    RootView()
        .modelContainer(MockData.previewContainer)
}

#Preview("Onboarding") {
    RootView()
        .modelContainer(MockData.previewContainer)
        .onAppear {
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        }
}
