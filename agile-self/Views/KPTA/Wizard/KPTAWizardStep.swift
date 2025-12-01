//
//  KPTAWizardStep.swift
//  agile-self
//
//  Created by Claude on 2025/12/01.
//

import SwiftUI

/// Represents each step in the KPTA wizard flow
enum KPTAWizardStep: Int, CaseIterable, Identifiable {
    case setup = 0
    case keep = 1
    case problem = 2
    case tryStep = 3
    case review = 4

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .setup: return "When"
        case .keep: return "Keep"
        case .problem: return "Problem"
        case .tryStep: return "Try"
        case .review: return "Review"
        }
    }

    var subtitle: String {
        switch self {
        case .setup: return "What period are you reflecting on?"
        case .keep: return "What went well?"
        case .problem: return "What was challenging?"
        case .tryStep: return "What will you try next?"
        case .review: return "Review and save"
        }
    }

    var iconName: String {
        switch self {
        case .setup: return "calendar"
        case .keep: return "checkmark.circle"
        case .problem: return "exclamationmark.triangle"
        case .tryStep: return "lightbulb"
        case .review: return "list.clipboard"
        }
    }

    var color: Color {
        switch self {
        case .setup: return Theme.KPTA.action
        case .keep: return Theme.KPTA.keep
        case .problem: return Theme.KPTA.problem
        case .tryStep: return Theme.KPTA.`try`
        case .review: return Theme.KPTA.action
        }
    }

    var category: KPTACategory? {
        switch self {
        case .keep: return .keep
        case .problem: return .problem
        case .tryStep: return .try
        default: return nil
        }
    }

    var next: KPTAWizardStep? {
        KPTAWizardStep(rawValue: rawValue + 1)
    }

    var previous: KPTAWizardStep? {
        KPTAWizardStep(rawValue: rawValue - 1)
    }

    var isFirst: Bool { self == .setup }
    var isLast: Bool { self == .review }
}
