# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

## Build Commands

```bash
# Build iOS app
xcodebuild -scheme agile-self -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run unit tests (iOS)
xcodebuild test -scheme agile-self -destination 'platform=iOS Simulator,name=iPhone 16'

# Run UI tests
xcodebuild test -scheme agile-self -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:agile-selfUITests
```

Alternatively, open `agile-self.xcodeproj` in Xcode and use Cmd+B to build, Cmd+U to run tests.

## Project Overview

**Agile Self** is a native iOS application for personal self-retrospection with AI-powered growth insights, integrated with Apple Health and Screen Time data.

- Tagline: "Your AI Growth Partner"
- Motto: "Turn Reflection Into Action"
- Platform: iOS 26.1+ (watchOS 26.1+ for the Watch app)
- Full specification: See SPEC.md

## Tech Stack

| Component | Technology |
|-----------|------------|
| Language | Swift 5.0 (SWIFT_APPROACHABLE_CONCURRENCY = YES) |
| UI | SwiftUI (iOS 26.1+) |
| Data | SwiftData (CloudKit deferred to M6; `cloudKitDatabase = .none`) |
| Health | HealthKit (free-account ✅) |
| Screen Time | DeviceActivity / FamilyControls (deferred — paid/uncertain) |
| Charts | Swift Charts |
| AI (on-device) | Foundation Models (iOS 26) + NaturalLanguage |
| AI (cloud) | Gemini API (deferred — behind `allowCloudAI`) |
| Subscription | StoreKit 2 (local `Subscriptions.storekit` config) |
| Widget | WidgetKit (App Group `group.tetsuya.agile-self`) |
| Min iOS | **26.1** |

## Project Structure

```
agile-self/
├── agile_selfApp.swift              # App entry point (RootView + ModelContainer)
├── Models/
│   ├── DailyCheckIn.swift           # 4-axis daily scoring (1-10)
│   ├── HealthSnapshot.swift         # Daily health metrics from HealthKit
│   ├── WeeklyReview.swift           # AI conversation review + ConversationMessage
│   ├── MonthlyReport.swift          # Auto-generated report + Correlation
│   ├── ActionItemV2.swift           # Action items + ActionSource enum
│   ├── ActionPriority.swift         # Priority enum (high/medium/low)
│   ├── UserProfile.swift            # User settings + SubscriptionTier
│   └── Streak.swift                 # Check-in streak tracking
├── Views/
│   ├── Root/
│   │   ├── RootView.swift           # Onboarding gate → MainTabView
│   │   └── MainTabView.swift        # 3-tab: Home / Insights / Profile
│   ├── Home/
│   │   ├── HomeView.swift           # Dashboard (greeting, trend, dimensions, health)
│   │   ├── ScoreTrendChart.swift    # 7-day composite score (Swift Charts)
│   │   ├── DimensionCard.swift      # Circular ring progress card
│   │   ├── AIInsightCard.swift      # AI-generated insight display
│   │   └── HealthMetricCard.swift   # Health data compact card
│   ├── CheckIn/
│   │   ├── DailyCheckInView.swift   # Full-screen 4-axis scoring entry
│   │   ├── ScoreDimensionPicker.swift # Horizontal 1-10 picker
│   │   └── CheckInConfirmationView.swift # Animated confirmation overlay
│   ├── Insights/
│   │   ├── InsightsView.swift       # Trends, correlations, patterns, streaks
│   │   ├── CorrelationCard.swift    # Health-score correlation display
│   │   └── PatternCard.swift        # AI-discovered pattern card
│   ├── Profile/
│   │   ├── ProfileView.swift        # User info, actions, settings (+ add/delete, sheets)
│   │   ├── ActionRow.swift          # Reusable action item row
│   │   └── AddActionView.swift      # New-action modal (M2/D5)
│   ├── WeeklyReview/                # WeeklyReviewIntroView, WeeklyConversationView, WeeklySummaryView
│   ├── MonthlyReport/               # MonthlyReportView, HeatmapCalendarView
│   ├── Onboarding/                  # OnboardingContainerView (permissions + gate)
│   ├── Settings/                    # SettingsView (export / delete-all)
│   └── Subscription/                # PaywallView
├── ViewModels/                      # @Observable VMs: Home, Insights, Profile, MonthlyReport, CheckIn
├── Services/                        # AppContainer (DI); AI/ (AIServiceRouter, OnDeviceAIService,
│   │                                #   FoundationModelsAIService + AIGenerableDTOs — M3, GeminiAIService);
│   │                                #   Analytics, HealthKit, Notifications, ScreenTime, Streak, Subscription,
│   │                                #   WatchConnectivity, DataManagement (DataManagementService/ExportedDataFile — M2)
├── Widget/                          # WidgetSnapshot + WidgetSnapshotWriter (M4 app-side → App Group)
└── Utilities/
    ├── Theme.swift                  # Design system (colors, typography, spacing)
    ├── MockData.swift               # Preview-only mock data (#Preview blocks only)
    └── ShareContentBuilder.swift    # Plain-text share content (M2/D6)

AgileSelfWidget/                     # WidgetKit extension (M4) — App Group group.tetsuya.agile-self
agile-self Watch App/                # watchOS companion (WCSession check-in sync)
ScreenTimeReport/                    # DeviceActivity extension (excluded from build — see M0)
├── ScreenTimeReport.swift
├── TotalActivityReport.swift
└── TotalActivityView.swift
Subscriptions.storekit               # Local StoreKit test config (M2/D7)
```

