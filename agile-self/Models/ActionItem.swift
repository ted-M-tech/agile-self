//
//  ActionItem.swift
//  agile-self
//
//  Created by Claude on 2025/11/30.
//

import Foundation
import SwiftData

@Model
final class ActionItem {
    @Attribute(.unique) var id: UUID
    var text: String
    var isCompleted: Bool
    var deadline: Date?
    var completedAt: Date?
    var fromTryItem: Bool
    var createdAt: Date

    var retrospective: Retrospective?

    init(
        id: UUID = UUID(),
        text: String,
        isCompleted: Bool = false,
        deadline: Date? = nil,
        completedAt: Date? = nil,
        fromTryItem: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.text = text
        self.isCompleted = isCompleted
        self.deadline = deadline
        self.completedAt = completedAt
        self.fromTryItem = fromTryItem
        self.createdAt = createdAt
    }

    var isOverdue: Bool {
        guard let deadline = deadline, !isCompleted else { return false }
        return deadline < Date()
    }

    func markCompleted() {
        isCompleted = true
        completedAt = Date()
    }

    func markIncomplete() {
        isCompleted = false
        completedAt = nil
    }
}
