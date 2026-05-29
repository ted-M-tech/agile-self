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
            WidgetSnapshotWriter.update(context: modelContext)
        }
    }

    // MARK: - First Launch Setup

    /// Creates a default UserProfile and Streak if none exist yet.
    private func ensureDefaultRecords() {
        var didInsert = false

        let profileDescriptor = FetchDescriptor<UserProfile>()
        if (try? modelContext.fetch(profileDescriptor))?.isEmpty ?? true {
            modelContext.insert(UserProfile())
            didInsert = true
        }

        let streakDescriptor = FetchDescriptor<Streak>()
        if (try? modelContext.fetch(streakDescriptor))?.isEmpty ?? true {
            modelContext.insert(Streak())
            didInsert = true
        }

        // Persist immediately so onboarding (which fetches the singleton profile to
        // write displayName / notification prefs / hasCompletedOnboarding) sees it on disk.
        if didInsert {
            try? modelContext.save()
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
