# Agile Self

## Turn Reflection Into Action

Agile Self is a native iOS app for personal growth through structured reflection, powered by your health and activity data.

---

## Overview

Agile Self combines the KPT reflection framework with quantitative insights from Apple Health and Screen Time. By connecting how you feel with measurable data, you gain deeper self-awareness and make meaningful progress.

### Core Principles

- **Reflection-First** — Weekly and monthly retrospectives using KPT
- **Data-Informed** — Health, activity, and screen time context
- **Privacy-Native** — All data stays on-device and in your iCloud
- **Minimal by Design** — Simple interface, focused experience

---

## KPT Framework

The KPT framework structures reflection into three clear categories.

### Keep

What went well. What you want to continue.

- Positive habits maintained
- Achievements and wins
- Effective strategies that worked

### Problem

What challenged you. What got in the way.

- Obstacles and frustrations
- Patterns that didn't serve you
- Things that need attention

### Try

What you'll experiment with next.

- New approaches to test
- Solutions to problems identified
- Ways to build on your keeps

---

## Quantitative Context

Agile Self enriches your reflections with objective data from three sources.

### Health Data

From Apple HealthKit:

| Metric | Description |
|--------|-------------|
| Sleep Duration | Average hours per night |
| Sleep Quality | Derived from sleep stages |
| Steps | Daily step count average |
| Active Calories | Energy burned through activity |
| Exercise Minutes | Workout duration |
| Stand Hours | Hours with movement |
| Workouts | Session count by type |

### Screen Time

From DeviceActivity Framework:

| Metric | Description |
|--------|-------------|
| Total Screen Time | Daily average usage |
| Pickups | How often you check your device |
| Notifications | Interruption frequency |
| App Categories | Where time is spent |

### Wellness Score

A unified 0-100 score calculated from:

- Sleep quality and consistency
- Physical activity levels
- Screen time balance
- Weekly trends and changes

---

## Information Architecture

### Tab Structure

```
┌─────────────────────────────────────────┐
│                                         │
│              Dashboard                  │
│         Wellness at a glance            │
│                                         │
├─────────┬─────────┬─────────┬──────────┤
│         │         │         │          │
│  Home   │   KPT   │ Insights│ Settings │
│         │         │         │          │
└─────────┴─────────┴─────────┴──────────┘
```

### Home

Your current state and recent activity.

- Wellness score with trend
- Latest retrospective summary
- Quick stats: sleep, steps, screen time
- Upcoming check-in reminder

### KPT

Create and manage retrospectives.

- New retrospective (Weekly / Monthly)
- Date range with quantitative context preview
- KPT entry with rich text
- History of past retrospectives

### Insights

Deep dive into your data.

- Health trends over time
- Screen time patterns
- Correlations between metrics
- Personal best highlights

### Settings

Control your experience.

- Health permissions
- Screen Time permissions
- iCloud sync status
- Notification preferences
- Export data
- About

---

## Data Model

### Core Entities

```
Retrospective
├── id: UUID
├── title: String
├── type: weekly | monthly
├── dateRange: DateInterval
├── keeps: [KPTItem]
├── problems: [KPTItem]
├── tries: [KPTItem]
├── context: QuantitativeContext?
└── timestamps: created, updated

KPTItem
├── id: UUID
├── category: keep | problem | try
├── text: String
├── retrospective: Retrospective
└── timestamps: created, updated

QuantitativeContext
├── id: UUID
├── dateRange: DateInterval
├── health: HealthSummary?
├── screenTime: ScreenTimeSummary?
├── wellnessScore: Int?
└── retrospective: Retrospective?
```

### Health Summary

```
HealthSummary
├── avgSleepMinutes: Int?
├── avgSleepQuality: Int?        (0-100)
├── avgSteps: Int?
├── avgActiveCalories: Int?
├── totalExerciseMinutes: Int?
├── avgStandHours: Int?
└── totalWorkouts: Int?
```

### Screen Time Summary

```
ScreenTimeSummary
├── avgScreenMinutes: Int?
├── avgPickups: Int?
├── avgNotifications: Int?
└── topCategories: [String]?
```

---

## Design Language

### Color System

| Element | Color | Hex | Usage |
|---------|-------|-----|-------|
| Keep | Green | #34C759 | Positive, continue |
| Problem | Red | #FF3B30 | Challenges |
| Try | Purple | #AF52DE | Experiments |
| Health | Blue | #007AFF | Quantitative data |
| Screen Time | Orange | #FF9500 | Digital wellness |
| Wellness | Teal | #5AC8FA | Overall score |

