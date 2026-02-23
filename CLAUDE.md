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
- Platform: iOS 18.1+
- Full specification: See SPEC.md

## Tech Stack

| Component | Technology |
|-----------|------------|
| Language | Swift 6.0+ |
| UI | SwiftUI (iOS 18.1+) |
| Data | SwiftData + CloudKit |
| Health | HealthKit |
| Screen Time | DeviceActivity / FamilyControls |
| Charts | Swift Charts |
| AI (on-device) | NaturalLanguage + Foundation Models |
| AI (cloud) | Gemini 2.0 Flash API |
| Subscription | StoreKit 2 |
| Widget | WidgetKit |
| Min iOS | **18.1** |

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
│   └── Profile/
│       ├── ProfileView.swift        # User info, actions, settings
│       └── ActionRow.swift          # Reusable action item row
└── Utilities/
    ├── Theme.swift                  # Design system (colors, typography, spacing)
    └── MockData.swift               # Preview mock data

ScreenTimeReport/                    # App Extension
├── ScreenTimeReport.swift
├── TotalActivityReport.swift
└── TotalActivityView.swift
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
- Project uses SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor
- Mark nonisolated properties that don't need MainActor

### Privacy
- Local-first data storage
- Cloud AI data is anonymized before sending
- User consent required for cloud AI (allowCloudAI flag)

## Xcode Capabilities Required

### iOS Target (agile-self)
- HealthKit
- iCloud (CloudKit)
- Family Controls
- Push Notifications
- App Groups

### ScreenTimeReport Extension
- Family Controls

## Testing

- Unit tests in `agile-selfTests/`
- UI tests in `agile-selfUITests/`
- Use MockData.previewContainer for in-memory SwiftData previews
