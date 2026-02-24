//
//  WatchConnectivityService.swift
//  agile-self
//
//  iOS-side WCSession service. Receives check-in data from Apple Watch
//  and persists it to SwiftData.
//

import Foundation
import WatchConnectivity
import SwiftData

@Observable
final class WatchConnectivityService: NSObject {

    // MARK: - Properties

    private var session: WCSession?
    let modelContainer: ModelContainer

    // MARK: - Init

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        super.init()
    }

    // MARK: - Activation

    func activate() {
        guard WCSession.isSupported() else { return }
        session = WCSession.default
        session?.delegate = self
        session?.activate()
    }

    // MARK: - Check-In Persistence (testable)

    /// Upserts a DailyCheckIn and updates the Streak for the given scores.
    /// Returns the reply dictionary with compositeScore and currentStreak.
    /// Synchronous on @MainActor — call directly from tests.
    func persistCheckIn(
        energy: Int,
        focus: Int,
        stress: Int,
        growth: Int,
        context: ModelContext
    ) throws -> [String: Any] {
        let today = Calendar.current.startOfDay(for: Date())

        // Upsert: find existing check-in for today or create new
        let descriptor = FetchDescriptor<DailyCheckIn>(
            predicate: #Predicate { $0.date == today }
        )
        let checkIn: DailyCheckIn
        if let existing = try context.fetch(descriptor).first {
            existing.energyScore = energy
            existing.focusScore = focus
            existing.stressScore = stress
            existing.growthScore = growth
            checkIn = existing
        } else {
            let newCheckIn = DailyCheckIn(
                date: today,
                energyScore: energy,
                focusScore: focus,
                stressScore: stress,
                growthScore: growth
            )
            context.insert(newCheckIn)
            checkIn = newCheckIn
        }

        // Update streak
        let streakDescriptor = FetchDescriptor<Streak>()
        let streak: Streak
        if let existing = try context.fetch(streakDescriptor).first {
            streak = existing
        } else {
            let newStreak = Streak()
            context.insert(newStreak)
            streak = newStreak
        }
        streak.recordCheckIn(on: today)

        try context.save()

        return [
            "compositeScore": checkIn.compositeScore,
            "currentStreak": streak.currentStreak
        ]
    }

    /// Fetches the current state (today's score + streak) for the reply.
    func fetchCurrentState(context: ModelContext) throws -> [String: Any] {
        let today = Calendar.current.startOfDay(for: Date())
        var reply: [String: Any] = [:]

        let checkInDescriptor = FetchDescriptor<DailyCheckIn>(
            predicate: #Predicate { $0.date == today }
        )
        if let todayCheckIn = try context.fetch(checkInDescriptor).first {
            reply["compositeScore"] = todayCheckIn.compositeScore
            reply["didCheckInToday"] = true
        }

        let streakDescriptor = FetchDescriptor<Streak>()
        if let streak = try context.fetch(streakDescriptor).first {
            reply["currentStreak"] = streak.currentStreak
        }

        return reply
    }

    // MARK: - Message Handlers

    func handleCheckIn(_ message: [String: Any], replyHandler: (([String: Any]) -> Void)? = nil) {
        guard
            let energy = message["energy"] as? Int,
            let focus = message["focus"] as? Int,
            let stress = message["stress"] as? Int,
            let growth = message["growth"] as? Int
        else { return }

        let container = modelContainer

        Task { @MainActor in
            let context = container.mainContext
            if let reply = try? self.persistCheckIn(
                energy: energy, focus: focus, stress: stress, growth: growth,
                context: context
            ) {
                replyHandler?(reply)
            }
        }
    }

    func handleStateRequest(replyHandler: @escaping ([String: Any]) -> Void) {
        let container = modelContainer

        Task { @MainActor in
            let context = container.mainContext
            if let reply = try? self.fetchCurrentState(context: context) {
                replyHandler(reply)
            } else {
                replyHandler([:])
            }
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityService: WCSessionDelegate {

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        // No action needed on iOS side
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        let messageType = message["type"] as? String

        Task { @MainActor in
            switch messageType {
            case "checkIn":
                self.handleCheckIn(message, replyHandler: replyHandler)
            case "requestState":
                self.handleStateRequest(replyHandler: replyHandler)
            default:
                replyHandler([:])
            }
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any]
    ) {
        if message["type"] as? String == "checkIn" {
            Task { @MainActor in
                self.handleCheckIn(message)
            }
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveUserInfo userInfo: [String: Any]
    ) {
        if userInfo["type"] as? String == "checkIn" {
            Task { @MainActor in
                self.handleCheckIn(userInfo)
            }
        }
    }
}
