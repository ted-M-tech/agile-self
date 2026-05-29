//
//  AppLog.swift
//  agile-self
//
//  Lightweight os.Logger channels for on-device verification diagnostics (M2/M3/M4).
//  These let us confirm device-only behaviors from the log stream instead of guessing
//  by eye — which AI backend ran, what the widget snapshot contains, whether a check-in
//  upserted, and which Health metrics returned.
//
//  Watch live on a connected device (no Xcode needed):
//      log stream --device --predicate 'subsystem BEGINSWITH "tetsuya.agile-self"'
//  Or narrow to one channel:
//      log stream --device --predicate 'subsystem == "tetsuya.agile-self" AND category == "AI"'
//
//  Privacy: only scores / booleans / counts are logged (marked .public so they appear in
//  the stream). User note TEXT is never logged — only whether a note exists.
//

import Foundation
import os

enum AppLog {
    private static let subsystem = "tetsuya.agile-self"

    /// On-device AI: which backend served each request (foundationModels vs heuristic).
    static let ai = Logger(subsystem: subsystem, category: "AI")
    /// Widget snapshot publishing from the app side.
    static let widget = Logger(subsystem: subsystem, category: "Widget")
    /// Daily check-in create/upsert.
    static let checkIn = Logger(subsystem: subsystem, category: "CheckIn")
    /// HealthKit fetch results (which metrics returned).
    static let health = Logger(subsystem: subsystem, category: "Health")
}