### Typography

Following Apple Human Interface Guidelines:

- **Large Title** — Screen headers
- **Title** — Section headers
- **Body** — Primary content
- **Callout** — Secondary information
- **Caption** — Metadata and labels

### Components

- Native SwiftUI controls
- SF Symbols for all icons
- Card-based layouts for KPT items
- Charts for quantitative visualization
- Dynamic Type support throughout

---

## Technical Architecture

### Platform Requirements

| Requirement | Version |
|-------------|---------|
| iOS | 17.0+ |
| watchOS | 10.0+ |
| Swift | 5.9+ |
| Xcode | 15.0+ |

### Technology Stack

| Layer | Technology |
|-------|------------|
| UI | SwiftUI |
| Data | SwiftData |
| Sync | CloudKit (automatic) |
| Health | HealthKit |
| Screen Time | DeviceActivity |
| Charts | Swift Charts |

### Project Structure

```
agile-self/
├── App/
│   └── AgileSelfApp.swift
├── Models/
│   ├── Retrospective.swift
│   ├── KPTItem.swift
│   ├── KPTCategory.swift
│   ├── QuantitativeContext.swift
│   ├── HealthSummary.swift
│   └── ScreenTimeSummary.swift
├── Views/
│   ├── Dashboard/
│   ├── KPT/
│   ├── Insights/
│   └── Settings/
├── Services/
│   ├── Health/
│   │   ├── HealthKitManager.swift
│   │   └── HealthDataAggregator.swift
│   ├── ScreenTime/
│   │   └── ScreenTimeManager.swift
│   └── Wellness/
│       └── WellnessScoreCalculator.swift
└── Utilities/
    ├── Theme.swift
    └── Extensions/
```

---

## Privacy

### Data Handling

- **On-Device Processing** — All health and screen time data processed locally
- **iCloud Sync** — Retrospectives sync via CloudKit to user's private database
- **No External Services** — Zero third-party analytics or tracking
- **Read-Only Health Access** — Never writes to Apple Health
- **User Control** — Full data export and deletion available

### Required Permissions

| Permission | Purpose |
|------------|---------|
| HealthKit Read | Access sleep, activity, workout data |
| DeviceActivity | Access screen time metrics |
| iCloud | Sync retrospectives across devices |
| Notifications | Weekly check-in reminders |

---

## Implementation Phases

### Phase 1: Core KPT

Foundation with simplified reflection flow.

- KPT entry interface (no actions)
- Retrospective list and detail views
- SwiftData models and CloudKit sync
- Basic dashboard

### Phase 2: Health Integration

Connect Apple Health data.

- HealthKit authorization flow
- Health data fetching and aggregation
- Health summary display during KPT entry
- Wellness score calculation (health only)

### Phase 3: Screen Time Integration

Add digital wellness context.

- DeviceActivity authorization
- Screen time data collection
- Combined quantitative context
- Full wellness score

### Phase 4: Insights

Data visualization and trends.

- Swift Charts implementation
- Historical trend views
- Correlation insights
- Personal bests and streaks

### Phase 5: Polish

Refinement and platform expansion.

- watchOS companion app
- Home screen widgets
- Accessibility audit
- Performance optimization

---

## Appendix

### Wellness Score Algorithm

```
Sleep Score (0-40 points)
├── Duration: 7-9 hours optimal
├── Consistency: Regular bedtime
└── Quality: Deep sleep percentage

Activity Score (0-30 points)
├── Steps: 8000+ daily target
├── Exercise: 30+ min daily
└── Stand hours: 12+ hours

Balance Score (0-30 points)
├── Screen time: <4 hours daily
├── Pickups: <50 per day
└── Evening screen: Minimal after 9pm

Total: 0-100
```

### KPT vs KPTA

This app uses KPT (Keep, Problem, Try) rather than KPTA:

| Framework | Components | Focus |
|-----------|------------|-------|
| KPTA | Keep, Problem, Try, Action | Reflection + Task Management |
| KPT | Keep, Problem, Try | Pure Reflection |

KPT keeps the focus on self-awareness and insight. Task management is left to dedicated tools.

---

*Agile Self — Your AI Growth Partner*
