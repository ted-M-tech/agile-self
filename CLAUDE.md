# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Build iOS app
xcodebuild -scheme agile-self -destination 'platform=iOS Simulator,name=iPhone 16' build

# Build watchOS app
xcodebuild -scheme "agile-self Watch App" -destination 'platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)' build

# Run unit tests (iOS)
xcodebuild test -scheme agile-self -destination 'platform=iOS Simulator,name=iPhone 16'

# Run a single test
xcodebuild test -scheme agile-self -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:agile-selfTests/agile_selfTests/testExample

# Run UI tests
xcodebuild test -scheme agile-self -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:agile-selfUITests

# Run watchOS tests
xcodebuild test -scheme "agile-self Watch App" -destination 'platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)'
```

Alternatively, open `agile-self.xcodeproj` in Xcode and use Cmd+B to build, Cmd+U to run tests.

## Project Overview

**Agile Self** is a native iOS/watchOS application for personal self-retrospection using the KPTA (Keep, Problem, Try, Action) framework, integrated with Apple Health data.

- Tagline: "Your AI Growth Partner"
- Motto: "Turn Reflection Into Action"
- Platform: iOS 17+ / watchOS 10+ (Native Apple only)

## Product Architecture

### Development Strategy

**iOS-Native App with Health Integration**:
- Native SwiftUI app for iPhone and Apple Watch
- KPTA framework for structured retrospectives
- Apple Health integration (sleep, activity, workouts)
- iCloud sync via CloudKit + SwiftData
- No external backend services required

### Tech Stack (Apple Native)

| Component | Technology |
|-----------|------------|
| **Language** | Swift 5.9+ |
| **UI Framework** | SwiftUI |
| **Data Layer** | SwiftData |
| **Cloud Sync** | CloudKit (automatic via SwiftData) |
| **Authentication** | Sign in with Apple |
| **Health Data** | HealthKit |
| **Screen Time** | DeviceActivity Framework (optional) |
| **Minimum iOS** | iOS 17.0 |
| **Minimum watchOS** | watchOS 10.0 |

### Why CloudKit + SwiftData?
- **Zero backend maintenance** - Apple manages infrastructure
- **Free** - Included with Apple Developer Program ($99/year)
- **Automatic iCloud sync** - One-line configuration in SwiftData
- **Offline-first** - Built-in offline support with automatic sync
- **Privacy** - Health data stays in Apple ecosystem
- **Native integration** - No third-party SDKs required

## Key Product Principles

### KPTA Framework Flow
1. **Keep**: What went well, what to continue
2. **Problem**: Obstacles and challenges faced
3. **Try**: New approaches to experiment with (based on Problems and Keeps)
4. **Action**: Specific, concrete to-dos derived from each Try

The critical differentiator is the Action step - converting reflection into concrete actionable items.

### Health Data Integration
- Sleep tracking (duration, quality, bedtime/wake time)
- Activity metrics (steps, calories, exercise minutes, stand hours)
- Workout summaries
- Correlate health data with retrospective periods
- Surface insights about health-productivity connections

### UI/UX Philosophy
- Native iOS design following Apple Human Interface Guidelines
- Clean, focused interface optimized for reflection
- watchOS companion for quick access
- Home screen widgets for at-a-glance stats
- Support both light and dark mode

## Project Structure (Current)

```
agile-self/
├── agile-self/                     # iOS app target
│   ├── agile_selfApp.swift         # App entry point
│   ├── ContentView.swift           # Root view
│   └── Assets.xcassets/            # App assets
├── agile-self Watch App/           # watchOS companion target
│   ├── agile_selfApp.swift         # Watch app entry
│   ├── ContentView.swift           # Watch root view
│   └── Assets.xcassets/            # Watch assets
├── agile-selfTests/                # iOS unit tests (Swift Testing)
├── agile-selfUITests/              # iOS UI tests (XCTest)
├── agile-self Watch AppTests/      # watchOS unit tests
├── agile-self Watch AppUITests/    # watchOS UI tests
└── agile-self.xcodeproj/           # Xcode project
```

### Planned Structure (to be implemented)

```
agile-self/
├── Models/                         # SwiftData models
│   ├── Retrospective.swift
│   ├── KPTAItem.swift
│   ├── ActionItem.swift
│   └── HealthSummary.swift
├── Views/
│   ├── Dashboard/                  # Main dashboard
│   ├── KPTA/                       # Retrospective entry
│   ├── Actions/                    # Action items list
│   ├── History/                    # Past retrospectives
│   ├── Health/                     # Health dashboard
│   └── Settings/                   # App settings
├── Services/
│   ├── HealthKit/                  # HealthKitManager
│   └── ScreenTime/                 # Optional
└── Utilities/
```

## SwiftData Models

### Core Models

```swift
@Model
final class Retrospective {
    @Attribute(.unique) var id: UUID
    var title: String
    var type: RetrospectiveType // weekly, monthly
    var startDate: Date
    var endDate: Date

