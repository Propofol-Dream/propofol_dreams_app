# Mobile Workflow & Real-Time Infusion Table

## Status
- **Date:** 2026-06-19
- **Version:** v3.0.8+130
- **Author:** George / Eddy

## Overview

Four workstreams targeting mobile UX improvements and a new real-time infusion table feature for anaesthesia workflow.

---

## 1. EleMarsh Result Hierarchy

**Problem:** All stat cards look the same — ABW and Induction CpT/Bolus (clinically critical) have equal visual weight to eBIS, BMI, and vial times (reference info).

**Solution:** Differentiate by size, weight, and border.

| Tier | Items | Font Size | Weight | Border | Color |
|------|-------|-----------|--------|--------|-------|
| **Primary** | ABW, Induction CpT/Bolus | 32px | 800 | 2px primary | `colorScheme.primary` |
| **Secondary** | eBIS | 18px | 600 | 1px outline | `colorScheme.onSurface` |
| **Tertiary** | BMI, 20 mL, 50 mL | 18px | 600 | 1px outline | `colorScheme.onSurface` |

Cards remain separate (BMI does not merge into eBIS). Units sit next to values (already done in `_buildStatCard`).

**Files:** `lib/screens/elemarsh_screen.dart` — add a `fontSize` parameter to `_buildStatCard`, pass different sizes per tier.

---

## 2. Collapsible Input Panels

**Problem:** Once data is entered, the input panel takes up screen space that could show results — especially on mobile.

**Solution:** All screens get a collapsible input card with a header bar showing a summary of current inputs.

### Layout
- **Header bar**: Title + summary text + collapse arrow. Always visible.
- **Body**: Fields (PKField, SwitchField, button groups). Collapsible via `AnimatedCrossFade` or `AnimatedSize`.
- **Desktop**: `CollapsibleInputSection` is not used — fields render directly without a wrapper.
- **Mobile**: Starts expanded (no auto-collapse).

### Summary display
Each screen shows a concise one-liner in the header:
- **EleMarsh**: `"{flow} · {sex} · {age}y · {weight}kg · {height}cm · CeT {target}"`
- **TCI**: `"{drug} · {sex} · {age}y · {weight}kg · {height}cm · CeT {target}"`
- **Volume**: `"{model} · {weight}kg · {rate} mL/hr · {hours}h"`
- **Duration**: `"{weight}kg · {rate} {unit}"`

### Animation
- 300ms `fastOutSlowIn` curve
- Smooth slide, no jank

### Per-screen implementation
Each screen wraps its `_buildInputFields` in a new `CollapsibleInputSection` widget (or equivalent):
```dart
Widget _buildInputPanel(Settings settings) {
  return CollapsibleInputSection(
    summary: _buildSummary(),
    child: _buildInputFields(settings),
  );
}
```

**New widget:** `lib/components/collapsible_input_section.dart`
- Generic wrapper widget
- Takes `summary` (Widget or String) and `child` (Widget)
- Has `isCollapsed` state, toggle on tap
- `CollapsibleInputSectionTheme` if needed

**Files:**
- New: `lib/components/collapsible_input_section.dart`
- Modified: `lib/screens/elemarsh_screen.dart`, `lib/screens/tci_screen.dart`, `lib/screens/volume_screen.dart`, `lib/screens/duration_screen.dart`
- No change to Settings screen (no results to show)

---

## 3. Real-Time Infusion Table

**Problem:** During surgery, the anaesthetist needs to know where they are in the infusion timeline — what's been given, what's coming next, and how it maps to the current wall clock.

**Solution:** A sync mechanism on the TCI data table that anchors a selected row to the current wall clock, dims past rows, and shows a progress indicator.

### Workflow
1. User taps a **time cell** in the dosage table (e.g., "0:45") — row highlights with selection indicator
2. User goes to the **Sync section** inside the input panel:
   - Sets the **current wall clock time** via a time picker (defaults to `TimeOfDay.now()`)
   - Taps **"Sync Time"** button
3. The table **anchors** the selected row's infusion time to the entered wall clock time
4. **Past rows dim** to 30% opacity
5. **"Now" row** gets a distinct highlight + "◀ (now)" label
6. **Future rows** remain full opacity
7. A **progress bar** appears at the top of the table showing elapsed fraction
8. User can tap **"Clear Sync"** to reset

### Behavior
- **Static snapshot** — no live timer auto-advance. User manually re-syncs to update.
- Sync state is **in-memory only** — not persisted to SharedPreferences.
- Sync mode is separate from table row selection (does not change `selectedDosageTableRow`).
- **Sync clears automatically** when the table recalculates (user changes inputs → new `InfusionRegimeData` → old row indices invalid).
- Only one synced time point at a time.
- Works on both mobile and desktop.

### UI
- Dimmed rows: `opacity: 0.3`
- Now row: `background: secondaryContainer`, `◀ (now)` suffix on time
- Progress bar: `LinearProgressIndicator` above the table, value = `syncedRowIndex / totalRows`
- Sync controls: time picker (HH:MM) + "Sync Time" + "Clear Sync" buttons
- Sync section placement: **inside the input panel** (collapsible, same as other inputs)

### State variables (in `_TCIScreenState`)
```dart
int? _syncedRowIndex;          // Which row is anchored
TimeOfDay? _syncedClockTime;   // Wall clock time entered by user
bool _isTableSynced = false;   // Whether sync mode is active
```

### Files
- `lib/components/infusion_regime_table.dart` — modify `DosageDataTable` to accept sync state (`syncedRowIndex`, `isSynced`) and render dim/now styling
- `lib/screens/tci_screen.dart` — add sync state (`_syncedRowIndex`, `_isTableSynced`), sync controls, progress bar

---

## 4. Mobile-First Pass

**Problem:** TCI screen on mobile has too much vertical content. Chips and chart consume space that could show the table.

**Already done (this session):**
- Removed patient chips on mobile (desktop still shows them)
- Removed infusion rate chart on mobile (desktop still shows it)

**Remaining changes:**
- Dashboard cards on mobile: use **compact card style** (option A) — smaller padding, 16px font, tighter layout
- Data table: reduce `maxVisibleRows` from 8 to 4 on mobile
- Collapsible input panels (workstream #2) will further free up space

### TCI dashboard cards
The TCI dashboard (`_buildDashboardCards`) uses inline `Card` widgets with hardcoded padding/fonts — not `_buildStatCard`. Implement compact mode by passing a `compact` bool to `_buildDashboardCards`:

```dart
Widget _buildDashboardCards(InfusionRegimeData data, {bool compact = false})
```

Compact values:
- `padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8)`
- value `fontSize: 16`, subtitle `fontSize: 10`, icon `size: 14`
- Card elevation stays 1

Desktop values (unchanged):
- `padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10)`
- value `fontSize: 24`, subtitle `fontSize: 11`, icon `size: 16`

### Data table rows on mobile
In `_buildResults`, pass `maxVisibleRows: 4` on mobile (vs 8 on desktop).

### Files
- `lib/screens/tci_screen.dart` — `_buildDashboardCards` gets `compact` param, `_buildResults` passes mobile flag

---

## Implementation Order

1. **Collapsible input panels** — foundational; all screens benefit, enables future mobile work
2. **EleMarsh result hierarchy** — quick visual fix
3. **Mobile-first pass (TCI)** — compact cards + reduced rows
4. **Real-time infusion table** — most complex, builds on existing table infrastructure

## Future Considerations
- Real-time auto-advance of "now" row (live timer) — deferred, George wants static snapshot
- Volume/Duration screens could also benefit from real-time sync if they add time-anchored tables