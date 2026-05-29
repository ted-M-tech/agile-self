//
//  ConnectionNarrator.swift
//  agile-self
//
//  Deterministic, honest narration of the connection between QUALITATIVE mood check-ins and
//  QUANTITATIVE Apple Health metrics. This is the app's core differentiator — surfaced as
//  plain-language sentences on Home ("Today's connection") and Insights ("Connections").
//
//  CONTRACT:
//  - Every NUMBER (correlation magnitude, average lift, today's metric value) is computed here
//    from real data via `AnalyticsService` and `HealthSnapshot`. The LLM may only rephrase the
//    prose; it must NEVER invent a statistic.
//  - Correlation ≠ causation. ALL copy uses "tends to" / "on days when" / "lines up with" —
//    NEVER "caused" / "because".
//

import Foundation

/// Pure (stateless) functions that turn deterministic correlation/health data into honest,
/// human-readable connection sentences. Shared by `OnDeviceAIService` (the always-available
/// heuristic) and `FoundationModelsAIService` (which feeds these as ground-truth into the LLM).
enum ConnectionNarrator {

    // MARK: - Health Factor → Dimension mapping

    /// A health metric paired with the mood dimension it tracks in `AnalyticsService`.
    private struct FactorBinding {
        let factor: String                 // matches Correlation.factor1 (e.g. "Sleep")
        let dimension: DimensionType        // the mood axis it correlates with
        /// Extracts the metric value from a snapshot (nil when unavailable).
        let value: (HealthSnapshot) -> Double?
        /// Formats the metric value for prose (e.g. 443 min → "7h 23m").
        let phrase: (Double) -> String
    }

    /// The same bindings AnalyticsService correlates on, in the order we prefer to narrate.
    private static let bindings: [FactorBinding] = [
        FactorBinding(
            factor: "Sleep",
            dimension: .focus,
            value: { $0.sleepMinutes.map(Double.init) },
            phrase: { Self.formatSleep(minutes: Int($0)) }
        ),
        FactorBinding(
            factor: "Steps",
            dimension: .energy,
            value: { $0.steps.map(Double.init) },
            phrase: { Self.formatSteps(Int($0)) }
        ),
        FactorBinding(
            factor: "Exercise",
            dimension: .growth,
            value: { $0.exerciseMinutes.map(Double.init) },
            phrase: { "\(Int($0)) min of exercise" }
        ),
        FactorBinding(
            factor: "Heart Rate",
            dimension: .stress,
            value: { $0.restingHeartRate.map(Double.init) },
            phrase: { "a resting heart rate of \(Int($0)) bpm" }
        ),
        FactorBinding(
            factor: "Running",
            dimension: .focus,
            value: { $0.runningDistanceMeters },
            phrase: { String(format: "%.1f km of running", $0 / 1000.0) }
        ),
    ]

    // MARK: - Connections (Insights)

    /// Up to 3 plain-language connection statements from deterministic correlations.
    /// Returns `[]` when AnalyticsService doesn't yet have enough matched data.
    static func connections(
        checkIns: [DailyCheckIn],
        health: [HealthSnapshot],
        analytics: AnalyticsService = AnalyticsService()
    ) -> [String] {
        let correlations = analytics.detectCorrelations(checkIns: checkIns, health: health)
        return connections(from: correlations, checkIns: checkIns, health: health)
    }

    /// Up to 3 connection statements built from already-computed correlations.
    static func connections(
        from correlations: [Correlation],
        checkIns: [DailyCheckIn],
        health: [HealthSnapshot]
    ) -> [String] {
        guard !correlations.isEmpty else { return [] }

        var statements: [String] = []
        for correlation in correlations.prefix(3) {
            statements.append(connectionSentence(for: correlation, checkIns: checkIns, health: health))
        }
        return statements
    }

