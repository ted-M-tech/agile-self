# CLAUDE.md — Agile Self iOS App

## Build & Test

```bash
# Build iOS
xcodebuild -scheme agile-self -destination 'platform=iOS Simulator,name=iPhone 16' build
# Unit tests
xcodebuild test -scheme agile-self -destination 'platform=iOS Simulator,name=iPhone 16'
# Watch app
xcodebuild -scheme "agile-self Watch App" -destination 'platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)' build
```

## Do NOT

- Nest types inside `@Model` classes (SwiftData runtime crash)
- Use `ObservableObject` / `@Published` — use `@Observable`
- Use `NavigationView` — use `NavigationStack`
- Use `DispatchQueue` — use Swift Concurrency (`async/await`, `.task {}`)
- Use `Task {}` in `onAppear` — use `.task {}` modifier
- Use force unwrapping (`!`) in production code
- Use `@unchecked Sendable` — fix the actual isolation issue
- Use `exit(0)` — Apple rejects this
- Edit `.pbxproj` files — add files via Xcode manually
- Store raw HealthKit data in iCloud
- Pass `@Model` objects across actor boundaries — pass `PersistentIdentifier`

## Project Structure

```
agile-self/
├── agile_selfApp.swift                    # Entry point, ModelContainer
├── Models/                                # SwiftData @Model classes (7 files)
│   ├── DailyCheckIn.swift                 # 4-axis scoring + compositeScore
│   ├── HealthSnapshot.swift               # Health metrics + sleepScore
│   ├── WeeklyReview.swift                 # AI conversation (JSON-encoded messages)
│   ├── MonthlyReport.swift                # Trends + correlations (JSON-encoded)
│   ├── ActionItemV2.swift                 # Actions + ActionPriority + ActionSource enums
│   ├── UserProfile.swift                  # Settings + SubscriptionTier enum
│   └── Streak.swift                       # Streak tracking
├── ViewModels/                            # @Observable view models (4 files)
│   ├── HomeViewModel.swift
│   ├── CheckInViewModel.swift
│   ├── InsightsViewModel.swift
│   └── ProfileViewModel.swift
├── Views/
│   ├── Root/                              # RootView (onboarding gate) + MainTabView (3 tabs)
│   ├── Home/                              # HomeView, ScoreTrendChart, DimensionCard, AIInsightCard, HealthMetricCard
│   ├── CheckIn/                           # DailyCheckInView, ScoreDimensionPicker, CheckInConfirmationView
│   ├── Insights/                          # InsightsView, CorrelationCard, PatternCard
│   ├── MonthlyReport/                     # MonthlyReportView, HeatmapCalendarView
│   ├── WeeklyReview/                      # WeeklyReviewIntroView, WeeklyConversationView, WeeklySummaryView, QuickResponseChip
│   ├── Onboarding/                        # OnboardingContainerView
│   ├── Profile/                           # ProfileView, ActionRow
│   ├── Settings/                          # SettingsView
│   └── Subscription/                      # PaywallView
├── Services/
│   ├── AppContainer.swift                 # DI container (lazy service init)
│   ├── AI/                                # AIServiceProtocol, AIServiceRouter, OnDeviceAIService, GeminiAIService, AIService (legacy)
│   ├── Analytics/                         # AnalyticsService (Pearson correlation, trends)
│   ├── HealthKit/                         # HealthKitService (6 data types)
│   ├── Notifications/                     # NotificationService
│   ├── ScreenTime/                        # ScreenTimeService (FamilyControls)
│   ├── Streak/                            # StreakService
│   ├── Subscription/                      # SubscriptionService (StoreKit 2)
│   └── WatchConnectivity/                 # WatchConnectivityService
└── Utilities/
    ├── Theme.swift                        # Design system + DimensionType enum
    └── MockData.swift                     # Preview data

agile-self Watch App/                      # watchOS companion (5 files)
├── WatchCheckInView.swift, WatchConnectivityManager.swift, WatchTheme.swift
ScreenTimeReport/                          # DeviceActivity extension (3 files)
agile-selfTests/                           # Swift Testing framework (2 files)
```

