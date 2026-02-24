//
//  WatchTheme.swift
//  agile-self Watch App
//
//  Design system for the Watch app, mirroring the iOS Theme.
//

import SwiftUI

// MARK: - WatchTheme

enum WatchTheme {

    // MARK: - Colors

    enum Colors {
        static let backgroundPrimary = Color(hex: 0x0A0A0F)
        static let backgroundSecondary = Color(hex: 0x13131A)
        static let backgroundTertiary = Color(hex: 0x1C1C26)

        static let accentStart = Color(hex: 0x6C5CE7)
        static let accentEnd = Color(hex: 0xA29BFE)

        static var accentGradient: LinearGradient {
            LinearGradient(
                colors: [accentStart, accentEnd],
                startPoint: .leading,
                endPoint: .trailing
            )
        }

        static let textPrimary = Color(hex: 0xF0F0F5)
        static let textSecondary = Color(hex: 0x8888A0)
        static let textTertiary = Color(hex: 0x55556A)

        static let success = Color(hex: 0x00B894)
    }

    // MARK: - Dimension Colors

    enum Dimension {
        static let energy = Color(hex: 0xFDCB6E)
        static let focus = Color(hex: 0x74B9FF)
        static let stress = Color(hex: 0xFF6B6B)
        static let growth = Color(hex: 0x55EFC4)

        static func color(for type: WatchDimensionType) -> Color {
            switch type {
            case .energy: return energy
            case .focus: return focus
            case .stress: return stress
            case .growth: return growth
            }
        }
    }
}

// MARK: - WatchDimensionType

enum WatchDimensionType: String, CaseIterable, Codable, Identifiable {
    case energy
    case focus
    case stress
    case growth

    var id: String { rawValue }

    var label: String {
        switch self {
        case .energy: return "Energy"
        case .focus: return "Focus"
        case .stress: return "Stress"
        case .growth: return "Growth"
        }
    }

    var icon: String {
        switch self {
        case .energy: return "bolt.fill"
        case .focus: return "eye.fill"
        case .stress: return "waveform.path.ecg"
        case .growth: return "leaf.fill"
        }
    }
}

// MARK: - Color(hex:)

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
