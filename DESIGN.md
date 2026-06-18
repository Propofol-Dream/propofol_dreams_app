# Propofol Dreams — Design System

**Memorable thing:** *Serious medical tool. This is software for the operating room — precise, trustworthy, no-nonsense.*

---

## Design Philosophy

Borrows from two worlds: the **OR monitor** (dark, high-contrast, data-dense, glanceable) and the **infusion pump** (physical-button feel, channel-based, step-by-step programming). The result is a dark-first interface that puts calculation results front and center, with input as a deliberate secondary action.

---

## Responsive Layout System

### Breakpoints

| Breakpoint | Width | Device | Layout |
|---|---|---|---|
| Mobile | < 768px | Phone | Single column, bottom nav, full-screen results |
| Tablet | 768–1024px | iPad/landscape phone | 2-column (input sidebar + results), nav rail |
| Desktop | > 1024px | Laptop/desktop | 3-column (nav drawer + input + results), keyboard shortcuts |
| Web | Any | Browser | Same as desktop, with wider max-width (1440px) |

### Layout by Screen

#### Mobile (< 768px)

```
┌──────────────────────────────┐
│  AppBar: "TCI"               │
├──────────────────────────────┤
│  ┌────────────────────────┐  │
│  │ Collapsible Input Card  │  │
│  │ [▼] 25y/M/70kg/170cm   │  │
│  │     Propofol · Eleveld  │  │
│  │     3.0μg/mL · 255min   │  │
│  └────────────────────────┘  │
│                              │
│  ┌────────────────────────┐  │
│  │  Results Area           │  │
│  │  (full width, scroll)   │  │
│  │                        │  │
│  │  [Bolus] [Max] [Total] │  │
│  │                        │  │
│  │  ┌─ Rate Chart ──────┐ │  │
│  │  │  ╱╲    ╱╲         │ │  │
│  │  │ ╱  ╲  ╱  ╲        │ │  │
│  │  │╱    ╲╱    ╲       │ │  │
│  │  └───────────────────┘ │  │
│  │                        │  │
│  │  ┌─ Infusion Table ──┐ │  │
│  │  │ Time  Rate  Vol   │ │  │
│  │  │ 0:00  120   0.0   │ │  │
│  │  │ 0:15  100   30.0  │ │  │
│  │  │ ...               │ │  │
│  │  └───────────────────┘ │  │
│  └────────────────────────┘  │
├──────────────────────────────┤
│  [TCI] [Vol] [Dur] [ElM] [⚙]│  ← Bottom Nav
└──────────────────────────────┘
```

- **Input card** starts expanded, auto-collapses on calculate
- **Results** fill remaining space below
- **Bottom nav** for tab switching (5 tabs)
- **FAB** for calculate (when input is collapsed)

#### Tablet (768–1024px)

```
┌──────────────────────────────────────────────┐
│  AppBar: "TCI"                                │
├──────────────┬───────────────────────────────┤
│  Navigation  │  ┌─────────────────────────┐  │
│  Rail        │  │ Collapsible Input Card   │  │
│              │  │ [▼] Summary line         │  │
│  🧮 TCI      │  └─────────────────────────┘  │
│  📊 Volume   │                               │
│  ⏱ Duration  │  ┌─────────────────────────┐  │
│  🧠 EleMarsh │  │ Results                 │  │
│  ⚙ Settings  │  │ [Bolus] [Max] [Total]   │  │
│              │  │                         │  │
│              │  │ ┌─ Chart ─────────────┐ │  │
│              │  │ │  ╱╲    ╱╲          │ │  │
│              │  │ └────────────────────┘ │  │
│              │  │                         │  │
│              │  │ ┌─ Table ────────────┐ │  │
│              │  │ │ Time  Rate  Vol    │ │  │
│              │  │ └────────────────────┘ │  │
│              │  └─────────────────────────┘  │
├──────────────┴───────────────────────────────┤
│  Status bar (optional)                       │
└──────────────────────────────────────────────┘
```

- **Navigation rail** on the left (icons + labels)
- **Input card** in the main column (collapsible)
- **Results** below input, side-by-side with nothing
- Wider tables, more chart space

#### Desktop (> 1024px)

