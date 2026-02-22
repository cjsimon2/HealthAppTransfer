# Wes Anderson UI Overhaul — Implementation Plan

## Status: In Progress

## Phase 1: Theme Foundation — COMPLETED
Created 5 files in `HealthAppTransfer/Theme/`:
- [x] `AppColors.swift` — Adaptive light/dark color tokens
- [x] `AppTypography.swift` — Serif display + sans body fonts
- [x] `AppLayout.swift` — Corner radii, shadows, spacing
- [x] `WarmChartColors.swift` — Warm-shifted category colors (`warmChartColor`)
- [x] `ViewModifiers.swift` — WarmCardModifier, button styles, PaperGrainOverlay

## Phase 2: App Shell (3 files) — PENDING
- [ ] `App/HealthAppTransferApp.swift` — `.tint(.red)` → `.tint(AppColors.primary)`
- [ ] `Views/ContentView.swift` — Lock screen colors, root background + PaperGrainOverlay
- [ ] `Views/MainTabView.swift` — Minimal/none (inherits tint)

## Phase 3: Dashboard (2 files) — PENDING
- [ ] `Views/Dashboard/MetricCardView.swift` — `.warmCard()`, warm chart colors, typography
- [ ] `Views/Dashboard/DashboardView.swift` — Empty state colors, picker checkmarks

## Phase 4: Charts (2 files) — PENDING
- [ ] `Views/Charts/ChartStyleModifier.swift` — `warmChartColor` gradient
- [ ] `Views/Charts/HealthChartView.swift` — Chart colors, tooltip bg

## Phase 5: Health Data (2 files) — PENDING
- [ ] `Views/HealthData/HealthDataView.swift` — Category dots, empty state
- [ ] `Views/HealthData/HealthDataDetailView.swift` — Stats card, section headers

## Phase 6: Settings (6 files) — PENDING
- [ ] `Views/Settings/SettingsView.swift` — Icon badge colors
- [ ] `Views/Settings/PairingView.swift` — Header/banner colors
- [ ] `Views/Settings/PairedDevicesView.swift` — Status colors
- [ ] `Views/Settings/LANSyncView.swift` — Status/banner colors
- [ ] `Views/Settings/SyncSettingsView.swift` — Accent colors
- [ ] `Views/Settings/SecuritySettingsView.swift` — Toggle colors

## Phase 7: Automations (6 files) — PENDING
- [ ] `Views/Automations/AutomationsView.swift` — Empty state, type colors
- [ ] `Views/Automations/MQTTAutomationFormView.swift` — Checkmark colors
- [ ] `Views/Automations/RESTAutomationFormView.swift` — Checkmark colors
- [ ] `Views/Automations/CloudStorageFormView.swift` — Checkmark colors
- [ ] `Views/Automations/CalendarFormView.swift` — Accent colors
- [ ] `Views/Automations/HomeAssistantFormView.swift` — Checkmark colors

## Phase 8: Onboarding (5 files) — PENDING
- [ ] `Views/Onboarding/OnboardingView.swift` — Bottom bar background
- [ ] `Views/Onboarding/WelcomeStepView.swift` — Fonts, backgrounds
- [ ] `Views/Onboarding/HealthKitStepView.swift` — Icon, backgrounds
- [ ] `Views/Onboarding/NotificationStepView.swift` — Icon, backgrounds
- [ ] `Views/Onboarding/QuickSetupStepView.swift` — Backgrounds

## Phase 9: Export (1 file) — PENDING
- [ ] `Views/Export/QuickExportView.swift` — Checkmark colors

## Phase 10: Cleanup — PENDING
- [ ] Rename `warmChartColor` → `chartColor` (delete old property)
- [ ] Normalize hardcoded corner radii to AppLayout constants
- [ ] Remove remaining system color references

## Key Migration Patterns

### Color Replacements
| Old | New |
|-----|-----|
| `.red` (tint) | `AppColors.primary` |
| `.blue` (checkmarks) | `AppColors.primary` |
| `.green` (trend up) | `AppColors.secondary` |
| `.red` (trend down) | `AppColors.accent` |
| `.orange` (emphasis) | `AppColors.accent` |
| `Color(.systemBackground)` | `AppColors.surface` |
| `.fill.tertiary` | `AppColors.surfaceElevated` |
| `chartColor` | `warmChartColor` |

### Font Replacements
| Old | New |
|-----|-----|
| `.title2.bold()` | `AppTypography.displayMedium` |
| `.caption.weight(.medium)` | `AppTypography.captionMedium` |
| `.title3.bold().monospacedDigit()` | `AppTypography.monoValue` |

### Card Styling
| Old | New |
|-----|-----|
| `RoundedRectangle(...)  .fill(.background)  .shadow(...)` | `.warmCard()` |

## Files That DON'T Need Changes
- `Views/MainTabView.swift` — Inherits tint from parent
- `Views/Charts/WorkoutMapView.swift` — Minimal/no color updates needed
