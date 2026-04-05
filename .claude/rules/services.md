---
description: Rules for service layer files
globs:
  - "agile-self/Services/**/*.swift"
---

# Service Layer Rules

- Use `@Observable` only when the service has view-observable state (e.g., `isAuthorized`, `isProcessing`)
- Otherwise use plain `final class`
- All services are created and held by `AppContainer` (lazy initialization)
- Use protocol abstraction for testability (e.g., `AIServiceProtocol`)
- Mark methods `nonisolated` when they don't touch `@Observable` state
- NEVER use `@unchecked Sendable` — fix the actual isolation
- Error handling: services should `throw`, callers decide how to handle
- HealthKit: never write data, read-only access (`toShare: []`)
- HealthKit: request permissions at point of use, not at app launch
