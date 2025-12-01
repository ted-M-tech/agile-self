# Agile Self

**Turn Reflection Into Action**

A native iOS app for personal growth through structured reflection, powered by your health and activity data.

---

## What is Agile Self?

Agile Self helps you build self-awareness through weekly retrospectives. Using the KPT framework (Keep, Problem, Try), you reflect on what's working, what's challenging, and what to experiment with next.

What makes it different: your reflections are enriched with real data from Apple Health and Screen Time, giving you objective context alongside your subjective insights.

---

## Features

### KPT Reflection

- **Keep** — Document wins and habits to continue
- **Problem** — Identify challenges and obstacles
- **Try** — Plan experiments and new approaches

### Quantitative Context

- Sleep duration and quality
- Activity and exercise metrics
- Screen time and device pickups
- Unified wellness score (0-100)

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
2. Enable capabilities: iCloud, HealthKit
3. Build and run

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
| Screen Time | DeviceActivity |
| Charts | Swift Charts |

---

## License

MIT License

---

*Made for personal growth*
