//
//  ErrorStateView.swift
//  agile-self
//
//  Shared full-screen error state — a single, consistent "something went wrong" view with an
//  optional retry, replacing the near-identical copies that lived in Insights / Profile /
//  Monthly. Keeps copy, layout, and accessibility uniform across screens.
//

import SwiftUI

struct ErrorStateView: View {
    var title: String = "Something went wrong"
    let message: String
    /// When provided, shows a "Try Again" button that runs this action.
    var retry: (() -> Void)?

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            Spacer(minLength: Theme.Spacing.xxl)

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(Theme.Colors.warning)
                .accessibilityHidden(true)

            Text(title)
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Colors.textPrimary)

            Text(message)
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Theme.Spacing.xl)

            if let retry {
                Button(action: retry) {
                    Text("Try Again")
                        .secondaryButtonStyle()
                }
                .padding(.horizontal, Theme.Spacing.xl)
                .padding(.top, Theme.Spacing.sm)
            }

            Spacer(minLength: Theme.Spacing.xxl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message)")
    }
}

#Preview {
    ZStack {
        Theme.Colors.backgroundPrimary.ignoresSafeArea()
        ErrorStateView(message: "Unable to load your data. Please try restarting the app.", retry: {})
    }
    .preferredColorScheme(.dark)
}
