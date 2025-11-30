//
//  KPTAItem.swift
//  agile-self
//
//  Created by Claude on 2025/11/30.
//

import Foundation
import SwiftData

@Model
final class KPTAItem {
    @Attribute(.unique) var id: UUID
    var text: String
    var category: KPTACategory
    var orderIndex: Int
    var createdAt: Date

    var retrospective: Retrospective?

    init(
        id: UUID = UUID(),
        text: String,
        category: KPTACategory,
        orderIndex: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.text = text
        self.category = category
        self.orderIndex = orderIndex
        self.createdAt = createdAt
    }

    // MARK: - Validation

    /// Returns true if the item has valid content
    var isValid: Bool {
        !trimmedText.isEmpty
    }

    /// Returns the text with leading/trailing whitespace removed
    var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Updates the text with validated content
    func updateText(_ newText: String) {
        text = newText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
