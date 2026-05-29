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
        // Versioned schema (V1) — stable migration foundation. See AppSchema.swift.
        let schema = Schema(versionedSchema: AppSchemaV1.self)

        // CloudKit is disabled for the free-account device build (no paid Apple
        // Developer Program → no iCloud container). `.automatic` without an iCloud
        // entitlement crashes/sync-fails on device. Re-enable in M6 after enrolling.
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )

        do {
            let container = try ModelContainer(
                for: schema,
                migrationPlan: AppMigrationPlan.self,
                configurations: [modelConfiguration]
            )
            self.sharedModelContainer = container
            let app = AppContainer(modelContainer: container)
            self.appContainer = app
            app.refreshCloudAIPreference(context: container.mainContext)
            app.watchConnectivityService.activate()
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
