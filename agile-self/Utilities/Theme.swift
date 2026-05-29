//
//  Theme.swift
//  agile-self
//
//  Premium Dark Design System
//

import SwiftUI

// MARK: - Theme

enum Theme {

    // MARK: - Colors

    enum Colors {
        // Backgrounds
        static let backgroundPrimary = Color(hex: 0x0A0A0F)
        static let backgroundSecondary = Color(hex: 0x13131A)
        static let backgroundTertiary = Color(hex: 0x1C1C26)

        // Accent
        static let accentStart = Color(hex: 0x6C5CE7)
        static let accentEnd = Color(hex: 0xA29BFE)

        static var accentGradient: LinearGradient {
            LinearGradient(
                colors: [accentStart, accentEnd],
                startPoint: .leading,
                endPoint: .trailing
            )
        }

        // Text
        static let textPrimary = Color(hex: 0xF0F0F5)
        static let textSecondary = Color(hex: 0x8888A0)
        static let textTertiary = Color(hex: 0x55556A)

        // Divider
        static let divider = Color.white.opacity(0.04)

        // Semantic
        static let success = Color(hex: 0x00B894)
        static let warning = Color(hex: 0xE17055)
        static let error = Color(hex: 0xFF6B6B)

        // Health Metric colors
        static let sleep = Color(hex: 0x6C5CE7)
        static let steps = Color(hex: 0xE17055)
        static let heartRate = Color(hex: 0xFF6B6B)
        static let screenTime = Color(hex: 0x00CEC9)
        static let running = Color(hex: 0x00B894)
    }

    // MARK: - Dimension Colors (4-axis scoring)

    enum Dimension {
        static let energy = Color(hex: 0xFDCB6E)
        static let focus = Color(hex: 0x74B9FF)
        static let stress = Color(hex: 0xFF6B6B)
        static let growth = Color(hex: 0x55EFC4)

        static let energyBackground = Color(hex: 0xFDCB6E).opacity(0.15)
        static let focusBackground = Color(hex: 0x74B9FF).opacity(0.15)
        static let stressBackground = Color(hex: 0xFF6B6B).opacity(0.15)
        static let growthBackground = Color(hex: 0x55EFC4).opacity(0.15)

        static func color(for type: DimensionType) -> Color {
            switch type {
            case .energy: return energy
            case .focus: return focus
            case .stress: return stress
            case .growth: return growth
            }
        }

        static func background(for type: DimensionType) -> Color {
            switch type {
            case .energy: return energyBackground
            case .focus: return focusBackground
            case .stress: return stressBackground
            case .growth: return growthBackground
            }
        }
    }

    // MARK: - Typography (SF Pro Rounded + SF Pro Text)

    enum Typography {
        // Dynamic Type-scalable: text-style-based system fonts scale with the
        // user's preferred content size. Each text style's default size matches
        // the previous fixed sizes closely, so default-setting layout is preserved.
        static let display = Font.system(.largeTitle, design: .rounded).weight(.bold)
        static let title1 = Font.system(.title, design: .rounded).weight(.semibold)
        static let title2 = Font.system(.title2, design: .rounded).weight(.semibold)
        static let title3 = Font.system(.title3, design: .rounded).weight(.medium)
        static let headline = Font.system(.headline, design: .default).weight(.semibold)
        static let body = Font.system(.body, design: .default)
        static let callout = Font.system(.callout, design: .default)
        static let subhead = Font.system(.subheadline, design: .default)
        static let footnote = Font.system(.footnote, design: .default)
        static let caption = Font.system(.caption, design: .default)

        // Score numerals: intentionally fixed-size (rounded). These hero numbers
        // live in circular rings / gauges (DimensionCard, InsightsView) that would
        // distort or clip if the numerals scaled to accessibility sizes. Keep them
        // fixed for layout integrity; surrounding labels above use scalable styles.
        static let scoreDisplay = Font.system(size: 48, weight: .bold, design: .rounded)
        static let scoreLarge = Font.system(size: 34, weight: .bold, design: .rounded)
        static let scoreMedium = Font.system(size: 24, weight: .bold, design: .rounded)
        static let scoreSmall = Font.system(size: 17, weight: .semibold, design: .rounded)
    }

