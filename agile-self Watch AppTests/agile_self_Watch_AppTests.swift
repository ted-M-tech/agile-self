//
//  agile_self_Watch_AppTests.swift
//  agile-self Watch AppTests
//
//  Tests for Watch app logic: theme, dimension types, connectivity manager, composite score.
//

import Testing
import Foundation
@testable import agile_self_Watch_App

// MARK: - computeCompositeScore Tests

struct CompositeScoreTests {

    @Test
    func defaultScores() {
        let score = computeCompositeScore(energy: 3, focus: 3, calm: 3, growth: 3)
        // Plain mean: (3 + 3 + 3 + 3) / 4.0 = 3.0 (neutral default)
        #expect(score == 3.0)
    }

    @Test
    func allMaximum() {
        let score = computeCompositeScore(energy: 5, focus: 5, calm: 5, growth: 5)
        // (5 + 5 + 5 + 5) / 4.0 = 5.0
        #expect(score == 5.0)
    }

    @Test
    func allMinimum() {
        let score = computeCompositeScore(energy: 1, focus: 1, calm: 1, growth: 1)
        // (1 + 1 + 1 + 1) / 4.0 = 1.0
        #expect(score == 1.0)
    }

    @Test
    func calmRaisesComposite() {
        // Higher calm (up = better) yields a higher composite.
        let lowCalm = computeCompositeScore(energy: 3, focus: 3, calm: 1, growth: 3)
        let highCalm = computeCompositeScore(energy: 3, focus: 3, calm: 5, growth: 3)
        #expect(highCalm > lowCalm)
    }

    @Test
    func mixedValues() {
        let score = computeCompositeScore(energy: 4, focus: 3, calm: 4, growth: 2)
        // Plain mean: (4 + 3 + 4 + 2) / 4.0 = 3.25
        #expect(score == 3.25)
    }

    @Test
    func scoreAlwaysInRange() {
        for e in [1, 3, 5] {
            for f in [1, 3, 5] {
                for c in [1, 3, 5] {
                    for g in [1, 3, 5] {
                        let score = computeCompositeScore(energy: e, focus: f, calm: c, growth: g)
                        #expect(score >= 1.0)
                        #expect(score <= 5.0)
                    }
                }
            }
        }
    }

    @Test
    func symmetricScores() {
        // When all four dimensions are equal, the composite equals that value.
        let score = computeCompositeScore(energy: 4, focus: 4, calm: 4, growth: 4)
        #expect(score == 4.0)
    }
}

// MARK: - WatchDimensionType Tests

struct WatchDimensionTypeTests {

    @Test
    func allCasesCount() {
        #expect(WatchDimensionType.allCases.count == 4)
    }

    @Test
    func labels() {
        #expect(WatchDimensionType.energy.label == "Energy")
        #expect(WatchDimensionType.focus.label == "Focus")
        // The 4th axis is reframed to Calm (enum case + rawValue stay "stress").
        #expect(WatchDimensionType.stress.label == "Calm")
        #expect(WatchDimensionType.growth.label == "Growth")
    }

    @Test
    func icons() {
        #expect(WatchDimensionType.energy.icon == "bolt.fill")
        #expect(WatchDimensionType.focus.icon == "eye.fill")
        #expect(WatchDimensionType.stress.icon == "wind")
        #expect(WatchDimensionType.growth.icon == "leaf.fill")
    }

    @Test
    func rawValues() {
        #expect(WatchDimensionType.energy.rawValue == "energy")
        #expect(WatchDimensionType.focus.rawValue == "focus")
        #expect(WatchDimensionType.stress.rawValue == "stress")
        #expect(WatchDimensionType.growth.rawValue == "growth")
    }

    @Test
    func identifiable() {
        #expect(WatchDimensionType.energy.id == "energy")
        #expect(WatchDimensionType.focus.id == "focus")
        #expect(WatchDimensionType.stress.id == "stress")
        #expect(WatchDimensionType.growth.id == "growth")
    }

    @Test
    func codableRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for dim in WatchDimensionType.allCases {
            let data = try encoder.encode(dim)
            let decoded = try decoder.decode(WatchDimensionType.self, from: data)
            #expect(decoded == dim)
        }
    }

    @Test
    func decodableFromString() throws {
        let decoder = JSONDecoder()
        let data = Data("\"stress\"".utf8)
        let decoded = try decoder.decode(WatchDimensionType.self, from: data)
        #expect(decoded == .stress)
    }

    @Test
    func decodableFailsForInvalidString() {
        let decoder = JSONDecoder()
        let invalidData = Data("\"happiness\"".utf8)
        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(WatchDimensionType.self, from: invalidData)
        }
    }

    @Test
    func orderMatchesDimensionOrder() {
        let cases = WatchDimensionType.allCases
        #expect(cases[0] == .energy)
        #expect(cases[1] == .focus)
        #expect(cases[2] == .stress)
        #expect(cases[3] == .growth)
    }
}

