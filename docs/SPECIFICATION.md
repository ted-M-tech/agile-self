# Agile Self - Product Specification

**Turn Reflection Into Action**

A native iOS app for personal growth through structured KPTA retrospectives, enriched with Apple Health data.

---

## Overview

Agile Self combines the KPTA reflection framework with quantitative insights from Apple Health. By connecting subjective reflection with measurable data, users gain deeper self-awareness and convert insights into concrete actions.

### Core Principles

- **Reflection-First** - Daily, weekly, and monthly retrospectives using KPTA
- **Action-Oriented** - Every Try automatically becomes an actionable task
- **Data-Informed** - Health and activity context for each retrospective
- **Privacy-Native** - All data on-device and in user's iCloud
- **Minimal Design** - Clean Apple-style interface

---

## KPTA Framework

The KPTA framework structures reflection into four categories:

### Keep
What went well. What to continue.
- Positive habits maintained
- Achievements and wins
- Effective strategies

### Problem
What challenged you. What got in the way.
- Obstacles and frustrations
- Patterns that didn't serve you
- Areas needing attention

### Try
What you'll experiment with next.
- New approaches to test
- Solutions to problems identified
- Ways to build on keeps

### Action
Concrete tasks derived from Tries.
- Each Try automatically creates an Action
- Actions have optional deadlines and priorities
- Track completion across all retrospectives

---

## App Structure

### Navigation (3 Tabs)

```
┌─────────────────────────────────────────┐
│                                         │
│              Home Dashboard             │
│         Health + Stats + Recent         │
│                                         │
├─────────────┬─────────────┬─────────────┤
│             │             │             │
│    Home     │   Actions   │   History   │
│             │             │             │
└─────────────┴─────────────┴─────────────┘
```

### Home
Dashboard view with:
- Today's health metrics (sleep, steps, calories, exercise)
- Quick stats (retros count, pending actions, completed)
- Overdue actions alert
- Upcoming actions
- Recent retrospective summary
- Settings access (gear icon in nav bar)

### Actions
Action management with:
- Filter by status (all, pending, completed, overdue)
- Sort by priority, deadline, or date created
- Mark complete/incomplete
- Edit details and deadlines
- Add standalone actions

### History
Past retrospectives with:
- List grouped by month
- Filter by type (daily, weekly, monthly)
- Detail view showing all KPTA items
- Delete retrospectives

### New Retrospective (Sheet)
Step-by-step wizard flow:
1. **Setup** - Select type (daily/weekly/monthly) and date range
2. **Keep** - Enter keeps
3. **Problem** - Enter problems
4. **Try** - Enter tries (each becomes an action)
5. **Review** - Preview and save

---

## Data Model

### Retrospective
```
Retrospective
├── id: UUID
├── title: String
├── type: daily | weekly | monthly
├── startDate: Date
├── endDate: Date
├── kptaItems: [KPTAItem]       # All K/P/T items
├── actions: [ActionItem]
├── healthSummary: HealthSummary?
├── createdAt: Date
└── updatedAt: Date
```

### KPTAItem
```
KPTAItem
├── id: UUID
├── text: String
├── category: keep | problem | try
├── orderIndex: Int
├── retrospective: Retrospective
├── createdAt: Date
└── updatedAt: Date
```

### ActionItem
```
ActionItem
├── id: UUID
├── text: String
├── isCompleted: Bool
├── completedAt: Date?
├── deadline: Date?
├── priority: low | medium | high
├── fromTryItem: Bool
├── notes: String?
├── retrospective: Retrospective?
├── sourceKPTAItem: KPTAItem?
├── createdAt: Date
└── updatedAt: Date
```

### HealthSummary
```
HealthSummary
├── id: UUID
├── periodStart: Date
├── periodEnd: Date
├── avgSleepMinutes: Int?
├── avgSteps: Int?
├── avgActiveCalories: Int?
├── totalExerciseMinutes: Int?
├── avgStandHours: Int?
├── totalWorkouts: Int?
├── wellnessScore: Int?          # 0-100
└── retrospective: Retrospective?
```

---

## Health Integration

### Metrics Displayed

| Metric | Source | Display |
|--------|--------|---------|
| Sleep | HealthKit (sleepAnalysis) | Hours and minutes |
| Steps | HealthKit (stepCount) | Daily count |
| Active Calories | HealthKit (activeEnergyBurned) | kcal |
| Exercise | HealthKit (appleExerciseTime) | Minutes |

### Home Dashboard
Today's health data shown in a 2x2 grid with icons and colors.

### Authorization
- Request read-only access on first launch
- Handle denial gracefully with fallback UI
- Show "Enable in Settings" message if denied

---

## Design Language

### Color Scheme

| Element | Color | Usage |
|---------|-------|-------|
| Keep | Green (#34C759) | Positive items |
| Problem | Red (#FF3B30) | Challenges |
| Try | Purple (#AF52DE) | Experiments |
| Action | Blue (#007AFF) | Tasks |

### Typography
Following Apple Human Interface Guidelines:
- Large Title - Screen headers
- Headline - Section headers
- Body - Content
- Callout - Secondary text
- Caption - Labels and metadata

### Components
- Native SwiftUI controls
- SF Symbols for icons
- Card-based layouts
- .regularMaterial backgrounds
- Rounded corners (Theme.CornerRadius)

---

## Technical Stack

| Component | Technology |
|-----------|------------|
| Language | Swift 5.9+ |
| UI | SwiftUI |
| Data | SwiftData |
| Sync | CloudKit (automatic) |
| Health | HealthKit |
| Platform | iOS 17.0+ |

---

## Privacy

- All data stored on-device and in user's private iCloud
- No external servers or analytics
- Read-only HealthKit access
- User can delete all data in Settings
- Health data never leaves Apple ecosystem

---

## Future Considerations

- Voice input with Apple Speech Recognition
- AI-powered insights (on-device or Apple Intelligence)
- watchOS companion app
- Home screen widgets
- Screen Time integration (DeviceActivity)
- Calendar integration
