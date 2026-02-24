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
        let score = computeCompositeScore(energy: 5, focus: 5, stress: 5, growth: 5)
        // invertedStress = 11 - 5 = 6; (5 + 5 + 6 + 5) / 4.0 = 5.25
        #expect(score == 5.25)
    }

    @Test
    func allMaximum() {
        let score = computeCompositeScore(energy: 10, focus: 10, stress: 1, growth: 10)
        // invertedStress = 11 - 1 = 10; (10 + 10 + 10 + 10) / 4.0 = 10.0
        #expect(score == 10.0)
    }

    @Test
    func allMinimum() {
        let score = computeCompositeScore(energy: 1, focus: 1, stress: 10, growth: 1)
        // invertedStress = 11 - 10 = 1; (1 + 1 + 1 + 1) / 4.0 = 1.0
        #expect(score == 1.0)
    }

    @Test
    func stressInversion() {
        let lowStress = computeCompositeScore(energy: 5, focus: 5, stress: 2, growth: 5)
        let highStress = computeCompositeScore(energy: 5, focus: 5, stress: 9, growth: 5)
        #expect(lowStress > highStress)
    }

    @Test
    func mixedValues() {
        let score = computeCompositeScore(energy: 8, focus: 6, stress: 3, growth: 7)
        // invertedStress = 11 - 3 = 8; (8 + 6 + 8 + 7) / 4.0 = 7.25
        #expect(score == 7.25)
    }

    @Test
    func scoreAlwaysInRange() {
        for e in [1, 5, 10] {
            for f in [1, 5, 10] {
                for s in [1, 5, 10] {
                    for g in [1, 5, 10] {
                        let score = computeCompositeScore(energy: e, focus: f, stress: s, growth: g)
                        #expect(score >= 1.0)
                        #expect(score <= 10.0)
                    }
                }
            }
        }
    }

    @Test
    func symmetricScores() {
        // When all dimensions have equal "effective" value, composite equals that value
        // energy=7, focus=7, stress=4 (inverted=7), growth=7 -> all 7 -> composite = 7.0
        let score = computeCompositeScore(energy: 7, focus: 7, stress: 4, growth: 7)
        #expect(score == 7.0)
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
        #expect(WatchDimensionType.stress.label == "Stress")
        #expect(WatchDimensionType.growth.label == "Growth")
    }

    @Test
    func icons() {
        #expect(WatchDimensionType.energy.icon == "bolt.fill")
        #expect(WatchDimensionType.focus.icon == "eye.fill")
        #expect(WatchDimensionType.stress.icon == "waveform.path.ecg")
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

        manager.applyLocalState(energy: 8, focus: 7, stress: 3, growth: 9)

        // (8 + 7 + 8 + 9) / 4.0 = 8.0
        #expect(manager.todayCompositeScore == 8.0)
        #expect(manager.didCheckInToday == true)
    }

    @Test
    func applyLocalState_matchesComputeFunction() {
        let manager = WatchConnectivityManager()

        manager.applyLocalState(energy: 3, focus: 7, stress: 9, growth: 4)

        let expected = computeCompositeScore(energy: 3, focus: 7, stress: 9, growth: 4)
        #expect(manager.todayCompositeScore == expected)
    }

    @Test
    func applyLocalState_minScores() {
        let manager = WatchConnectivityManager()

        manager.applyLocalState(energy: 1, focus: 1, stress: 10, growth: 1)

        #expect(manager.todayCompositeScore == 1.0)
    }

    @Test
    func applyLocalState_maxScores() {
        let manager = WatchConnectivityManager()

        manager.applyLocalState(energy: 10, focus: 10, stress: 1, growth: 10)

        #expect(manager.todayCompositeScore == 10.0)
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
