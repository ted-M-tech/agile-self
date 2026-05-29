---
description: Rules for SwiftUI view files
globs:
  - "agile-self/Views/**/*.swift"
---

# SwiftUI View Rules

- Every view file MUST have a `#Preview` block using `MockData.previewContainer`
- Views over 200 lines MUST be decomposed into extracted subviews
- Use `Theme.*` constants for ALL colors, typography, spacing — never hardcode values
- Use `.task {}` for async work — never `Task {}` in `onAppear`
- Use `@State private var viewModel = XViewModel()` pattern for view-owned state
- Configure ViewModel in `.task { viewModel.configure(...); viewModel.loadData(...) }`
- Use `@Bindable var viewModel` when you need `$binding` syntax
- Dark mode only: `preferredColorScheme(.dark)`
- All interactive elements need `accessibilityLabel`
- Respect `accessibilityReduceMotion` for animations
- Use `NavigationStack`, never `NavigationView`
- Use SF Symbols for all icons
