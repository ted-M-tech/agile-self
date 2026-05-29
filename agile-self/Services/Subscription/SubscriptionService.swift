//
//  SubscriptionService.swift
//  agile-self
//
//  StoreKit 2 subscription management for premium features.
//

import Foundation
import StoreKit

@Observable
final class SubscriptionService {

    // MARK: - Product IDs

    static let monthlyProductID = "com.agileSelf.premium.monthly"
    static let yearlyProductID = "com.agileSelf.premium.yearly"

    // MARK: - State

    var products: [Product] = []
    var purchasedProductIDs: Set<String> = []
    var isLoading = false
    var errorMessage: String?

    /// Invoked after entitlements are refreshed, with the current premium status.
    /// Installed by `AppContainer` to keep `UserProfile.subscriptionTier` in sync.
    /// `@ObservationIgnored`: it's a callback sink (not observable UI state), and the
    /// `@Observable` macro can't synthesize a tracked accessor for a `@MainActor` closure type.
    @ObservationIgnored var onEntitlementsChanged: (@MainActor (Bool) -> Void)?

    var isPremium: Bool {
        !purchasedProductIDs.isEmpty
    }

    var monthlyProduct: Product? {
        products.first { $0.id == Self.monthlyProductID }
    }

    var yearlyProduct: Product? {
        products.first { $0.id == Self.yearlyProductID }
    }

    private var updateListenerTask: Task<Void, Error>?

    // MARK: - Init / Deinit

    init() {
        updateListenerTask = listenForTransactions()
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Load Products

    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        do {
            products = try await Product.products(for: [
                Self.monthlyProductID,
                Self.yearlyProductID
            ])
        } catch {
            errorMessage = "Failed to load products."
        }
        isLoading = false
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws -> StoreKit.Transaction? {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updatePurchasedProducts()
            await transaction.finish()
            return transaction
        case .userCancelled:
            return nil
        case .pending:
            return nil
        @unknown default:
            return nil
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        try? await AppStore.sync()
        await updatePurchasedProducts()
    }

    // MARK: - Check Current Entitlements

    func updatePurchasedProducts() async {
        var purchased: Set<String> = []
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                purchased.insert(transaction.productID)
            }
        }
        purchasedProductIDs = purchased
        onEntitlementsChanged?(!purchased.isEmpty)
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                if let transaction = try? self.checkVerified(result) {
                    await self.updatePurchasedProducts()
                    await transaction.finish()
                }
            }
        }
    }

    nonisolated private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let value):
            return value
        }
    }

    enum StoreError: Error {
        case failedVerification
    }
}
