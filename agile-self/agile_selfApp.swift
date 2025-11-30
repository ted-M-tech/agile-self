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
    var sharedModelContainer: ModelContainer = {
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
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(sharedModelContainer)
    }
}
