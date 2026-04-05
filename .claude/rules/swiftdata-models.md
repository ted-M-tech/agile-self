---
description: Rules for SwiftData model files
globs:
  - "agile-self/Models/**/*.swift"
---

# SwiftData Model Rules

- NEVER nest types (enums, structs) inside `@Model` classes — define them at top level in the same file
- All properties MUST be optional or have default values (required for CloudKit compatibility)
- Use `@Attribute(.unique)` on `var id: UUID = UUID()`
- Use `Data?` + computed property for JSON-encoded complex arrays
- Simple `[String]` arrays work directly
- Supporting enums must conform to `String, Codable`
- Use `@Relationship(deleteRule: .cascade)` for parent-child relationships
- Validate ranges in `init()` (e.g., scores clamped to 1-10)
- `compositeScore` and other derived values should be computed properties on the model, not duplicated in ViewModels
- Import only `Foundation` + `SwiftData` — never `SwiftUI` (put color mappings in Theme.swift)