```
┌──────────────────────────────────────────────────────────────┐
│  AppBar: "Propofol Dreams · TCI Calculator"                   │
├──────────┬──────────────────────┬───────────────────────────┤
│  Nav     │  Input Panel         │  Results Panel             │
│  Drawer  │  (320–420px)         │  (flex, fills remaining)   │
│          │                      │                            │
│  🧮 TCI  │  ┌────────────────┐  │  ┌──────────────────────┐  │
│  📊 Vol  │  │ Patient        │  │  │ Dashboard Cards      │  │
│  ⏱ Dur   │  │ Age  Height    │  │  │ [Bolus] [Max] [Total]│  │
│  🧠 ElM  │  │ Weight  Sex    │  │  └──────────────────────┘  │
│  ⚙ Set   │  │                │  │                            │
│          │  │ Drug Selector  │  │  ┌──────────────────────┐  │
│          │  │ Model Selector │  │  │ Rate Chart (large)   │  │
│          │  │                │  │  │  ╱╲    ╱╲            │  │
│          │  │ Target Conc.   │  │  │ ╱  ╲  ╱  ╲           │  │
│          │  │ Duration       │  │  │╱    ╲╱    ╲          │  │
│          │  │                │  │  └──────────────────────┘  │
│          │  │ [ Calculate ]  │  │                            │
│          │  └────────────────┘  │  ┌──────────────────────┐  │
│          │                      │  │ Infusion Table       │  │
│          │                      │  │ (scrollable, sortable)│  │
│          │                      │  └──────────────────────┘  │
├──────────┴──────────────────────┴───────────────────────────┤
│  Status bar: Model info · Drug concentration · Pump rate     │
└──────────────────────────────────────────────────────────────┘
```

- **Navigation drawer** on the left (collapsible, icons + labels)
- **Input panel** fixed width (320–420px), always visible
- **Results panel** fills remaining space
- **Status bar** at bottom with contextual info
- **Keyboard shortcuts**: Enter to calculate, Tab between fields

#### Web (browser, responsive)

Same as desktop layout with:
- Max content width: 1440px
- Centered layout on ultra-wide screens
- Print-friendly styles for clinical printouts
- Keyboard navigation for power users

---

## Color System

### Dark Theme (Primary — OR Monitor Inspired)

| Token | Usage | Hex |
|---|---|---|
| `surface` | Main background | `#0D1117` |
| `surfaceContainer` | Card backgrounds | `#161B22` |
| `surfaceContainerHigh` | Input fields | `#1C2333` |
| `surfaceContainerHighest` | Hover/selected states | `#21262D` |
| `primary` | Accent, active elements | `#58A6FF` (blue) |
| `primaryContainer` | Selected state bg | `#1F3A5F` |
| `onPrimary` | Text on primary | `#FFFFFF` |
| `secondary` | Secondary info | `#8B949E` |
| `tertiary` | Warnings | `#D29922` |
| `error` | Errors | `#F85149` |
| `onSurface` | Primary text | `#E6EDF3` |
| `onSurfaceVariant` | Secondary text | `#8B949E` |
| `outline` | Borders | `#30363D` |
| `outlineVariant` | Subtle borders | `#21262D` |

### Light Theme

| Token | Usage | Hex |
|---|---|---|
| `surface` | Main background | `#FFFFFF` |
| `surfaceContainer` | Card backgrounds | `#F6F8FA` |
| `surfaceContainerHigh` | Input fields | `#EEF1F5` |
| `surfaceContainerHighest` | Hover/selected states | `#E1E4E8` |
| `primary` | Accent, active elements | `#0969DA` |
| `primaryContainer` | Selected state bg | `#DDF4FF` |
| `onPrimary` | Text on primary | `#FFFFFF` |
| `secondary` | Secondary info | `#656D76` |
| `tertiary` | Warnings | `#9A6700` |
| `error` | Errors | `#CF222E` |
| `onSurface` | Primary text | `#1F2328` |
| `onSurfaceVariant` | Secondary text | `#656D76` |
| `outline` | Borders | `#D0D7DE` |
| `outlineVariant` | Subtle borders | `#E1E4E8` |

### Drug Colors (existing system, preserved)

| Drug | Light | Dark |
|---|---|---|
| Propofol | `#FFD700` | `#FFD700` |
| Remifentanil 20mcg | `#2196F3` | `#64B5F6` |
| Remifentanil 40mcg | `#03A9F4` | `#4FC3F7` |
| Remifentanil 50mcg | `#F44336` | `#EF5350` |
| Dexmedetomidine | `#4CAF50` | `#81C784` |
| Remimazolam | `#9C27B0` | `#CE93D8` |

