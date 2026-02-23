//
//  agile_selfApp.swift
//  agile-self
//
//  Created by Tetsuya Maeda on 2025/11/30.
//

import SwiftUI
import SwiftData

@main
struct agile_selfApp: App {
    private let sharedModelContainer: ModelContainer?
    private let appContainer: AppContainer?

    init() {
        let schema = Schema([
            DailyCheckIn.self,
            HealthSnapshot.self,
            WeeklyReview.self,
            MonthlyReport.self,
            ActionItemV2.self,
            UserProfile.self,
            Streak.self,
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )

        do {
            let container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            self.sharedModelContainer = container
            self.appContainer = AppContainer(modelContainer: container)
        } catch {
            self.sharedModelContainer = nil
            self.appContainer = nil
            print("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            if let container = sharedModelContainer, let appContainer {
                RootView()
                    .modelContainer(container)
                    .environment(appContainer)
            } else {
                DatabaseErrorView()
            }
        }
    }
}

// MARK: - Database Error View

struct DatabaseErrorView: View {
    var body: some View {
        ZStack {
            Theme.Colors.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: Theme.Spacing.lg) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Theme.Colors.warning)

                Text("Unable to Load Data")
                    .font(Theme.Typography.title2)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text("There was a problem loading your data. Please try restarting the app.")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.xl)

                Text("Please close and reopen the app to try again.")
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.Colors.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.xl)
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }
}
