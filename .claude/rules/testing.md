---
description: Rules for test files
globs:
  - "agile-selfTests/**/*.swift"
  - "agile-selfUITests/**/*.swift"
---

# Testing Rules

- Use **Swift Testing** framework (`import Testing`), NOT XCTest for new tests
- Use `@Test("description")` — not `func testXxx()`
- Use `#expect(condition)` — not `XCTAssertEqual`
- Use `#require(value)` for preconditions that should abort the test
- Use `@Suite("name")` to group related tests
- Always use in-memory container: `ModelConfiguration(isStoredInMemoryOnly: true)`
- Use parameterized tests for score/dimension validation:
  ```swift
  @Test("scores", arguments: [(1, true), (0, false), (11, false)])
  func scoreValidation(score: Int, valid: Bool) { ... }
  ```
- Tests run in parallel by default — use `.serialized` trait when tests share state
- Keep XCTest only for UI tests (Swift Testing doesn't support them yet)