// MARK: - WatchConnectivityManager State Tests

struct WatchConnectivityManagerTests {

    @Test
    func initialState() {
        let manager = WatchConnectivityManager()

        #expect(manager.todayCompositeScore == nil)
        #expect(manager.currentStreak == 0)
        #expect(manager.didCheckInToday == false)
    }

    @Test
    func handleReply_updatesCompositeScore() {
        let manager = WatchConnectivityManager()

        manager.handleReply(["compositeScore": 7.5])

        #expect(manager.todayCompositeScore == 7.5)
        #expect(manager.didCheckInToday == true)
    }

    @Test
    func handleReply_updatesStreak() {
        let manager = WatchConnectivityManager()

        manager.handleReply(["currentStreak": 5])

        #expect(manager.currentStreak == 5)
        #expect(manager.didCheckInToday == true)
    }

    @Test
    func handleReply_updatesBothScoreAndStreak() {
        let manager = WatchConnectivityManager()

        manager.handleReply([
            "compositeScore": 8.25,
            "currentStreak": 3
        ])

        #expect(manager.todayCompositeScore == 8.25)
        #expect(manager.currentStreak == 3)
        #expect(manager.didCheckInToday == true)
    }

    @Test
    func handleReply_emptyReply_stillMarksCheckedIn() {
        let manager = WatchConnectivityManager()

        manager.handleReply([:])

        #expect(manager.todayCompositeScore == nil)
        #expect(manager.currentStreak == 0)
        #expect(manager.didCheckInToday == true)
    }

    @Test
    func handleReply_wrongTypes_ignoredGracefully() {
        let manager = WatchConnectivityManager()

        manager.handleReply([
            "compositeScore": "not a double",
            "currentStreak": "not an int"
        ])

        #expect(manager.todayCompositeScore == nil)
        #expect(manager.currentStreak == 0)
        #expect(manager.didCheckInToday == true)
    }

    @Test
    func handleReply_multipleCallsOverwrite() {
        let manager = WatchConnectivityManager()

        manager.handleReply(["compositeScore": 5.0, "currentStreak": 1])
        manager.handleReply(["compositeScore": 8.0, "currentStreak": 2])

        #expect(manager.todayCompositeScore == 8.0)
        #expect(manager.currentStreak == 2)
    }

    @Test
    func applyLocalState_computesCorrectScore() {
        let manager = WatchConnectivityManager()

        manager.applyLocalState(energy: 4, focus: 4, calm: 2, growth: 5)

        // Plain mean: (4 + 4 + 2 + 5) / 4.0 = 3.75
        #expect(manager.todayCompositeScore == 3.75)
        #expect(manager.didCheckInToday == true)
    }

    @Test
    func applyLocalState_matchesComputeFunction() {
        let manager = WatchConnectivityManager()

        manager.applyLocalState(energy: 3, focus: 4, calm: 5, growth: 2)

        let expected = computeCompositeScore(energy: 3, focus: 4, calm: 5, growth: 2)
        #expect(manager.todayCompositeScore == expected)
    }

    @Test
    func applyLocalState_minScores() {
        let manager = WatchConnectivityManager()

        manager.applyLocalState(energy: 1, focus: 1, calm: 1, growth: 1)

        #expect(manager.todayCompositeScore == 1.0)
    }

    @Test
    func applyLocalState_maxScores() {
        let manager = WatchConnectivityManager()

        manager.applyLocalState(energy: 5, focus: 5, calm: 5, growth: 5)

        #expect(manager.todayCompositeScore == 5.0)
    }
}

// MARK: - WatchTheme Tests

struct WatchThemeTests {

    @Test
    func dimensionColorsExistForAllTypes() {
        // Verify no crashes when requesting colors for all dimension types
        for dim in WatchDimensionType.allCases {
            _ = WatchTheme.Dimension.color(for: dim)
        }
    }

    @Test
    func accentGradientExists() {
        // Verify gradient can be created without crash
        _ = WatchTheme.Colors.accentGradient
    }
}
