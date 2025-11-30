//
//  KPTACategory.swift
//  agile-self
//
//  Created by Claude on 2025/11/30.
//

import Foundation
import SwiftUI

enum KPTACategory: String, Codable, CaseIterable {
    case keep
    case problem
    case `try`

    var displayName: String {
        switch self {
        case .keep: return "Keep"
        case .problem: return "Problem"
        case .try: return "Try"
        }
    }

    var color: Color {
        switch self {
        case .keep: return .green
        case .problem: return .red
        case .try: return .purple
        }
    }

    var iconName: String {
        switch self {
        case .keep: return "checkmark.circle.fill"
        case .problem: return "exclamationmark.triangle.fill"
        case .try: return "lightbulb.fill"
        }
    }
}