## Core Framework: Daily / Weekly / Monthly Hybrid

| Layer | Frequency | Time | Method |
|-------|-----------|------|--------|
| Daily | Every day | 15 sec | 4-axis scorecard (Energy/Focus/Stress/Growth, 1-10) |
| Weekly | Once/week | 3-5 min | AI conversation review (Gemini API) |
| Monthly | Auto | Auto | AI-generated report with trends & correlations |

### 4 Dimensions
| Dimension | Color | Score |
|-----------|-------|-------|
| Energy | Gold (#FDCB6E) | 1-10 |
| Focus | Sky Blue (#74B9FF) | 1-10 |
| Stress | Coral (#FF6B6B) | 1-10 (low=good, inverted for composite) |
| Growth | Mint (#55EFC4) | 1-10 |

### Navigation (3 Tabs)
- **Home** - Dashboard with score trends, dimension cards, AI insights, health data
- **Insights** - Trend charts, correlations, AI patterns, streak stats
- **Profile** - User info, action items, settings

## Design System (Theme.swift)

### Colors
- Background: Primary (#0A0A0F), Secondary (#13131A), Tertiary (#1C1C26)
- Accent gradient: #6C5CE7 → #A29BFE (purple)
- Text: Primary (#F0F0F5), Secondary (#8888A0), Tertiary (#55556A)
- Semantic: Success (#00B894), Warning (#E17055), Error (#FF6B6B)

### Typography
- Display/Titles: SF Pro Rounded (bold/semibold)
- Body/UI: SF Pro Text (regular)
- Scores: Rounded monospaced variants

### Key View Modifiers
- `.cardStyle()` - Secondary background card
- `.elevatedCardStyle()` - Tertiary background card
- `.primaryButtonStyle()` - Accent gradient CTA
- `.secondaryButtonStyle()` - Outline button
- `.pillStyle(color:)` - Small tag/badge
- `.colorBorderCard(_:)` - Card with colored left border
- `.gradientText()` - Accent gradient text overlay

## Development Guidelines

### SwiftUI
- Use NavigationStack, not NavigationView
- Dark mode only (preferredColorScheme(.dark))
- Use Theme.* constants for all colors, typography, spacing
- Support Dynamic Type
- Use SF Symbols for all icons
- All views must have #Preview blocks with MockData

### SwiftData
- Use @Model for persistent types
- Do NOT nest types inside @Model classes
- Use Data? + computed properties for JSON-encoded arrays
- Simple [String] arrays work directly

### Architecture
- Unidirectional: Views → ViewModels → Services → SwiftData
- AppContainer for dependency injection (replacing singletons)
- DimensionType enum defined in Theme.swift (shared across models/views)

### Concurrency
- Swift 5 language mode with `SWIFT_APPROACHABLE_CONCURRENCY = YES` **and `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`** (both set on the app + Watch App targets, Debug & Release — verified in `project.pbxproj`). So unannotated types/members are **`@MainActor`-isolated by default**; mark a declaration `nonisolated` to opt out. (The pbxproj is the source of truth; a doc claiming "nonisolated by default" is stale/wrong.)
- `@MainActor` closures stored in `@Observable` classes must be `@ObservationIgnored` (the macro can't synthesize a tracked accessor for a global-actor closure type).
- SourceKit single-file diagnostics ("cannot find type X" for cross-file symbols, or actor-isolation/await warnings) are frequently FALSE POSITIVES — `xcodebuild` is the source of truth.

### Build / Toolchain
- All Xcode CLI commands must be prefixed with `DEVELOPER_DIR=/Users/tetsuya/Downloads/Xcode.app/Contents/Developer` unless global `xcode-select` points at full Xcode.
- New source files auto-compile via `PBXFileSystemSynchronizedRootGroup` — do NOT hand-edit `project.pbxproj` to register files (double-registration corrupts the sync group). Adding a new *target* still requires Xcode GUI.
- Views that use `.modelContainer(...)` in a `#Preview` need `import SwiftData`.

### Privacy
- Local-first data storage
- Cloud AI data is anonymized before sending
- User consent required for cloud AI (allowCloudAI flag)

## Xcode Capabilities Required

### iOS Target (agile-self)
- HealthKit (free-account ✅)
- App Groups `group.tetsuya.agile-self` (free-account ✅ — widget + screen-time data sharing)
- iCloud (CloudKit) — **deferred to M6** (paid program; `cloudKitDatabase = .none` for now)
- Family Controls / Push Notifications — **deferred** (paid/uncertain on free account)

### AgileSelfWidgetExtension
- App Groups `group.tetsuya.agile-self`

### ScreenTimeReport Extension
- Family Controls (currently excluded from the build — see M0)

## Testing

- Unit tests in `agile-selfTests/`
- UI tests in `agile-selfUITests/`
- Use MockData.previewContainer for in-memory SwiftData previews
