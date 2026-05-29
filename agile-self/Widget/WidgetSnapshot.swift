//
//  WidgetSnapshot.swift
//  agile-self
//
//  Compact snapshot of today's state, shared with the home-screen widget via the App
//  Group. The widget target reads the same key/shape (add this file to the widget
//  target's membership so the type is shared — no duplication).
//

import Foundation

struct WidgetSnapshot: Codable {
    /// Start-of-day this snapshot represents.
    var date: Date
    var hasCheckInToday: Bool
    /// Composite score (1-10); 0 when no check-in yet today.
    var compositeScore: Double
    var energyScore: Int?
    var focusScore: Int?
    var stressScore: Int?
    var growthScore: Int?
    var currentStreak: Int
    var updatedAt: Date

    /// App Group shared between the app and the widget (free-account-confirmed).
    static let appGroupID = "group.tetsuya.agile-self"
    /// UserDefaults key under the App Group suite.
    static let defaultsKey = "widgetSnapshot.v1"

    /// Reads the latest snapshot from the App Group, if any. Used by the widget.
    static func load() -> WidgetSnapshot? {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: defaultsKey),
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data) else {
            return nil
        }
        return snapshot
    }
}
