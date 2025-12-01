# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

## Build Commands

```bash
# Build iOS app
xcodebuild -scheme agile-self -destination 'platform=iOS Simulator,name=iPhone 16' build

# Build watchOS app
xcodebuild -scheme "agile-self Watch App" -destination 'platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)' build

# Run unit tests (iOS)
xcodebuild test -scheme agile-self -destination 'platform=iOS Simulator,name=iPhone 16'

# Run UI tests
xcodebuild test -scheme agile-self -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:agile-selfUITests
```

Alternatively, open `agile-self.xcodeproj` in Xcode and use Cmd+B to build, Cmd+U to run tests.

## Project Overview

**Agile Self** is a native iOS/watchOS application for personal self-retrospection using the KPTA (Keep, Problem, Try, Action) framework, integrated with Apple Health data.

- Tagline: "Your AI Growth Partner"
- Motto: "Turn Reflection Into Action"
- Platform: iOS 17+ / watchOS 10+

## Tech Stack

| Component | Technology |
|-----------|------------|
| Language | Swift 5.9+ |
| UI Framework | SwiftUI |
| Data Layer | SwiftData |
| Cloud Sync | CloudKit (via SwiftData) |
| Health Data | HealthKit |
| Minimum iOS | iOS 17.0 |

## Project Structure

```
agile-self/
├── agile_selfApp.swift              # App entry point
├── Models/
│   ├── Retrospective.swift          # Main retrospective model
│   ├── KPTAItem.swift               # Keep/Problem/Try items
│   ├── KPTACategory.swift           # K/P/T enum
│   ├── ActionItem.swift             # Action items with priority
│   ├── ActionPriority.swift         # Priority enum
│   ├── RetrospectiveType.swift      # Daily/Weekly/Monthly
│   └── HealthSummary.swift          # Health data summary
├── Views/
│   ├── MainTabView.swift            # 3-tab navigation
│   ├── Home/
│   │   └── HomeView.swift           # Dashboard with health data
│   ├── Actions/
│   │   ├── ActionsListView.swift    # Action list with filters
│   │   ├── ActionRowView.swift
│   │   ├── ActionDetailView.swift
│   │   ├── AddActionView.swift
│   │   └── ActionsSummaryWidget.swift
│   ├── History/
│   │   ├── HistoryView.swift        # Past retrospectives
│   │   └── RetrospectiveDetailView.swift
│   ├── KPTA/
│   │   ├── KPTAEntryViewModel.swift
│   │   └── Wizard/                  # Step-by-step entry
│   │       ├── KPTAWizardView.swift
│   │       ├── KPTAWizardStep.swift
│   │       ├── KPTASetupStepView.swift
│   │       ├── KPTAInputStepView.swift
│   │       ├── KPTAReviewStepView.swift
│   │       ├── KPTAItemInputRow.swift
│   │       └── KPTAWizardProgressBar.swift
│   └── Settings/
│       └── SettingsView.swift
├── Services/
│   ├── HealthKit/
│   │   └── HealthKitManager.swift   # Health data fetching
│   └── Actions/
│       ├── ActionService.swift
│       └── ActionFilter.swift
└── Utilities/
    └── Theme.swift                  # Colors, spacing, typography
```

## Key Concepts

### KPTA Framework
1. **Keep** - What went well, continue doing
2. **Problem** - Challenges and obstacles
3. **Try** - New approaches to experiment with
4. **Action** - Concrete tasks derived from Tries (auto-created from each Try)

### Navigation (3 Tabs)
- **Home** - Dashboard with health data, stats, recent activity
- **Actions** - Manage action items with filtering
- **History** - Past retrospectives

Settings opens as a sheet from the Home screen navigation bar.

### Retrospective Types
- Daily
- Weekly
- Monthly

### Color Scheme (Theme.KPTA)
| Element | Color |
|---------|-------|
| Keep | Green |
| Problem | Red |
| Try | Purple |
| Action | Blue |

## Development Guidelines

### SwiftUI
- Use NavigationStack, not NavigationView
- Use @Query for SwiftData fetching
- Follow Apple Human Interface Guidelines
- Support Dynamic Type and dark mode
- Use SF Symbols for icons

### SwiftData
- Use @Model for persistent types
- Use @Relationship with deleteRule: .cascade
- Insert parent before appending children

### HealthKit
- Check HKHealthStore.isHealthDataAvailable() first
- Read-only access (never write)
- Handle authorization denial gracefully
- Use @MainActor for HealthKitManager

### Concurrency
- Project uses SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor
- Mark nonisolated properties that don't need MainActor
- Use @State for @Observable objects in views

## Code Patterns

```swift
// SwiftData query in view
@Query(sort: \Retrospective.createdAt, order: .reverse)
private var retrospectives: [Retrospective]

// HealthKit with @Observable
@MainActor
@Observable
final class HealthKitManager {
    static let shared = HealthKitManager()
    private nonisolated let healthStore: HKHealthStore?
    // ...
}

// Using in SwiftUI
@State private var healthManager = HealthKitManager.shared
```

## Xcode Capabilities Required

### iOS Target
- HealthKit
- iCloud (CloudKit)

### Info.plist Keys (via Build Settings)
- NSHealthShareUsageDescription
- NSHealthUpdateUsageDescription

## Testing

- Unit tests in `agile-selfTests/`
- UI tests in `agile-selfUITests/`
- Use in-memory ModelConfiguration for previews
