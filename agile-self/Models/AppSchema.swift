//
//  AppSchema.swift
//  agile-self
//
//  Versioned schema definition + migration plan for SwiftData.
//
//  SchemaV1 = the seven independent @Model types (the current on-disk shape).
//  Adopting a VersionedSchema gives us a stable migration foundation: future
//  schema changes add a new `AppSchemaVN`, a `MigrationStage`, and re-point
//  `Schema(versionedSchema:)` in agile_selfApp at the newest version.
//
//  NOTE: a WeeklyReview <-> ActionItemV2 @Relationship (task #13) was prototyped
//  here but DEFERRED — its lightweight migration crashed when opening a store
//  created before versioning, and the relationship has no consumers yet. Re-add
//  it later as SchemaV2 with a verified (likely custom) migration stage once a
//  feature actually reads it.
//

import Foundation
import SwiftData

// MARK: - Schema V1

/// Version 1 of the persisted schema: seven independent @Model types.
enum AppSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            DailyCheckIn.self,
            HealthSnapshot.self,
            WeeklyReview.self,
            MonthlyReport.self,
            ActionItemV2.self,
            UserProfile.self,
            Streak.self,
        ]
    }
}

// MARK: - Migration Plan

/// Migration plan for the app's persistent store. Currently a single version
/// with no migration stages; new versions and their stages are appended here.
enum AppMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [AppSchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}
