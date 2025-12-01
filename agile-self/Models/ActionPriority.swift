//
//  ActionPriority.swift
//  agile-self
//
//  Created by Claude on 2025/11/30.
//

import Foundation
import SwiftUI

/// Priority levels for action items
/// Codable for SwiftData persistence and CloudKit sync
enum ActionPriority: String, Codable, CaseIterable, Sendable {
    case high
    case medium
    case low

    // MARK: - Display Properties

    var displayName: String {
        switch self {
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        }
    }

    var iconName: String {
        switch self {
        case .high: return "exclamationmark.3"
        case .medium: return "exclamationmark.2"
        case .low: return "exclamationmark"
        }
    }

    var color: Color {
        switch self {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }

    // MARK: - Sorting

    /// Sort order value (lower = higher priority)
    var sortOrder: Int {
        switch self {
        case .high: return 0
        case .medium: return 1
        case .low: return 2
        }
    }
}

// MARK: - Comparable

extension ActionPriority: Comparable {
    static func < (lhs: ActionPriority, rhs: ActionPriority) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}
