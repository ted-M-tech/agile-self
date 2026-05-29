//
//  PaywallView.swift
//  agile-self
//
//  Premium subscription paywall with feature comparison and pricing.
//

import SwiftUI
import SwiftData
import StoreKit

// MARK: - Plan Type

enum PlanType: String, CaseIterable, Identifiable {
    case monthly
    case yearly

    var id: String { rawValue }
}

// MARK: - PaywallView

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppContainer.self) private var appContainer
    @State private var selectedPlan: PlanType = .yearly
    @State private var isPurchasing: Bool = false
    @State private var purchaseError: String?

    private var subscriptionService: SubscriptionService {
        appContainer.subscriptionService
    }

    /// Per-month equivalent of the yearly plan, derived from the real product price.
    /// Falls back to the JP-locale literal when the product hasn't loaded yet.
    private var yearlyMonthlyEquivalent: String {
        guard let yearly = subscriptionService.yearlyProduct else { return "\u{00A5}317/mo" }
        let perMonth = yearly.price / 12
        return perMonth.formatted(yearly.priceFormatStyle) + "/mo"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    headerSection
                    benefitsSection
                    pricingSection
                    subscribeButton
                    if let error = purchaseError {
                        Text(error)
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.error)
                            .multilineTextAlignment(.center)
                    }
                    restoreLink
                    legalFooter
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.xxl)
            }
            .background(Theme.Colors.backgroundPrimary.ignoresSafeArea())
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                    .accessibilityLabel("Close")
                }
            }
            .task {
                await subscriptionService.loadProducts()
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            Spacer()
                .frame(height: Theme.Spacing.md)

            // Crown icon with gradient
            Image(systemName: "crown.fill")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Theme.Colors.accentStart, Theme.Colors.accentEnd],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .accessibilityHidden(true)

            Text("Become a Supporter")
                .font(Theme.Typography.display)
                .gradientText()

            Text("Every feature is already yours. Premium keeps Agile Self growing.")
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, Theme.Spacing.sm)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Become a Supporter. Every feature is already yours. Premium keeps Agile Self growing.")
    }

    // MARK: - Benefits

    private var benefitsSection: some View {
        VStack(spacing: 0) {
            ForEach(Array(benefitRows.enumerated()), id: \.offset) { index, benefit in
                benefitRow(benefit)

                if index < benefitRows.count - 1 {
                    Divider()
                        .overlay(Theme.Colors.divider)
                        .padding(.leading, Theme.Spacing.md + 28 + Theme.Spacing.md)
                }
            }
        }
        .background(Theme.Colors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
    }

    private func benefitRow(_ benefit: BenefitRowData) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: benefit.icon)
                .font(.callout)
                .foregroundStyle(Theme.Colors.accentEnd)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(benefit.title)
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text(benefit.detail)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(benefit.title). \(benefit.detail)")
    }

    // MARK: - Pricing Section

    private var pricingSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.md) {
                // Monthly card
                pricingCard(
                    plan: .monthly,
                    title: "Monthly",
                    price: subscriptionService.monthlyProduct?.displayPrice ?? "\u{00A5}480",
                    period: "/month",
                    badge: nil
                )

                // Yearly card
                pricingCard(
                    plan: .yearly,
                    title: "Yearly",
                    price: subscriptionService.yearlyProduct?.displayPrice ?? "\u{00A5}3,800",
                    period: "/year",
                    badge: "34% OFF"
                )
            }
        }
    }

    private func pricingCard(
        plan: PlanType,
        title: String,
        price: String,
        period: String,
        badge: String?
    ) -> some View {
        let isSelected = selectedPlan == plan

        return Button {
            withAnimation(Theme.Animation.smooth) {
                selectedPlan = plan
            }
        } label: {
            VStack(spacing: Theme.Spacing.sm) {
                // Badge
                if let badge {
                    Text(badge)
                        .font(Theme.Typography.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Theme.Spacing.sm)
                        .padding(.vertical, Theme.Spacing.xs)
                        .background(Theme.Colors.accentGradient)
                        .clipShape(Capsule())
                } else {
                    Spacer()
                        .frame(height: 22)
                }

                Text(title)
                    .font(Theme.Typography.subhead)
                    .foregroundStyle(
                        isSelected
                            ? Theme.Colors.textPrimary
                            : Theme.Colors.textSecondary
                    )

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(price)
                        .font(Theme.Typography.title2)
                        .foregroundStyle(
                            isSelected
                                ? Theme.Colors.textPrimary
                                : Theme.Colors.textSecondary
                        )

                    Text(period)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textTertiary)
                }

                if plan == .yearly {
                    Text(yearlyMonthlyEquivalent)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textTertiary)
                } else {
                    Spacer()
                        .frame(height: 14)
                }

                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(
                        isSelected
                            ? Theme.Colors.accentStart
                            : Theme.Colors.textTertiary
                    )
                    .contentTransition(.symbolEffect(.replace))
            }
            .padding(Theme.Spacing.md)
            .frame(maxWidth: .infinity)
            .background(
                isSelected
                    ? Theme.Colors.backgroundTertiary
                    : Theme.Colors.backgroundSecondary
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                    .stroke(
                        isSelected
                            ? Theme.Colors.accentStart
                            : Color.clear,
                        lineWidth: 2
                    )
            )
            .shadow(
                color: isSelected ? Theme.Colors.accentStart.opacity(0.2) : .clear,
                radius: 12,
                y: 4
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) plan, \(price) \(period)")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityHint("Double tap to select this plan")
    }

    // MARK: - Subscribe Button

    private var subscribeButton: some View {
        Button {
            Task {
                isPurchasing = true
                purchaseError = nil
                let product: Product? = selectedPlan == .yearly
                    ? subscriptionService.yearlyProduct
                    : subscriptionService.monthlyProduct
                guard let product else {
                    purchaseError = "Product not available. Please try again later."
                    isPurchasing = false
                    return
                }
                do {
                    let transaction = try await subscriptionService.purchase(product)
                    if transaction != nil {
                        dismiss()
                    }
                } catch {
                    purchaseError = "Purchase failed. Please try again."
                }
                isPurchasing = false
            }
        } label: {
            Group {
                if isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Subscribe Now")
                }
            }
            .primaryButtonStyle()
        }
        .disabled(isPurchasing)
        .opacity(isPurchasing ? 0.7 : 1.0)
        .accessibilityLabel("Subscribe to \(selectedPlan == .yearly ? "yearly" : "monthly") plan")
        .accessibilityHint("Begins the purchase process")
    }

    // MARK: - Restore Link

    private var restoreLink: some View {
        Button {
            Task {
                await subscriptionService.restorePurchases()
                if subscriptionService.isPremium {
                    dismiss()
                }
            }
        } label: {
            Text("Restore Purchases")
                .ghostButtonStyle()
        }
        .accessibilityLabel("Restore previous purchases")
    }

    // MARK: - Legal Footer

    private var legalFooter: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text("Payment will be charged to your Apple ID account at confirmation of purchase. Subscription automatically renews unless it is canceled at least 24 hours before the end of the current period. Your account will be charged for renewal within 24 hours prior to the end of the current period.")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textTertiary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)

            HStack(spacing: Theme.Spacing.md) {
                Link("Terms of Service", destination: URL(string: "https://agileself.app/terms")!)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)

                Text("\u{2022}")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textTertiary)

                Link("Privacy Policy", destination: URL(string: "https://agileself.app/privacy")!)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            .accessibilityElement(children: .contain)
        }
        .padding(.top, Theme.Spacing.sm)
    }
}

// MARK: - Benefit Data

private struct BenefitRowData {
    let icon: String
    let title: String
    let detail: String
}

// Honest framing: nothing is locked. Every feature ships to everyone today; Premium is an
// optional supporter tier that funds development and is where future premium-only
// capabilities will live. Do NOT advertise limits that the app does not enforce.
private let benefitRows: [BenefitRowData] = [
    BenefitRowData(
        icon: "checkmark.seal.fill",
        title: "Everything, included",
        detail: "Check-ins, health insights, connections, reports, charts, and widgets — all of it."
    ),
    BenefitRowData(
        icon: "heart.fill",
        title: "Support an indie developer",
        detail: "Agile Self is built by one person. Your subscription keeps the lights on."
    ),
    BenefitRowData(
        icon: "sparkles",
        title: "Early access to new features",
        detail: "Help shape what comes next and try new capabilities first."
    ),
]

// MARK: - Preview

#Preview {
    PaywallView()
        .modelContainer(MockData.previewContainer)
        .environment(AppContainer(modelContainer: MockData.previewContainer))
        .preferredColorScheme(.dark)
}
