//
//  ScreenTimeManager.swift
//  agile-self
//
//  Created by Claude on 2025/12/01.
//

import Foundation
import FamilyControls

/// Manager for Screen Time authorization using FamilyControls
@MainActor
@Observable
final class ScreenTimeManager {
    static let shared = ScreenTimeManager()

    // MARK: - Authorization State

    enum AuthorizationStatus {
        case notDetermined
        case authorized
        case denied
    }

    private(set) var authorizationStatus: AuthorizationStatus = .notDetermined
    private(set) var isRequesting: Bool = false

    // MARK: - Init

    private init() {
        // Check if already authorized
        Task {
            await checkAuthorizationStatus()
        }
    }

    // MARK: - Authorization

    /// Request authorization for individual device monitoring (iOS 16+)
    func requestAuthorization() async {
        guard authorizationStatus != .authorized else { return }

        isRequesting = true
        defer { isRequesting = false }

        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            authorizationStatus = .authorized
        } catch {
            authorizationStatus = .denied
            print("Screen Time authorization failed: \(error)")
        }
    }

    /// Check current authorization status
    private func checkAuthorizationStatus() async {
        switch AuthorizationCenter.shared.authorizationStatus {
        case .notDetermined:
            authorizationStatus = .notDetermined
        case .approved:
            authorizationStatus = .authorized
        case .denied:
            authorizationStatus = .denied
        @unknown default:
            authorizationStatus = .notDetermined
        }
    }
}
