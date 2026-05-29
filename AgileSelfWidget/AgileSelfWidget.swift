//
//  AgileSelfWidget.swift
//  AgileSelfWidget
//
//  Home-screen widget showing today's composite score, 4-axis dimensions, and streak.
//  Reads a WidgetSnapshot published by the app via the App Group "group.tetsuya.agile-self".
//

import WidgetKit
import SwiftUI
import os

// Widget-side diagnostics (own subsystem; stream with subsystem BEGINSWITH "tetsuya.agile-self").
// This is the decisive M4 check: did the widget READ the shared App Group snapshot, or fall
// back to .sample because the App Group entitlement is missing/empty?
private let wlog = Logger(subsystem: "tetsuya.agile-self.AgileSelfWidget", category: "Widget")

// MARK: - Snapshot (extension-side mirror of the app's WidgetSnapshot)
// Kept as a minimal copy to avoid a shared-framework dependency for the PoC. The shape
// and App Group key MUST stay in sync with agile-self/Widget/WidgetSnapshot.swift.

struct WidgetSnapshot: Codable {
    var date: Date
    var hasCheckInToday: Bool
    var compositeScore: Double
    var energyScore: Int?
    var focusScore: Int?
    var stressScore: Int?
    var growthScore: Int?
    var currentStreak: Int
    var updatedAt: Date

    static let appGroupID = "group.tetsuya.agile-self"
    static let defaultsKey = "widgetSnapshot.v1"

    static func load() -> WidgetSnapshot? {
        guard let defaults = UserDefaults(suiteName: appGroupID) else {
            wlog.error("load: UserDefaults(suiteName:\(appGroupID, privacy: .public)) is nil")
            return nil
        }
        guard let data = defaults.data(forKey: defaultsKey) else {
            wlog.notice("load: no data at key=\(defaultsKey, privacy: .public) → App Group empty or entitlement missing → using .sample")
            return nil
        }
        guard let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data) else {
            wlog.error("load: decode failed (\(data.count, privacy: .public) bytes)")
            return nil
        }
        wlog.notice("load: OK hasCheckIn=\(snapshot.hasCheckInToday, privacy: .public) composite=\(snapshot.compositeScore, privacy: .public) streak=\(snapshot.currentStreak, privacy: .public) (reading REAL shared data)")
        return snapshot
    }

    // stressScore stores Calm (high = good); a good sample day has high calm. Scores are 1–5.
    static let sample = WidgetSnapshot(
        date: Date(), hasCheckInToday: true, compositeScore: 4.25,
        energyScore: 4, focusScore: 4, stressScore: 5, growthScore: 4,
        currentStreak: 12, updatedAt: Date()
    )
}

// MARK: - Theme (inline; the app's Theme.swift is not a member of this target)

private enum WTheme {
    static let bg = Color(red: 0.039, green: 0.039, blue: 0.059)
    static let accentStart = Color(red: 0.424, green: 0.361, blue: 0.906)
    static let accentEnd = Color(red: 0.635, green: 0.608, blue: 0.996)
    static let textPrimary = Color(red: 0.941, green: 0.941, blue: 0.961)
    static let textSecondary = Color(red: 0.533, green: 0.533, blue: 0.627)
    static let energy = Color(red: 0.992, green: 0.796, blue: 0.431)
    static let focus = Color(red: 0.455, green: 0.722, blue: 1.0)
    static let stress = Color(red: 1.0, green: 0.420, blue: 0.420)
    static let growth = Color(red: 0.333, green: 0.937, blue: 0.769)
    static let accent = LinearGradient(colors: [accentStart, accentEnd], startPoint: .topLeading, endPoint: .bottomTrailing)
}

// MARK: - Timeline

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry(date: Date(), snapshot: .sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> Void) {
        completion(WidgetEntry(date: Date(), snapshot: WidgetSnapshot.load() ?? .sample))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> Void) {
        let entry = WidgetEntry(date: Date(), snapshot: WidgetSnapshot.load())
        // Refresh at the start of tomorrow so the "today" framing stays correct; app
        // events (check-in, launch) also call WidgetCenter.reloadAllTimelines().
        let tomorrow = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        )
        completion(Timeline(entries: [entry], policy: .after(tomorrow)))
    }
}

struct WidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?
}

// MARK: - Views

struct AgileSelfWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: Provider.Entry

    private var snapshot: WidgetSnapshot? { entry.snapshot }

    var body: some View {
        switch family {
        case .systemMedium: mediumView
        default: smallView
        }
    }

    private var header: some View {
        HStack {
            Text("AGILE SELF")
                .font(.system(size: 9, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(WTheme.textSecondary)
            Spacer()
            streakBadge
        }
    }

    private var streakBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: "flame.fill")
                .font(.system(size: 10))
                .foregroundStyle(WTheme.energy)
            Text("\(snapshot?.currentStreak ?? 0)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(WTheme.textPrimary)
        }
    }

    @ViewBuilder
    private var scoreBlock: some View {
        if let s = snapshot, s.hasCheckInToday {
            Text(String(format: "%.1f", s.compositeScore))
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(WTheme.accent)
            Text("Today's score")
                .font(.system(size: 11))
                .foregroundStyle(WTheme.textSecondary)
        } else {
            Text("\u{2014}")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(WTheme.textSecondary)
            Text("Log today's check-in")
                .font(.system(size: 11))
                .foregroundStyle(WTheme.textSecondary)
        }
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 4) {
            header
            Spacer()
            scoreBlock
            Spacer()
        }
    }

    private var mediumView: some View {
        HStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                header
                Spacer()
                scoreBlock
                Spacer()
            }
            VStack(spacing: 7) {
                dimRow("Energy", snapshot?.energyScore, WTheme.energy)
                dimRow("Focus", snapshot?.focusScore, WTheme.focus)
                // stressScore now holds the Calm value (high = full bar = good).
                dimRow("Calm", snapshot?.stressScore, WTheme.stress)
                dimRow("Growth", snapshot?.growthScore, WTheme.growth)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func dimRow(_ label: String, _ value: Int?, _ color: Color) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(WTheme.textSecondary)
                .frame(width: 46, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(color.opacity(0.2)).frame(height: 5)
                    Capsule().fill(color)
                        .frame(width: geo.size.width * CGFloat(value ?? 0) / 5.0, height: 5)
                }
            }
            .frame(height: 5)
            Text(value.map { "\($0)" } ?? "\u{2014}")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(WTheme.textPrimary)
                .frame(width: 16, alignment: .trailing)
        }
    }
}

// MARK: - Widget

struct AgileSelfWidget: Widget {
    let kind: String = "AgileSelfWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            AgileSelfWidgetEntryView(entry: entry)
                .containerBackground(WTheme.bg, for: .widget)
        }
        .configurationDisplayName("Agile Self")
        .description("Today's composite score, dimensions, and streak.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    AgileSelfWidget()
} timeline: {
    WidgetEntry(date: .now, snapshot: .sample)
    WidgetEntry(date: .now, snapshot: nil)
}