    /// One honest sentence for a single correlation, enriched with a deterministic "lift"
    /// (the average dimension difference between the high-metric and low-metric halves) when
    /// it can be computed from matched same-day pairs.
    private static func connectionSentence(
        for correlation: Correlation,
        checkIns: [DailyCheckIn],
        health: [HealthSnapshot]
    ) -> String {
        let positive = correlation.coefficient >= 0
        let dimensionLabel = correlation.factor2  // already the Calm/Focus/Energy/Growth label
        let factor = correlation.factor1

        // Compute a concrete lift if we can resolve the matching binding.
        if let binding = bindings.first(where: { $0.factor == factor }),
           let lift = dimensionLift(binding: binding, checkIns: checkIns, health: health) {
            let liftText = String(format: "%.1f", abs(lift.delta))
            let metricPhrase = lift.highThresholdPhrase
            if positive {
                return "On days with more \(factor.lowercased()) (around \(metricPhrase)), your \(dimensionLabel) tends to run about +\(liftText) higher."
            } else {
                return "On days with more \(factor.lowercased()) (around \(metricPhrase)), your \(dimensionLabel) tends to run about \(liftText) lower."
            }
        }

        // Fallback: a qualitative sentence keyed to the sign, still honest and correlational.
        if positive {
            return "More \(factor.lowercased()) tends to line up with stronger \(dimensionLabel) days."
        } else {
            return "More \(factor.lowercased()) tends to line up with lower \(dimensionLabel) days."
        }
    }

    /// The average dimension score on the higher-metric half of matched days minus the lower
    /// half — a deterministic, real "lift". Returns nil when there aren't enough pairs.
    private struct DimensionLift {
        let delta: Double
        let highThresholdPhrase: String
    }

    private static func dimensionLift(
        binding: FactorBinding,
        checkIns: [DailyCheckIn],
        health: [HealthSnapshot]
    ) -> DimensionLift? {
        let calendar = Calendar.current
        var healthByDay: [Date: HealthSnapshot] = [:]
        for snapshot in health {
            healthByDay[calendar.startOfDay(for: snapshot.date)] = snapshot
        }

        var pairs: [(metric: Double, score: Double)] = []
        for checkIn in checkIns {
            let day = calendar.startOfDay(for: checkIn.date)
            guard let snapshot = healthByDay[day], let metric = binding.value(snapshot) else { continue }
            pairs.append((metric, Double(checkIn.score(for: binding.dimension))))
        }
        guard pairs.count >= 4 else { return nil }

        let sortedByMetric = pairs.sorted { $0.metric < $1.metric }
        let half = sortedByMetric.count / 2
        let lowHalf = sortedByMetric.prefix(half)
        let highHalf = sortedByMetric.suffix(half)
        guard !lowHalf.isEmpty, !highHalf.isEmpty else { return nil }

        let lowAvg = lowHalf.map(\.score).reduce(0, +) / Double(lowHalf.count)
        let highAvg = highHalf.map(\.score).reduce(0, +) / Double(highHalf.count)
        let highMetricAvg = highHalf.map(\.metric).reduce(0, +) / Double(highHalf.count)

        return DimensionLift(delta: highAvg - lowAvg, highThresholdPhrase: binding.phrase(highMetricAvg))
    }

    // MARK: - Today's connection (Home)

