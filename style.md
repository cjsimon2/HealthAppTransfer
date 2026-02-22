# Wes Anderson UI Style Guide

## Design Philosophy
Warm, curated, analog-feeling aesthetic. Aged paper surfaces, editorial serif typography, warm shadows, and subtle paper grain textures. Every surface should feel like a beautifully designed journal, never cold or clinical.

## Color Palette (defined in `Theme/AppColors.swift`)

### Brand Colors
| Token | Light | Dark | Use |
|-------|-------|------|-----|
| `AppColors.primary` | Ochre Gold `#C49A2A` | `#E0B84D` | Tint, toggles, interactive elements |
| `AppColors.accent` | Terracotta `#D96B4B` | `#E8907A` | Emphasis, down-trend, alerts |
| `AppColors.secondary` | Warm Sage `#768E6A` | `#9AB88E` | Positive indicators, up-trend |

### Surface Colors
| Token | Light | Dark | Use |
|-------|-------|------|-----|
| `AppColors.surface` | Aged paper `#F5F0E6` | Warm leather `#1C1916` | Root background |
| `AppColors.surfaceElevated` | Cream `#FAF5ED` | `#26221D` | Cards, sheets |
| `AppColors.surfaceGrouped` | `#EDE7DB` | `#16130F` | Grouped sections |

### Text Colors
| Token | Light | Dark | Use |
|-------|-------|------|-----|
| `AppColors.textPrimary` | Warm ink `#2C2418` | Off-white `#F2EDDF` | Primary text |
| `AppColors.textSecondary` | Warm gray `#7A7068` | `#A09890` | Secondary/caption |

### Shadow & Border
| Token | Light | Dark | Use |
|-------|-------|------|-----|
| `AppColors.shadow` | `#3D2E1A` | `#000000` | Card shadows (at 10% opacity) |
| `AppColors.darkBorder` | `.clear` | Amber 8% | Dark mode card edges |

### Semantic (standard — clinical accuracy)
| Token | Color | Use |
|-------|-------|-----|
| `AppColors.success` | `.green` | Success states |
| `AppColors.warning` | `.orange` | Warning states |
| `AppColors.danger` | `.red` | Danger/error states |

## Typography (defined in `Theme/AppTypography.swift`)

### Display (New York Serif)
| Token | Size | Weight | Use |
|-------|------|--------|-----|
| `AppTypography.displayLarge` | `.largeTitle` | `.bold` | Hero text |
| `AppTypography.displayMedium` | `.title2` | `.semibold` | Section headers, sheet titles |
| `AppTypography.displaySmall` | `.title3` | `.medium` | Subsection headers |

### Body (SF Pro)
| Token | Size | Use |
|-------|------|-----|
| `AppTypography.bodyRegular` | `.body` | Standard text |
| `AppTypography.bodySemibold` | `.body` semibold | Emphasized body |
| `AppTypography.captionMedium` | `.caption` medium | Card labels |

### Monospaced
| Token | Size | Use |
|-------|------|-----|
| `AppTypography.monoValue` | `.title3` bold mono | Metric values |
| `AppTypography.monoValueSmall` | `.body` semibold mono | Smaller values |

## Layout (defined in `Theme/AppLayout.swift`)

### Corner Radii
| Token | Value | Use |
|-------|-------|-----|
| `AppLayout.cornerRadiusSmall` | 8pt | Small elements |
| `AppLayout.cornerRadiusButton` | 12pt | Buttons |
| `AppLayout.cornerRadiusCard` | 16pt | Cards |
| `AppLayout.cornerRadiusSheet` | 20pt | Sheets |

### Shadow
- Radius: 10pt, Y-offset: 4pt, Opacity: 10%
- Color: `AppColors.shadow`

### Spacing Scale
4, 8, 12, 16, 20, 24, 32

## Chart Colors (defined in `Theme/WarmChartColors.swift`)
All 17 categories have warm, muted analogs accessed via `category.warmChartColor`.

## View Modifiers (defined in `Theme/ViewModifiers.swift`)

### `.warmCard()`
Elevated surface fill + warm shadow + dark mode amber border.

### `.buttonStyle(.warmPrimary)`
Ochre gold background, white text, pressed opacity.

### `.buttonStyle(.warmSecondary)`
Outlined variant with warm border.

### `PaperGrainOverlay()`
128x128 static noise texture, tiled at 3% opacity.
Respects `accessibilityReduceTransparency`.

## Rules
1. **Semantic colors stay standard** — success/warning/danger for clinical accuracy
2. **System fonts only** — New York and SF Pro, no custom fonts
3. **Dynamic Type preserved** — all fonts use system variants
4. **Paper grain disabled** when `reduceTransparency` is true
5. **Touch targets unchanged** — modifiers affect visual only
6. **Use `warmChartColor`** instead of `chartColor` for category colors