    // MARK: - Spacing

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
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
        static let xl: CGFloat = 20
        static let pill: CGFloat = 999
    }

    // MARK: - Animations

    enum Animation {
        // Micro interactions
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.15)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.25)

        // Springs
        static let smooth = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.8)
        static let bouncy = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.6)
        static let scoreSelection = SwiftUI.Animation.spring(response: 0.15, dampingFraction: 0.7)

        // Chart / Ring animations
        static let trendLineDraw = SwiftUI.Animation.easeOut(duration: 1.2)
        static let ringFill = SwiftUI.Animation.spring(response: 0.8, dampingFraction: 0.75)

        // Stagger helpers
        static func stagger(index: Int, base: Double = 0.05) -> SwiftUI.Animation {
            SwiftUI.Animation.easeOut(duration: 0.5).delay(Double(index) * base)
        }

        static func springStagger(index: Int, base: Double = 0.1) -> SwiftUI.Animation {
            SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.7)
                .delay(Double(index) * base)
        }

        // Chat / AI
        static let chatMessage = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.8)
        static let typewriterDot = SwiftUI.Animation.easeInOut(duration: 0.5).repeatForever()

        // CTA pulse
        static let ctaPulse = SwiftUI.Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)

        // Confirmation
        static let checkmarkDraw = SwiftUI.Animation.easeOut(duration: 0.6)
    }
}

// MARK: - Dimension Type Enum

enum DimensionType: String, CaseIterable, Codable, Identifiable {
    case energy
    case focus
    case stress
    case growth

    var id: String { rawValue }

    // NOTE: the `.stress` case and rawValue "stress" are kept for data continuity. Its
    // presentation is now Calm (high = better); higher always means better for all axes.
    var label: String {
        switch self {
        case .energy: return "Energy"
        case .focus: return "Focus"
        case .stress: return "Calm"
        case .growth: return "Growth"
        }
    }

    var localizedLabel: LocalizedStringKey {
        switch self {
        case .energy: return "Energy"
        case .focus: return "Focus"
        case .stress: return "Calm"
        case .growth: return "Growth"
        }
    }

    var icon: String {
        switch self {
        case .energy: return "sun.max.fill"
        case .focus: return "scope"
        case .stress: return "wind"
        case .growth: return "leaf.fill"
        }
    }

    var question: LocalizedStringKey {
        switch self {
        case .energy: return "How's your energy today?"
        case .focus: return "How focused were you?"
        case .stress: return "How calm did you feel?"
        case .growth: return "Did you grow today?"
        }
    }
}

// MARK: - Color Extension (Hex Init)

extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: opacity
        )
    }
}

// MARK: - View Modifiers

extension View {
    /// Standard card style with secondary background
    func cardStyle() -> some View {
        self
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
    }

    /// Elevated card style with tertiary background
    func elevatedCardStyle() -> some View {
        self
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.backgroundTertiary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
    }

    /// Card with dimension-colored left border
    func dimensionBorderCard(_ type: DimensionType) -> some View {
        self
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .fill(Theme.Dimension.color(for: type))
                    .frame(width: 3)
            }
    }

    /// Card with custom color left border
    func colorBorderCard(_ color: Color) -> some View {
        self
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .fill(color)
                    .frame(width: 3)
            }
    }

    /// Primary CTA button style (accent gradient)
    func primaryButtonStyle() -> some View {
        self
            .font(Theme.Typography.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)
            .background(Theme.Colors.accentGradient)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
    }

    /// Secondary button style (outline)
    func secondaryButtonStyle() -> some View {
        self
            .font(Theme.Typography.headline)
            .foregroundStyle(Theme.Colors.accentStart)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)
            .background(Theme.Colors.backgroundTertiary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .stroke(Theme.Colors.accentStart.opacity(0.3), lineWidth: 1)
            )
    }

    /// Ghost/text button style
    func ghostButtonStyle() -> some View {
        self
            .font(Theme.Typography.callout)
            .foregroundStyle(Theme.Colors.textSecondary)
    }

    /// Pill tag style
    func pillStyle(color: Color) -> some View {
        self
            .font(Theme.Typography.caption)
            .foregroundStyle(color)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }
}

// MARK: - Gradient Text Modifier

struct GradientText: ViewModifier {
    func body(content: Content) -> some View {
        content
            .overlay {
                Theme.Colors.accentGradient
                    .mask(content)
            }
    }
}

extension View {
    func gradientText() -> some View {
        modifier(GradientText())
    }
}
