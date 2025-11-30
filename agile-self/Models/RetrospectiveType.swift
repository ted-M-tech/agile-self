//
//  RetrospectiveType.swift
//  agile-self
//
//  Created by Claude on 2025/11/30.
//

import Foundation

enum RetrospectiveType: String, Codable, CaseIterable {
    case weekly
    case monthly

    var displayName: String {
        switch self {
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        }
    }
}