---

## Typography

| Style | Size | Weight | Usage |
|---|---|---|---|
| `headlineLarge` | 28sp | Regular | Screen titles |
| `headlineMedium` | 24sp | Regular | Section headers |
| `headlineSmall` | 20sp | Regular | Card titles |
| `titleLarge` | 18sp | Medium | Input labels |
| `titleMedium` | 16sp | Medium | Field labels |
| `bodyLarge` | 16sp | Regular | Body text |
| `bodyMedium` | 14sp | Regular | Secondary text |
| `bodySmall` | 12sp | Regular | Helper/error text |
| `labelLarge` | 14sp | Medium | Button text |
| `labelSmall` | 11sp | Medium | Badge text |

**Monospace** (for numerical data in tables and charts):
- `14sp` / `Medium` — table values
- `12sp` / `Regular` — chart axis labels

---

## Spacing & Sizing

All spacing uses the design token scale: `kSp2`, `kSp4`, `kSp8`, `kSp12`, `kSp16`, `kSp24`, `kSp32`.

### Component Heights

| Component | Mobile | Tablet | Desktop |
|---|---|---|---|
| Input fields | 56px | 60px | 64px |
| Segmented buttons | 40px | 44px | 48px |
| Bottom nav | 64px | — | — |
| Nav rail items | — | 56px | — |
| Nav drawer items | — | — | 48px |
| Status bar | — | — | 32px |
| Collapsed input card | 68px | 56px | 48px |

### Card Elevation

| State | Elevation |
|---|---|
| Collapsed | `kElev1` (1dp) |
| Expanded | `kElev3` (3dp) |
| Modal/Dialog | `kElev8` (8dp) |

### Border Radius

| Component | Radius |
|---|---|
| Cards | `kRadiusLg` (12dp) |
| Input fields | `kRadius` (8dp) |
| Buttons | `kRadius` (8dp) |
| Chips/Badges | `kRadiusSm` (4dp) |
| Bottom sheet | `kRadiusXl` (20dp) top |

---

## Component Design

### Collapsible Input Card

The core interaction pattern. Borrows from infusion pump step-by-step programming.

**Expanded state:** Shows all input fields for the current calculator. Header has title + expand/collapse chevron. Calculate button at bottom.

**Collapsed state:** Single-line summary of current values. Tapping re-expands. Auto-collapses on successful calculation.

**States:**
- Default: `surfaceContainer` background, `kElev1`
- Expanded: `surfaceContainer` background, `kElev3`
- Validation error: Red border (`error`), forced expanded
- Calculating: Button shows spinner, inputs disabled

### Navigation

**Mobile:** Bottom `NavigationBar` with 5 destinations. Active tab uses `primary` color.

**Tablet:** `NavigationRail` with icons + labels. Active item uses `primaryContainer` background.

**Desktop:** `NavigationDrawer` with full labels. Collapsible to icon-only. Active item uses `primaryContainer`.

### Results Display

**Dashboard cards:** 3 compact stat cards (Bolus, Max Rate, Total Volume). Each has icon, label, value. `kRadiusLg` corners.

**Rate chart:** Custom-painted line chart. Dark background, `primary` line, subtle grid. Hover/tap to see exact values. Responsive height.

**Infusion table:** Scrollable data table. Time, Rate, Volume columns. Selected row highlighted. Conditional decimal formatting (1dp for <10, 0dp for ≥10).

---

## Animation

| Element | Duration | Curve |
|---|---|---|
| Card expand/collapse | `kAnimNormal` (300ms) | `easeInOutCubic` |
| Content fade | `kAnimFast` (200ms) | `easeInOut` |
| Tab switch | `kAnimFast` (200ms) | `easeInOut` |
| Button press | 50ms | Immediate |
| Validation error | `kAnimFast` (200ms) | `easeInOut` |

---

## Implementation Priority

1. **Phase 1:** Dark theme color scheme + responsive breakpoint utilities
2. **Phase 2:** Navigation rail (tablet) + navigation drawer (desktop)
3. **Phase 3:** Adaptive layout system (3-column desktop, 2-column tablet)
4. **Phase 4:** Status bar + keyboard shortcuts
5. **Phase 5:** Print styles + web optimization
