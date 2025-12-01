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
    @State private var containerError: Error?

    init() {
        let schema = Schema([
            Retrospective.self,
            KPTAItem.self,
            ActionItem.self,
            HealthSummary.self,
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )

        do {
            self.sharedModelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            self.sharedModelContainer = nil
            print("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            if let container = sharedModelContainer {
                MainTabView()
                    .modelContainer(container)
            } else {
                DatabaseErrorView()
            }
        }
    }
}

// MARK: - Database Error View

struct DatabaseErrorView: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.orange)

            Text("Unable to Load Data")
                .font(Theme.Typography.title2)
                .fontWeight(.semibold)

            Text("There was a problem loading your data. Please try restarting the app or contact support if the issue persists.")
                .font(Theme.Typography.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.xl)

            Button {
                // Attempt to restart or provide recovery option
                #if os(iOS)
                exit(0)
                #endif
            } label: {
                Text("Restart App")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.md)
                    .background(Theme.KPTA.action)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
            }
            .padding(.horizontal, Theme.Spacing.xl)
        }
        .padding()
    }
}
