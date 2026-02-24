//
//  AppContainer.swift
//  agile-self
//
//  Dependency injection container for services.
//  Injected into the SwiftUI environment via @Environment(AppContainer.self).
//

import Foundation
import SwiftData

/// Central container for all app services.
/// Lazily instantiates services on first access for performance.
@Observable
final class AppContainer {

    // MARK: - Model Container

    let modelContainer: ModelContainer

    // MARK: - Init

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    // MARK: - Services (Lazy)

    private var _healthKitService: HealthKitService?
    var healthKitService: HealthKitService {
        if let existing = _healthKitService { return existing }
        let service = HealthKitService()
        _healthKitService = service
        return service
    }

    private var _aiService: AIService?
    var aiService: AIService {
        if let existing = _aiService { return existing }
        let service = AIService()
        _aiService = service
        return service
    }

    private var _streakService: StreakService?
    var streakService: StreakService {
        if let existing = _streakService { return existing }
        let service = StreakService()
        _streakService = service
        return service
    }

    private var _subscriptionService: SubscriptionService?
    var subscriptionService: SubscriptionService {
        if let existing = _subscriptionService { return existing }
        let service = SubscriptionService()
        _subscriptionService = service
        return service
    }

    private var _notificationService: NotificationService?
    var notificationService: NotificationService {
        if let existing = _notificationService { return existing }
        let service = NotificationService()
        _notificationService = service
        return service
    }

    private var _analyticsService: AnalyticsService?
    var analyticsService: AnalyticsService {
        if let existing = _analyticsService { return existing }
        let service = AnalyticsService()
        _analyticsService = service
        return service
    }

    private var _screenTimeService: ScreenTimeService?
    var screenTimeService: ScreenTimeService {
        if let existing = _screenTimeService { return existing }
        let service = ScreenTimeService()
        _screenTimeService = service
        return service
    }

    private var _watchConnectivityService: WatchConnectivityService?
    var watchConnectivityService: WatchConnectivityService {
        if let existing = _watchConnectivityService { return existing }
        let service = WatchConnectivityService(modelContainer: modelContainer)
        _watchConnectivityService = service
        return service
    }
}
