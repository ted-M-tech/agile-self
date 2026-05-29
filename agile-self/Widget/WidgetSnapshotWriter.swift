//
//  WidgetSnapshotWriter.swift
//  agile-self
//
//  Builds today's WidgetSnapshot from SwiftData and publishes it to the App Group, then
//  asks WidgetKit to reload. Free-account safe: refresh is driven by app events
//  (launch, check-in) — no remote push required.
//

import Foundation
import SwiftData
import os
#if canImport(WidgetKit)
import WidgetKit
#endif

enum WidgetSnapshotWriter {

    /// Recomputes and publishes the widget snapshot. Call on the main actor (it reads the
    /// main ModelContext).
    static func update(context: ModelContext) {
        let today = Calendar.current.startOfDay(for: Date())

        let checkIn = (try? context.fetch(
            FetchDescriptor<DailyCheckIn>(predicate: #Predicate { $0.date == today })
        ))?.first
        let streak = (try? context.fetch(FetchDescriptor<Streak>()))?.first

        let snapshot = WidgetSnapshot(
            date: today,
            hasCheckInToday: checkIn != nil,
            compositeScore: checkIn?.compositeScore ?? 0,
            energyScore: checkIn?.energyScore,
            focusScore: checkIn?.focusScore,
            stressScore: checkIn?.stressScore,
            growthScore: checkIn?.growthScore,
            currentStreak: streak?.currentStreak ?? 0,
            updatedAt: Date()
        )

        AppLog.widget.notice("publish hasCheckIn=\(snapshot.hasCheckInToday, privacy: .public) composite=\(snapshot.compositeScore, privacy: .public) e=\(snapshot.energyScore ?? -1, privacy: .public) f=\(snapshot.focusScore ?? -1, privacy: .public) s=\(snapshot.stressScore ?? -1, privacy: .public) g=\(snapshot.growthScore ?? -1, privacy: .public) streak=\(snapshot.currentStreak, privacy: .public)")

        guard let defaults = UserDefaults(suiteName: WidgetSnapshot.appGroupID),
              let data = try? JSONEncoder().encode(snapshot) else {
            AppLog.widget.error("publish FAILED — could not open App Group suite=\(WidgetSnapshot.appGroupID, privacy: .public) or encode")
            return
        }
        defaults.set(data, forKey: WidgetSnapshot.defaultsKey)
        AppLog.widget.notice("publish WROTE \(data.count, privacy: .public) bytes to App Group key=\(WidgetSnapshot.defaultsKey, privacy: .public)")

        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}
