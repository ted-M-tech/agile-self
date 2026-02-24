//
//  WatchConnectivityManager.swift
//  agile-self Watch App
//
//  Watch-side WCSession manager. Sends check-in data to the paired iPhone.
//

import Foundation
import WatchConnectivity

/// Computes the composite score from the four dimension scores.
/// Stress is inverted (11 - stress) so lower stress contributes positively.
/// This matches the formula in DailyCheckIn.compositeScore on the iOS side.
func computeCompositeScore(energy: Int, focus: Int, stress: Int, growth: Int) -> Double {
    let invertedStress = 11 - stress
    return Double(energy + focus + invertedStress + growth) / 4.0
}

@Observable
final class WatchConnectivityManager: NSObject {

    // MARK: - State

    var todayCompositeScore: Double?
    var currentStreak: Int = 0
    var didCheckInToday: Bool = false

    private var session: WCSession?

    // MARK: - Init

    override init() {
        super.init()
    }

    // MARK: - Activation

    func activate() {
        guard WCSession.isSupported() else { return }
        session = WCSession.default
        session?.delegate = self
        session?.activate()
    }

    // MARK: - Send Check-In

    func sendCheckIn(energy: Int, focus: Int, stress: Int, growth: Int) {
        let payload: [String: Any] = [
            "type": "checkIn",
            "energy": energy,
            "focus": focus,
            "stress": stress,
            "growth": growth,
            "timestamp": Date().timeIntervalSince1970
        ]

        guard let session, session.isReachable else {
            // Fallback: queue for delivery when iPhone becomes reachable
            session?.transferUserInfo(payload)
            applyLocalState(energy: energy, focus: focus, stress: stress, growth: growth)
            return
        }

        session.sendMessage(payload, replyHandler: { [weak self] reply in
            Task { @MainActor in
                self?.handleReply(reply)
            }
        }, errorHandler: { [weak self] _ in
            // Fallback to transferUserInfo on error
            self?.session?.transferUserInfo(payload)
            Task { @MainActor in
                self?.applyLocalState(energy: energy, focus: focus, stress: stress, growth: growth)
            }
        })
    }

    // MARK: - State Management (internal for testability)

    func handleReply(_ reply: [String: Any]) {
        if let score = reply["compositeScore"] as? Double {
            todayCompositeScore = score
        }
        if let streak = reply["currentStreak"] as? Int {
            currentStreak = streak
        }
        didCheckInToday = true
    }

    func applyLocalState(energy: Int, focus: Int, stress: Int, growth: Int) {
        todayCompositeScore = computeCompositeScore(energy: energy, focus: focus, stress: stress, growth: growth)
        didCheckInToday = true
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        // Request current state from iPhone on activation
        if activationState == .activated {
            session.sendMessage(["type": "requestState"], replyHandler: { reply in
                Task { @MainActor in
                    self.handleReply(reply)
                }
            }, errorHandler: { _ in })
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any]
    ) {
        Task { @MainActor in
            self.handleReply(message)
        }
    }
}
