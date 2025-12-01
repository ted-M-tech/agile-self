# Agile Self

**Turn Reflection Into Action**

A native iOS app for personal growth through structured KPTA retrospectives, powered by Apple Health data.

---

## What is Agile Self?

Agile Self helps you build self-awareness through daily, weekly, and monthly retrospectives. Using the KPTA framework (Keep, Problem, Try, Action), you reflect on what's working, what's challenging, and what to try next - then automatically convert those insights into actionable tasks.

Your reflections are enriched with real data from Apple Health, giving you objective context alongside your subjective insights.

---

## Features

### KPTA Reflection
- **Keep** - Document wins and habits to continue
- **Problem** - Identify challenges and obstacles
- **Try** - Plan experiments and new approaches
- **Action** - Automatic task creation from every Try

### Health Dashboard
- Sleep duration (last night)
- Steps count (today)
- Active calories
- Exercise minutes

### Action Management
- Filter by status (pending, completed, overdue)
- Sort by priority or deadline
- Track completion across retrospectives

### Privacy-First
- All data stays on-device and in your iCloud
- No external servers or analytics
- Read-only access to Apple Health

---

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Apple Developer account (for CloudKit)

---

## Quick Start

```bash
git clone <repo-url>
cd agile-self
open agile-self.xcodeproj
```

1. Select your development team
2. Add HealthKit capability
3. Build and run (Cmd+R)

---

## Documentation

| Document | Description |
|----------|-------------|
| [Specification](./SPECIFICATION.md) | Complete product specification |
| [CLAUDE.md](../CLAUDE.md) | Development guidelines |

---

## Tech Stack

| Component | Technology |
|-----------|------------|
| UI | SwiftUI |
| Data | SwiftData + CloudKit |
| Health | HealthKit |
| Platform | iOS 17+ |

---

## License

MIT License

---

*Made for personal growth*