    @Relationship(deleteRule: .cascade)
    var keeps: [KPTAItem]
    @Relationship(deleteRule: .cascade)
    var problems: [KPTAItem]
    @Relationship(deleteRule: .cascade)
    var tries: [KPTAItem]
    @Relationship(deleteRule: .cascade)
    var actions: [ActionItem]

    var healthSummary: HealthSummary?
    var createdAt: Date
    var updatedAt: Date
}

@Model
final class ActionItem {
    @Attribute(.unique) var id: UUID
    var text: String
    var isCompleted: Bool
    var deadline: Date?
    var fromTryItem: Bool
    var createdAt: Date
}

@Model
final class HealthSummary {
    var date: Date
    var sleepDurationMinutes: Int?
    var sleepQualityScore: Int?
    var stepCount: Int?
    var exerciseMinutes: Int?
    var wellnessScore: Int?
}
```

### CloudKit Configuration

```swift
@main
struct AgileSelfApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            Retrospective.self,
            KPTAItem.self,
            ActionItem.self,
            HealthSummary.self
        ]) // CloudKit sync enabled automatically
    }
}
```

## Development Guidelines

### When implementing SwiftUI views:
- Use native SwiftUI components (NavigationStack, TabView, List)
- Follow Apple Human Interface Guidelines
- Support Dynamic Type for accessibility
- Support both light and dark mode
- Use SF Symbols for icons
- Prefer @Environment and @Query for data access

### When implementing SwiftData:
- Use @Model macro for all persistent types
- Use @Relationship for model relationships
- Enable CloudKit sync via modelContainer configuration
- Handle migration with isAutomaticMigrationEnabled: true
- Use @Query in views for reactive data fetching

### When implementing HealthKit:
- Always check HKHealthStore.isHealthDataAvailable()
- Request only the data types you need
- Use read-only access (never write to Health)
- Handle authorization denial gracefully
- Use HKObserverQuery for background updates
- Store daily aggregates, not raw samples

### KPTA Color Scheme

| Element | Color | SwiftUI |
|---------|-------|---------|
| Keep | Green | .green |
| Problem | Red | .red |
| Try | Purple | .purple |
| Action | Blue | .blue |

### Code Patterns

```swift
// View with data query
struct DashboardView: View {
    @Query(sort: \Retrospective.createdAt, order: .reverse)
    private var retrospectives: [Retrospective]

    var body: some View {
        NavigationStack {
            List(retrospectives) { retro in
                RetroRow(retrospective: retro)
            }
            .navigationTitle("Dashboard")
        }
    }
}

// HealthKit query
func fetchSleepData(for date: Date) async throws -> [HKCategorySample] {
    let sleepType = HKCategoryType(.sleepAnalysis)
    let predicate = HKQuery.predicateForSamples(
        withStart: date.startOfDay,
        end: date.endOfDay,
        options: .strictStartDate
    )

    return try await withCheckedThrowingContinuation { continuation in
        let query = HKSampleQuery(
            sampleType: sleepType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ) { _, samples, error in
            if let error = error {
                continuation.resume(throwing: error)
            } else {
                continuation.resume(returning: samples as? [HKCategorySample] ?? [])
            }
        }
        healthStore.execute(query)
    }
}
```

## Xcode Capabilities

### Required for iOS:
- [x] iCloud → CloudKit
- [x] HealthKit
- [x] Background Modes → Background fetch
- [x] Sign in with Apple

### Required for watchOS:
- [x] HealthKit
- [x] Background Modes

### Optional:
- [ ] Family Controls (Screen Time - requires Apple approval)

## Privacy Requirements

### Info.plist Keys

```xml
<key>NSHealthShareUsageDescription</key>
<string>Agile Self uses your health data to provide insights about how your sleep and activity patterns relate to your personal growth journey.</string>

<key>NSHealthUpdateUsageDescription</key>
<string>Agile Self does not write any data to Apple Health.</string>
```

### App Privacy
- Health data stays on-device and in user's iCloud
- No third-party analytics or tracking
- User can disable iCloud sync
- Clear data deletion in Settings

## Testing

### Unit Tests
- Test SwiftData model logic
- Test HealthKit data aggregation
- Test date utilities

### UI Tests
- Test KPTA entry flow
- Test action completion
- Test navigation

## Notes

### Migration from Web App
This project previously had a Next.js web app. That code is archived and not maintained. Focus only on the iOS-native implementation.

### Future Considerations
- AI insights (on-device ML or Apple Intelligence)
- Share retrospectives
- Calendar integration
- Habit tracking
