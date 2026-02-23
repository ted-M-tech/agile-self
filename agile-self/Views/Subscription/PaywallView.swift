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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    headerSection
                    featureComparisonSection
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

            Text("Unlock Premium")
                .font(Theme.Typography.display)
                .gradientText()

            Text("Get the most out of your growth journey")
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, Theme.Spacing.sm)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Unlock Premium. Get the most out of your growth journey.")
    }

    // MARK: - Feature Comparison

    private var featureComparisonSection: some View {
        VStack(spacing: 0) {
            // Column headers
            HStack {
                Text("Features")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Spacer()

                Text("Free")
                    .font(Theme.Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.Colors.textTertiary)
                    .frame(width: 64)

                Text("Premium")
                    .font(Theme.Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.Colors.accentEnd)
                    .frame(width: 80)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.md)

            Divider()
                .overlay(Theme.Colors.divider)

            // Feature rows
            ForEach(Array(featureRows.enumerated()), id: \.offset) { index, feature in
                featureRow(
                    name: feature.name,
                    icon: feature.icon,
                    freeValue: feature.freeValue,
                    premiumValue: feature.premiumValue
                )

                if index < featureRows.count - 1 {
                    Divider()
                        .overlay(Theme.Colors.divider)
                        .padding(.leading, Theme.Spacing.md + 24 + Theme.Spacing.sm)
                }
            }
        }
        .background(Theme.Colors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
    }

    private func featureRow(
        name: String,
        icon: String,
        freeValue: FeatureValue,
        premiumValue: FeatureValue
    ) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
                .frame(width: 24, height: 24)

            Text(name)
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Colors.textPrimary)
                .lineLimit(1)

            Spacer()

            featureValueView(freeValue, isPremium: false)
                .frame(width: 64)

            featureValueView(premiumValue, isPremium: true)
                .frame(width: 80)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm + 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name). Free: \(freeValue.accessibilityText). Premium: \(premiumValue.accessibilityText)")
    }

    @ViewBuilder
    private func featureValueView(_ value: FeatureValue, isPremium: Bool) -> some View {
        switch value {
        case .check:
            Image(systemName: "checkmark")
                .font(.caption.weight(.bold))
                .foregroundStyle(isPremium ? Theme.Colors.accentEnd : Theme.Colors.success)

        case .limited(let text):
            Text(text)
                .font(Theme.Typography.caption)
                .foregroundStyle(isPremium ? Theme.Colors.accentEnd : Theme.Colors.textTertiary)

        case .unavailable:
            Text("\u{2014}")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textTertiary.opacity(0.5))
        }
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
                    Text("\u{00A5}317/mo")
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

// MARK: - Feature Data

private enum FeatureValue {
    case check
    case limited(String)
    case unavailable

    var accessibilityText: String {
        switch self {
        case .check: return "Available"
        case .limited(let text): return text
        case .unavailable: return "Not available"
        }
    }
}

private struct FeatureRowData {
    let name: String
    let icon: String
    let freeValue: FeatureValue
    let premiumValue: FeatureValue
}

private let featureRows: [FeatureRowData] = [
    FeatureRowData(name: "Daily Check-in", icon: "checkmark.circle", freeValue: .check, premiumValue: .check),
    FeatureRowData(name: "Health Data", icon: "heart.fill", freeValue: .check, premiumValue: .check),
    FeatureRowData(name: "AI Daily Insight", icon: "sparkles", freeValue: .check, premiumValue: .check),
    FeatureRowData(name: "Weekly AI Review", icon: "bubble.left.and.text.bubble.right", freeValue: .limited("2/month"), premiumValue: .check),
    FeatureRowData(name: "Monthly Report", icon: "doc.text.fill", freeValue: .limited("Summary"), premiumValue: .check),
    FeatureRowData(name: "Trend Charts", icon: "chart.xyaxis.line", freeValue: .limited("7 days"), premiumValue: .check),
    FeatureRowData(name: "Correlations", icon: "arrow.triangle.branch", freeValue: .unavailable, premiumValue: .check),
    FeatureRowData(name: "Actions", icon: "checklist", freeValue: .limited("3 max"), premiumValue: .check),
    FeatureRowData(name: "Widgets", icon: "rectangle.on.rectangle", freeValue: .limited("Small"), premiumValue: .check),
    FeatureRowData(name: "Export", icon: "square.and.arrow.up", freeValue: .unavailable, premiumValue: .check),
]

// MARK: - Preview

#Preview {
    PaywallView()
        .modelContainer(MockData.previewContainer)
        .environment(AppContainer(modelContainer: MockData.previewContainer))
        .preferredColorScheme(.dark)
}
