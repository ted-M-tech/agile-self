# Agile Self - Your AI Growth Partner

**Turn Reflection Into Action**

A native iOS/watchOS application for personal self-retrospection using the KPTA (Keep, Problem, Try, Action) framework, integrated with Apple Health data.

![Version](https://img.shields.io/badge/version-3.0.0-blue)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange)
![iOS](https://img.shields.io/badge/iOS-17+-blue)
![watchOS](https://img.shields.io/badge/watchOS-10+-green)

## Features

### Core KPTA Framework
- **Keep**: Document what went well and what to continue
- **Problem**: Identify obstacles and challenges faced
- **Try**: Experiment with new approaches based on insights
- **Action**: Convert reflections into concrete, actionable tasks

### Apple Health Integration
- **Sleep Tracking**: Duration, quality score, bedtime/wake patterns
- **Activity Metrics**: Steps, calories, exercise minutes, stand hours
- **Workout Summaries**: Exercise sessions and types
- **Health Context**: Correlate health data with retrospective periods

### iCloud Sync
- **Automatic Sync**: Data syncs across all your Apple devices
- **Offline-First**: Works without internet, syncs when connected
- **Privacy**: Your data stays in your iCloud account

### Apple Watch Companion
- Quick access to recent retrospectives
- Action item completion on the go
- Complications for at-a-glance stats

## Tech Stack

| Component | Technology |
|-----------|------------|
| **Language** | Swift 5.9+ |
| **UI** | SwiftUI |
| **Data** | SwiftData + CloudKit |
| **Health** | HealthKit |
| **Widgets** | WidgetKit |

## Getting Started

### Requirements
- iOS 17.0 or later
- watchOS 10.0 or later (for Apple Watch app)
- Xcode 15.0 or later
- Apple Developer account (for CloudKit)

### Setup

1. **Clone the repository**
```bash
git clone <your-repo-url>
cd agile-self-your-ai-growth-partner
```

2. **Open in Xcode**
```bash
open AgileSelf.xcodeproj
```

3. **Configure Signing**
- Select your development team in Xcode
- Update bundle identifier if needed

4. **Enable Capabilities** (in Xcode)
- iCloud → CloudKit
- HealthKit
- Background Modes
- Sign in with Apple

5. **Run on device or simulator**

## Project Structure

```
AgileSelf/
├── AgileSelf/                      # iOS App
│   ├── App/
│   │   ├── AgileSelfApp.swift      # App entry point
│   │   └── ContentView.swift       # Root navigation
│   ├── Models/                     # SwiftData models
│   │   ├── Retrospective.swift
│   │   ├── KPTAItem.swift
│   │   ├── ActionItem.swift
│   │   └── HealthSummary.swift
│   ├── Views/
│   │   ├── Dashboard/              # Home tab
│   │   ├── KPTA/                   # New retrospective
│   │   ├── Actions/                # Action items
│   │   ├── History/                # Past retrospectives
│   │   ├── Health/                 # Health dashboard
│   │   └── Settings/               # App settings
│   ├── Services/
│   │   ├── HealthKit/              # Health data queries
│   │   └── ScreenTime/             # Optional
│   └── Utilities/
├── AgileSelfWatch/                 # watchOS App
├── AgileSelfWidgets/               # Home screen widgets
├── AgileSelfTests/                 # Unit tests
└── AgileSelfUITests/               # UI tests
```

## Application Flow

### 1. Dashboard
- Wellbeing score overview
- Recent retrospectives
- Health metrics summary
- Quick action stats

### 2. New Retrospective
- Select type (Weekly/Monthly)
- Enter Keep items (what went well)
- Enter Problem items (challenges)
- Enter Try items (experiments)
- Convert Tries to Actions with deadlines

### 3. Actions
- View all action items
- Filter: All / Pending / Completed
- Mark actions complete
- Track overdue items

### 4. History
- Browse past retrospectives
- Search by content
- View health context for each period

### 5. Health
- Sleep trends chart
- Activity metrics
- Correlations with retrospectives

### 6. Settings
- Health permissions
- Notifications/reminders
- Data export
- Account management

## KPTA Framework Guide

### Keep 🟢
"What went well this week?"
- Positive habits maintained
- Achievements and wins
- Effective strategies

### Problem 🔴
"What obstacles did I face?"
- Challenges and frustrations
- Things that didn't work
- Patterns to change

### Try 🟣
"What experiments should I try?"
- New approaches to test
- Ways to sustain Keeps
- Solutions for Problems

### Action 🔵
"What specific steps will I take?"
- Convert vague ideas to concrete tasks
- Add deadlines for accountability
- Track completion

## Privacy

- **Health data stays on-device and in your iCloud**
- No external servers or third-party analytics
- Read-only access to Apple Health (we never write)
- You control your data - delete anytime in Settings

## Development

### Architecture
- **MVVM** with SwiftUI
- **SwiftData** for persistence
- **CloudKit** for sync (automatic via SwiftData)
- **Combine** for reactive updates

### Build
```bash
# Open project
open AgileSelf.xcodeproj

# Build for device
xcodebuild -scheme AgileSelf -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### Test
```bash
# Run unit tests
xcodebuild test -scheme AgileSelf -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

## Documentation

- [CLAUDE.md](./CLAUDE.md) - Development guidelines for AI assistants
- [Plan](/.claude/plans/) - Implementation plans

## Roadmap

### v3.0 (Current)
- [x] Core KPTA functionality
- [x] SwiftData + CloudKit sync
- [x] HealthKit integration
- [ ] watchOS companion
- [ ] Home screen widgets

### Future
- [ ] AI insights (on-device ML)
- [ ] Share retrospectives
- [ ] Calendar integration
- [ ] Habit tracking

## License

MIT License

---

**Made with ❤️ for personal growth**

*"Turn Reflection Into Action"*
