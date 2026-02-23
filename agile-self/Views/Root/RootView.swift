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
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            Theme.Colors.backgroundPrimary
                .ignoresSafeArea()

            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingContainerView {
                    withAnimation(Theme.Animation.smooth) {
                        hasCompletedOnboarding = true
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .task {
            ensureDefaultRecords()
        }
    }

    // MARK: - First Launch Setup

    /// Creates a default UserProfile and Streak if none exist yet.
    private func ensureDefaultRecords() {
        let profileDescriptor = FetchDescriptor<UserProfile>()
        if (try? modelContext.fetch(profileDescriptor))?.isEmpty ?? true {
            let profile = UserProfile()
            modelContext.insert(profile)
        }

        let streakDescriptor = FetchDescriptor<Streak>()
        if (try? modelContext.fetch(streakDescriptor))?.isEmpty ?? true {
            let streak = Streak()
            modelContext.insert(streak)
        }
    }
}

// MARK: - Preview

#Preview("Main App") {
    RootView()
        .modelContainer(MockData.previewContainer)
        .environment(AppContainer(modelContainer: MockData.previewContainer))
}

#Preview("Onboarding") {
    RootView()
        .modelContainer(MockData.previewContainer)
        .environment(AppContainer(modelContainer: MockData.previewContainer))
        .onAppear {
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        }
}
