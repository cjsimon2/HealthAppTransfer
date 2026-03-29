---
description: Full 7-dimension project audit with findings report
---
Perform a comprehensive 7-dimension audit of the HealthAppTransfer project.

**Dimensions**:
1. Documentation accuracy (cross-reference CLAUDE.md, README, STATE.md against code)
2. Bug & problem detection (sync, export, import, network paths first)
3. Code quality & professionalism (Swift/SwiftUI conventions, MVVM compliance)
4. Dead code detection (unused services, models, view models)
5. Future features & upgrades (use WebSearch for iOS/Swift deprecations)
6. Security review (TLS, Keychain, entitlements, network exposure)
7. Output all findings to `PROJECT_AUDIT_REPORT.md` at project root

**Priority**: Data integrity items (sync, export format correctness, HealthKit mapping) are always checked FIRST in every dimension.

Use TodoWrite to track progress across all 7 dimensions.