    /// ONE sentence connecting today's standout health metric to today's mood. Returns nil when
    /// there is no health data at all (so the UI hides the card).
    static func todayConnection(
        checkIn: DailyCheckIn,
        todayHealth: HealthSnapshot?,
        correlations: [Correlation]
    ) -> String? {
        guard let health = todayHealth, health.hasAnyMetric else { return nil }

        let moodWord = moodLabel(for: checkIn.compositeScore)

        // Prefer a metric that the user has an established correlation with.
        if let (binding, correlation) = standoutCorrelatedBinding(health: health, correlations: correlations) {
            let metricPhrase = binding.phrase(binding.value(health)!)
            let dimensionLabel = correlation.factor2
            let dimScore = checkIn.score(for: binding.dimension)
            let dimQuality = dimensionQuality(dimScore)
            let positive = correlation.coefficient >= 0
            let leaning = positive
                ? "you tend to feel more \(feelingWord(for: binding.dimension)) after more \(binding.factor.lowercased())"
                : "more \(binding.factor.lowercased()) tends to track lower \(dimensionLabel) for you"
            return "You logged \(metricPhrase) — and \(leaning). Today's \(dimensionLabel): \(dimQuality)."
        }

        // No established correlation yet → neutral PARALLEL observation of today's standouts.
        let standouts = standoutPhrases(health: health)
        guard !standouts.isEmpty else { return nil }
        let joined = listPhrase(standouts)
        return "Today you logged \(joined) alongside a \(moodWord) day."
    }

    /// Picks the health metric that (a) has a value today and (b) the user has an established
    /// correlation for — strongest correlation first.
    private static func standoutCorrelatedBinding(
        health: HealthSnapshot,
        correlations: [Correlation]
    ) -> (FactorBinding, Correlation)? {
        let ranked = correlations.sorted { abs($0.coefficient) > abs($1.coefficient) }
        for correlation in ranked {
            if let binding = bindings.first(where: { $0.factor == correlation.factor1 }),
               binding.value(health) != nil {
                return (binding, correlation)
            }
        }
        return nil
    }

    /// Up to two concrete metric phrases present in today's snapshot (sleep + steps preferred).
    private static func standoutPhrases(health: HealthSnapshot) -> [String] {
        var phrases: [String] = []
        if let sleep = health.formattedSleep { phrases.append("\(sleep) of sleep") }
        if let steps = health.formattedSteps { phrases.append("\(steps) steps") }
        if phrases.isEmpty, let bpm = health.formattedHeartRate { phrases.append("a resting heart rate of \(bpm)") }
        if phrases.isEmpty, let run = health.formattedRunDistance { phrases.append("\(run) of running") }
        return Array(phrases.prefix(2))
    }

    // MARK: - Formatting helpers

    private static func formatSleep(minutes: Int) -> String {
        let hours = minutes / 60
        let remaining = minutes % 60
        if hours > 0 && remaining > 0 { return "\(hours)h \(remaining)m" }
        if hours > 0 { return "\(hours)h" }
        return "\(remaining)m"
    }

    private static let stepsFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

    private static func formatSteps(_ steps: Int) -> String {
        (stepsFormatter.string(from: NSNumber(value: steps)) ?? "\(steps)") + " steps"
    }

    /// Joins 1–2 phrases naturally ("X" or "X and Y").
    private static func listPhrase(_ phrases: [String]) -> String {
        switch phrases.count {
        case 0: return ""
        case 1: return phrases[0]
        default: return "\(phrases[0]) and \(phrases[1])"
        }
    }

    /// Composite (1–5) → a warm one-word mood label for the parallel observation.
    private static func moodLabel(for composite: Double) -> String {
        switch composite {
        case 4.5...: return "Great"
        case 3.7..<4.5: return "Strong"
        case 3.0..<3.7: return "Steady"
        case 2.3..<3.0: return "Quiet"
        default: return "Tender"
        }
    }

    /// A single dimension score (1–5) → quality word for "Today's Focus: Good".
    private static func dimensionQuality(_ score: Int) -> String {
        switch score {
        case 5: return "Excellent"
        case 4: return "Good"
        case 3: return "Steady"
        case 2: return "Low"
        default: return "Very low"
        }
    }

    /// The "feel more ___" adjective for a dimension — reads naturally where the bare label
    /// would not ("feel more energized", not "feel more energy"; "more focused", "more calm").
    private static func feelingWord(for dimension: DimensionType) -> String {
        switch dimension {
        case .energy: return "energized"
        case .focus: return "focused"
        case .stress: return "calm"   // the Calm axis (stored under stressScore)
        case .growth: return "productive"
        }
    }
}
