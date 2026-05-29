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

    private var _onDeviceAIService: OnDeviceAIService?
    /// Shared on-device service instance. Owns NaturalLanguage-backed helpers
    /// (e.g. `analyzeSentiment`) that are not part of `AIServiceProtocol`, and is
    /// also the on-device backend the router routes to. Kept as a single instance
    /// so callers never construct a fresh `OnDeviceAIService()` inline.
    private var onDeviceAIService: OnDeviceAIService {
        if let existing = _onDeviceAIService { return existing }
        let service = OnDeviceAIService()
        _onDeviceAIService = service
        return service
    }

    private var _aiService: (any AIServiceProtocol)?
    /// The unified AI service. Backed by `AIServiceRouter`, which composes the
    /// on-device service (instant, local) and the Gemini cloud service, routing
    /// by the user's `allowCloudAI` preference.
    var aiService: any AIServiceProtocol {
        if let existing = _aiService { return existing }
        let router = AIServiceRouter(
            onDeviceService: onDeviceAIService,
            geminiService: GeminiAIService(),
            foundationModelsService: FoundationModelsAIService()
        )
        _aiService = router
        return router
    }

    /// Analyzes the sentiment of free text (-1.0…1.0) via the shared on-device
    /// service. Exposed here so the check-in save path routes through DI instead of
    /// constructing a throwaway `OnDeviceAIService()`.
    func analyzeSentiment(_ text: String) -> Double {
        onDeviceAIService.analyzeSentiment(text)
    }

    /// Refreshes the router's cloud-AI preference from the persisted UserProfile.
    /// Call at launch and whenever the user toggles cloud AI in Settings.
    func refreshCloudAIPreference(context: ModelContext) {
        (aiService as? AIServiceRouter)?.updateCloudAIPreference(from: context)
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
        // Sync UserProfile.subscriptionTier whenever entitlements change. Safe no-op
        // when no profile exists yet (fresh install / post-wipe) — do NOT create one here.
        let container = modelContainer
        service.onEntitlementsChanged = { isPremium in
            let context = container.mainContext
            guard let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first else { return }
            let newTier: SubscriptionTier = isPremium ? .premium : .free
            if profile.subscriptionTier != newTier {
                profile.subscriptionTier = newTier
                try? context.save()
            }
        }
        _subscriptionService = service
        return service
    }

    /// Loads StoreKit products and refreshes entitlements, syncing the persisted
    /// `UserProfile.subscriptionTier`. Call at launch.
    func refreshSubscriptionState() async {
        await subscriptionService.loadProducts()
        await subscriptionService.updatePurchasedProducts()
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

    private var _dataManagementService: DataManagementService?
    var dataManagementService: DataManagementService {
        if let existing = _dataManagementService { return existing }
        let service = DataManagementService()
        _dataManagementService = service
        return service
    }
}
