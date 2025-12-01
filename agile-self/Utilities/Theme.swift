//
//  Theme.swift
//  agile-self
//
//  Created by Claude on 2025/11/30.
//

import SwiftUI

enum Theme {
    // MARK: - KPTA Colors

    enum KPTA {
        static let keep = Color.green
        static let problem = Color.red
        static let `try` = Color.purple
        static let action = Color.blue

        static let keepBackground = Color.green.opacity(0.1)
        static let problemBackground = Color.red.opacity(0.1)
        static let tryBackground = Color.purple.opacity(0.1)
        static let actionBackground = Color.blue.opacity(0.1)

        static func color(for category: KPTACategory) -> Color {
            switch category {
            case .keep: return keep
            case .problem: return problem
            case .try: return `try`
            }
        }

        static func backgroundColor(for category: KPTACategory) -> Color {
            switch category {
            case .keep: return keepBackground
            case .problem: return problemBackground
            case .try: return tryBackground
            }
        }
    }

    // MARK: - Semantic Colors

    enum Semantic {
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let info = Color.blue

        static let overdue = Color.red
        static let pending = Color.orange
        static let completed = Color.green
    }

    // MARK: - Wellbeing Score Colors

    enum Wellbeing {
        static func color(for score: Int) -> Color {
            switch score {
            case 70...100: return .green
            case 50..<70: return .orange
            default: return .red
            }
        }

        static func label(for score: Int) -> String {
            switch score {
            case 80...100: return "Excellent"
            case 70..<80: return "Good"
            case 50..<70: return "Fair"
            case 30..<50: return "Needs Attention"
            default: return "Low"
            }
        }
    }

    // MARK: - Typography

    enum Typography {
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title = Font.title.weight(.semibold)
        static let title2 = Font.title2.weight(.semibold)
        static let title3 = Font.title3.weight(.medium)
        static let headline = Font.headline
        static let body = Font.body
        static let callout = Font.callout
        static let caption = Font.caption
    }

    // MARK: - Spacing

    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Corner Radius

    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 24
    }
}

// MARK: - Animation

extension Theme {
    enum Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.15)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.25)
        static let smooth = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.8)
        static let bouncy = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.6)
    }
}

// MARK: - Shadows

extension Theme {
    enum Shadow {
        static func small(_ colorScheme: ColorScheme) -> some View {
            Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08)
        }

        static func medium(_ colorScheme: ColorScheme) -> some View {
            Color.black.opacity(colorScheme == .dark ? 0.4 : 0.12)
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Apply KPTA card styling with category-specific background
    func kptaCardStyle(category: KPTACategory) -> some View {
        self
            .padding(Theme.Spacing.md)
            .background(Theme.KPTA.backgroundColor(for: category))
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .stroke(Theme.KPTA.color(for: category).opacity(0.3), lineWidth: 1)
            )
    }

    /// Apply standard card styling with material background
    func cardStyle() -> some View {
        self
            .padding(Theme.Spacing.md)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
    }

    /// Apply elevated card styling with shadow
    func elevatedCardStyle() -> some View {
        self
            .padding(Theme.Spacing.md)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    /// Apply action button styling
    func actionButtonStyle(color: Color = Theme.KPTA.action) -> some View {
        self
            .font(Theme.Typography.callout.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.sm)
            .background(color)
            .clipShape(Capsule())
    }

    /// Apply secondary button styling
    func secondaryButtonStyle(color: Color = Theme.KPTA.action) -> some View {
        self
            .font(Theme.Typography.callout.weight(.medium))
            .foregroundStyle(color)
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.xs)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }
}