## Code Conventions

### ViewModel Pattern
```swift
@Observable final class XViewModel {
    var isLoading = false
    var errorMessage: String?
    private var healthService: HealthKitService?

    func configure(container: AppContainer) { self.healthService = container.healthService }
    func loadData(context: ModelContext) { /* sync fetch with FetchDescriptor */ }
    func loadAsync(context: ModelContext) async { /* async work */ }
}
// In view: @State private var viewModel = XViewModel()
// In .task { viewModel.configure(container: appContainer); viewModel.loadData(context: modelContext) }
```

### Service Pattern
- `@Observable` only when service has view-observable state (e.g., `isAuthorized`)
- Otherwise plain `final class` (e.g., `StreakService`, `AnalyticsService`)
- All services injected via `AppContainer`, accessed through `@Environment`
- Protocol-based for testability: `AIServiceProtocol`

### SwiftData Rules
- All `@Model` properties must be optional or have defaults (CloudKit compat)
- Supporting types (enums, structs) defined outside `@Model` class, in same file
- Use `Data?` + computed property for JSON-encoded arrays
- `@Attribute(.unique)` on `id: UUID` for all models
- Use `@Relationship(deleteRule: .cascade)` for parent-child links
- Test with `ModelConfiguration(isStoredInMemoryOnly: true)`

### Error Handling Policy
- `do/catch` with `errorMessage` state for primary data loads (user sees error)
- `try?` only for non-critical auxiliary data (health metrics, AI insights)
- Never silently swallow errors on core data operations

### Concurrency
- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` (all code is MainActor by default)
- Mark `nonisolated` on methods that don't touch `@Observable` state
- Use `.task {}` in views, never `Task {}` in `onAppear`
- Use `async let` for parallel independent fetches

### Naming
- Models: `DailyCheckIn`, `HealthSnapshot` (noun, PascalCase)
- ViewModels: `HomeViewModel`, `CheckInViewModel` (ScreenName + ViewModel)
- Services: `HealthKitService`, `AnalyticsService` (Framework + Service)
- Views: `HomeView`, `DailyCheckInView` (descriptive + View)

## Design System (Theme.swift)

### Colors
- Background: `#0A0A0F` / `#13131A` / `#1C1C26` | Accent: `#6C5CE7 → #A29BFE`
- Dimensions: Energy `#FDCB6E` | Focus `#74B9FF` | Stress `#FF6B6B` | Growth `#55EFC4`

### View Modifiers
`.cardStyle()` `.elevatedCardStyle()` `.primaryButtonStyle()` `.secondaryButtonStyle()` `.ghostButtonStyle()` `.pillStyle(color:)` `.colorBorderCard(_:)` `.dimensionBorderCard(_:)` `.gradientText()`

### Rules
- Dark mode only (`preferredColorScheme(.dark)`)
- Use `Theme.*` constants for all colors, typography, spacing
- Use SF Symbols for all icons
- All views must have `#Preview` blocks with `MockData.previewContainer`
- Views over 200 lines should be decomposed into subviews
- Support Dynamic Type — use semantic font sizes, not fixed `Font.system(size:)`
- Support VoiceOver — meaningful `accessibilityLabel` on all interactive elements
- Respect `accessibilityReduceMotion`

## Testing
- Use **Swift Testing** framework (`@Test`, `#expect`, `#require`), not XCTest
- In-memory container: `ModelConfiguration(isStoredInMemoryOnly: true)`
- Parameterized tests for score/dimension validation
- Unit tests in `agile-selfTests/`, UI tests in `agile-selfUITests/`

## Current MVP Status (2026-04)
- Phase: MVP (TestFlight target: May 2026)
- Gemini API: deferred (on-device AI only)
- CloudKit: `.none` for MVP
- Screen Time: deferred (HealthKit only)
- Full spec: See SPEC.md
- Issues: See GitHub Issues (ted-M-tech/agile-self)
