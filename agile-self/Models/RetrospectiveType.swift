//
//  RetrospectiveType.swift
//  agile-self
//
//  Created by Claude on 2025/11/30.
//

import Foundation

enum RetrospectiveType: String, Codable, CaseIterable {
    case daily
    case weekly
    case monthly

    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        }
    }

    var iconName: String {
        switch self {
        case .daily: return "sun.max"
        case .weekly: return "calendar.badge.clock"
        case .monthly: return "calendar"
        }
    }
}
