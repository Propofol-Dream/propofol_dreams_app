# Design Token System Spec

## Status

| Phase | Description | State |
|---|---|---|
| A | Token file + theme wiring + M3TextField cleanup + settings_screen_m3 | **Done** (merged in working tree) |
| B | M3 components already on tokens (trim duplicate theme overrides, consolidate responsive height) | **Open — small, safe** |
| C | Migrate legacy screens per-screen during M3 migration | **Deferred — coupled to `M3_MIGRATION_SPEC.md`** |
| D | Animation polish (tab fade, page transitions, list reorder, snackbar, hero) | **Open — new** |

This spec is no longer "future work". It records what was built, what remains, and the resolved disagreements between `DESIGN.md`, `UI_REDESIGN_PLAN.md`, and the live code.

---

## Problem (as originally written)

The project had **zero** shared design tokens. Every border radius, spacing, elevation, and animation duration was hardcoded inline across 40+ files. This made it impossible to achieve a consistent M3 look and feel.

| Category | Unique values | Occurrences |
|---|---|---|
| Border radius | 2, 5, 6, 8, 8.0, 12, 20 | 37 `BorderRadius.circular` (8 already tokenised in `theme.dart`) |
| Spacing | 0, 2, 4, 8, 12, 14, 16, 24, 32, … | 97 `EdgeInsets.` (many layout-specific, not design tokens) |
| Elevation | 0, 1, 3, 8 | 13 (across `Card`, `Material`, `AnimatedContainer`) |
| Animation | 25, 50, 150, 200, 300, 500ms | 20 `Duration(milliseconds: …)` (3 are token definitions themselves) |

---

## Token File — `lib/config/design_tokens.dart`

Already created. ~30 lines (27 today, +4 when the two color seeds are added). Single source of truth.

```dart
// ── Border Radius ──────────────────────────────────────────
const kRadiusSm = 4.0;
const kRadius = 8.0;       // M3 default for all components
const kRadiusLg = 12.0;
const kRadiusXl = 20.0;

// ── Spacing Scale ──────────────────────────────────────────
const kSp2 = 2.0;
const kSp4 = 4.0;
const kSp8 = 8.0;
const kSp12 = 12.0;
const kSp16 = 16.0;
const kSp24 = 24.0;
const kSp32 = 32.0;

// ── Elevation ─────────────────────────────────────────────
const kElev0 = 0.0;
const kElev1 = 1.0;
const kElev3 = 3.0;
const kElev8 = 8.0;

// ── Animation Duration ────────────────────────────────────
const kAnimFast = Duration(milliseconds: 200);
const kAnimNormal = Duration(milliseconds: 300);

// ── Debounce / Input Delay ────────────────────────────────
const kDebounce = Duration(milliseconds: 500);

// ── Color Seeds ───────────────────────────────────────────
// import 'package:flutter/material.dart' show Color;   // needed when seeds are added
const kSeedLight = Color(0xFF0D6B58);
const kSeedDark  = Color(0xFF86D6BF);
```

Already imported by 6 files (`theme.dart`, `collapsible_input_card.dart`, `m3_dropdown_menu.dart`, `realtime_screen.dart`, `settings_screen.dart`, `settings_screen_m3.dart`). 106 references.

---

## Theme Wiring — `lib/theme.dart`

Already wired. `MaterialTheme` exposes `light()`, `dark()`, plus 4 contrast variants. `theme(ColorScheme)` adds:

- `SegmentedButtonThemeData` — `BorderRadius.circular(kRadius)`
- `DropdownMenuThemeData` — `InputDecorationTheme(filled: true, fillColor: surfaceContainerHighest, border: BorderRadius.circular(kRadius))`
- `InputDecorationTheme` — 5 border states (border, enabledBorder, focusedBorder, errorBorder, focusedErrorBorder, disabledBorder), all `kRadius`; `contentPadding: EdgeInsets.symmetric(horizontal: kSp16, vertical: kSp16)`

Intentionally **not** wired (see Findings):
- `SwitchTheme` — M3 Switch is pill-shaped by default; forcing `kRadius` would make it squarish.
- `BottomNavigationBarTheme` — current `home_screen` uses legacy M2 `BottomNavigationBar`; the M3 `NavigationBarThemeData(kRadius * 2)` is forward-looking and harmless but won't apply until migration.

### M3TextField fillColor conflict — resolved

`PDTextField` used to set `fillColor: onPrimary` directly on its `InputDecoration`, silently overriding the `Theme` wrapper's `inputDecorationTheme(fillColor: surfaceContainerHighest)`. Borders worked because `PDTextField` doesn't set explicit borders.

Fix landed: `PDTextField` now has an `m3Style` flag. In M3 mode, `fillColor: null` lets the global `inputDecorationTheme` win. `M3TextField` is the simplified wrapper that just passes `m3Style: true`.

---

## Resolved Decisions

These were the four open disagreements between `DESIGN.md`, `UI_REDESIGN_PLAN.md`, `theme.dart`, and `main.dart`. All resolved.

### 1. Typography — `DESIGN.md` is the source of truth

`UI_REDESIGN_PLAN.md` says `headlineLarge: 32sp / Medium: 28sp / Small: 24sp`. `DESIGN.md` says **28 / 24 / 20**. M3 default Typography is 32 / 28 / 24. The live code (`main.dart:107,123`) builds `ThemeData(colorScheme: …)` with **no** `textTheme`, so it uses M3 defaults.

**Resolution:** Follow `DESIGN.md`.

- `headlineLarge` = 28sp (Screen titles)
- `headlineMedium` = 24sp (Section headers)
- `headlineSmall` = 20sp (Card titles)
- `titleLarge` = 18sp Medium (Input labels)
- `titleMedium` = 16sp Medium (Field labels)
- `bodyLarge` = 16sp Regular (Body)
- `bodyMedium` = 14sp Regular (Secondary text)
- `bodySmall` = 12sp Regular (Helper/error)
- `labelLarge` = 14sp Medium (Button text)
- `labelSmall` = 11sp Medium (Badge text)
- Table values: 14sp Medium monospace
- Chart axis labels: 12sp Regular monospace

**Action:** Update `main.dart` to construct a `TextTheme` from `DESIGN.md` and pass it to both `theme:` and `darkTheme:` as `ThemeData(textTheme: …, colorScheme: …)`. Do **not** route through the `MaterialTheme(textTheme)` constructor in `theme.dart:7` — it's dead code (see Finding 6). Pass the `TextTheme` directly to `ThemeData`.

### 2. Color scheme — current primary as seed, `fromSeed()` everywhere

`DESIGN.md` specifies explicit hex values per token for both dark and light schemes (GitHub-dark palette: `#0D1117`, `#161B22`, `#58A6FF`, …). The live `theme.dart` `darkScheme()` does **not** match this palette — it looks like an M3-generated scheme from a *teal* seed (dark `primary = 0xFF86D6BF`).

**Resolution:** Keep the **current primary** as the seed (the user chose this over the `DESIGN.md` hex). Capture the seeds as named constants; replace the 6 hand-rolled `ColorScheme` factories with `ColorScheme.fromSeed(...)` calls. The 4 contrast variants then come for free via `ColorScheme.fromSeed(seed, brightness, contrastLevel: …)`.

Seeds (extracted from current `theme.dart`):

| Mode | Seed | Use |
|---|---|---|
| Light | `Color(0xFF0D6B58)` | `ColorScheme.fromSeed(seedColor: kSeedLight, brightness: Brightness.light)` |
| Dark | `Color(0xFF86D6BF)` | `ColorScheme.fromSeed(seedColor: kSeedDark, brightness: Brightness.dark)` |

Both seeds added to `lib/config/design_tokens.dart` as `kSeedLight` and `kSeedDark`. The hand-rolled `lightScheme()`, `lightMediumContrastScheme()`, `lightHighContrastScheme()`, `darkScheme()`, `darkMediumContrastScheme()`, `darkHighContrastScheme()` factories (lines 9–337 of `theme.dart`, ~330 lines) are replaced with one-liners that call `ColorScheme.fromSeed(seedColor: kSeedLight/Dark, brightness: …, contrastLevel: …)`.

This **diverges from `DESIGN.md` hex values** — the app will continue to render in the current teal palette, not the `DESIGN.md` blue palette. Decision logged here so it's explicit. Future work (separate spec) can re-anchor the seeds on `DESIGN.md:151–186` if desired.

The 4 contrast variants stay M3-algorithm-derived. Drug colors in `DESIGN.md:189–196` are unchanged — already correct in code (per `CLAUDE.md` "Drug Color System" notes).

### 3. Spacing token coverage — accept the gap

`DESIGN.md` defines `kSp2/4/8/12/16/24/32`. Real `EdgeInsets.` in the codebase includes values outside this scale: `0`, `14`, `18`, `20`, `48` (for `scrollPadding`), `2` (button offset), etc.

**Resolution:** The scale is the *design* scale. Layout-specific one-offs (button offsets, scroll padding, intra-icon spacing) stay as literals. Migrate only the spacing that fits a token; don't force-fit.

### 4. `kRadiusSm = 4` — keep, flag for review

`DESIGN.md:252` says "Chips/Badges: `kRadiusSm` (4dp)". M3 default is 4dp for chips. The codebase doesn't currently use any 4dp radii, but the spec calls for them.

**Resolution:** Keep `kRadiusSm = 4.0`. Use it for chips/badges when they're added. If no chips/badges are added in the next two phases, revisit.

---

## Migration Plan

### Phase A — Done ✓

1. ✓ Created `lib/config/design_tokens.dart`
2. ✓ Wired M3 component themes in `lib/theme.dart` using tokens
3. ✓ Added `m3Style` flag to `PDTextField`; simplified `M3TextField` wrapper
4. ✓ `settings_screen_m3.dart` uses tokens

### Phase B — Open (small, safe)

1. **Trim `m3_dropdown_menu.dart` local theme overrides.** The file has its own `inputDecorationTheme` override on the `DropdownMenu` widget (5 sites of `kRadius` + duplicated border/fill definitions, lines 211–235) and its own `menuStyle` + `snackbar.shape` (lines 236–246, 329). The global `inputDecorationTheme` from `theme.dart` already provides borders/fill. **Verify first** by `flutter run` — `DropdownMenu` takes a *local* `inputDecorationTheme` parameter that is not a global theme, so the global may not reach it. If global does not reach, keep the local but reduce duplication by reading the same fields from a shared helper.
2. **Consolidate the 3 copies of `_getResponsiveHeight()`.** `PDTextField.dart:63–89`, `m3_dropdown_menu.dart:162–186`, and a similar helper in `adaptive_dropdown.dart` all implement the same 56/60/64 × textScale (clamp 1.0–1.5) formula. Extract to a single `lib/utils/responsive_height.dart` (or add to `design_tokens.dart` / a new `lib/utils/responsive.dart`).
3. **Remove `kRadiusSm` warning if unused after Phase B.** Skip if any chip/badge code is added.

### Phase C — Deferred to per-screen M3 migration

Per `M3_MIGRATION_SPEC.md`, each screen replaces hardcoded values with tokens as it's migrated. Legacy screens keep their hardcoded values until migrated.

Migration targets (when each screen is touched):

| File | Targets | Notes |
|---|---|---|
| `lib/widgets/PDLabel.dart` | `BorderRadius.circular(8.0)` → `kRadius` | 1 site |
| `lib/widgets/PDStyledLabel.dart` | `BorderRadius.circular(8.0)` → `kRadius` | 1 site |
| `lib/components/adaptive_dropdown.dart` | 2 sites of `BorderRadius.circular(8)` | Mostly legacy fallback paths |
| `lib/screens/m3_test_screen.dart` | 3 sites (`8`, `12`) | Demo screen, low risk |
| `lib/screens/m3_test_screen_simple.dart` | 2 sites | Demo screen, low risk |
| `lib/screens/realtime_screen.dart` | `BorderRadius.circular(6)` → `kRadius` | 1 site (intentional or bug?) |
| `lib/constants.dart` | `horizontalSidesPaddingPixel = 16.0` → `kSp16` | 1 site |

**Do not touch** (per `M3_MIGRATION_SPEC.md` safety boundary):

- `lib/models/*` — calculation logic
- `lib/providers/settings.dart` — only property reads
- `lib/components/infusion_regime_table.dart` — already M3-compatible; hardcoded `5` and `8` radii are intentional for table-cell rounding
- `lib/components/legacy/PDModelSelectorModal.dart` — legacy modal; migration is structural, not just token swap

**Debounce vs animation — Finding 4 confirmed.** All 500ms `Duration` usages in `volume_screen.dart` and `volume_plus_screen.dart` are calculator debounce delays, not animations. Use `kDebounce`. The 50ms and 25ms usages are local timing (button press feedback, table interpolation ticks) and should stay as literals.

### Phase D — Open (animation polish)

The app currently has **no transition animations**. Every `Navigator.push` uses the default `MaterialPageRoute` (theme-driven fade-through on M3, but invisible to the user), every tab swap in `home_screen.dart` is an instant `setState` rebuild with no `AnimatedSwitcher`, and the only `AnimatedSwitcher` in the codebase (`collapsible_input_card.dart:203`) is for child-swap, not screen transitions.

`DESIGN.md:291–299` defines an animation vocabulary that is **not** implemented:

| Element | Duration | Curve | Status |
|---|---|---|---|
| Card expand/collapse | `kAnimNormal` (300ms) | `easeInOutCubic` | ✓ Implemented (`collapsible_input_card.dart:79`) |
| Content fade | `kAnimFast` (200ms) | `easeInOut` | ✗ Not implemented |
| Tab switch | `kAnimFast` (200ms) | `easeInOut` | ✗ Not implemented |
| Button press | 50ms | Immediate | ✗ Not implemented |
| Validation error | `kAnimFast` (200ms) | `easeInOut` | ✗ Not implemented (errors appear instantly) |

Phase D adds the missing pieces, using the existing `kAnimFast` / `kAnimNormal` tokens and standard `Curves.easeInOut` / `easeInOutCubic`.

**D.1 — Tab-switch fade (mobile + web layouts)**

`home_screen.dart:88` (`_buildMobileLayout`) and `home_screen.dart:179` (`_buildWebLayout`) currently render `screens[currenIndex]` directly. Wrap each in an `AnimatedSwitcher` keyed by the screen identity so a tab swap fades the new screen in over the old.

```dart
// In both _buildMobileLayout and _buildWebLayout
AnimatedSwitcher(
  duration: kAnimFast,
  switchInCurve: Curves.easeInOut,
  switchOutCurve: Curves.easeInOut,
  child: KeyedSubtree(
    key: ValueKey('screen-$currenIndex'),
    child: screens[currenIndex],
  ),
)
```

**Why:** Tab switches become visible content transitions rather than instant repaints. Matches `DESIGN.md:297` (tab switch = `kAnimFast` `easeInOut`). Same animation for both mobile and web layouts — consistency.

**Caveat:** `AnimatedSwitcher` rebuilds the new child with a fresh `State` on each switch. The current `screens[currenIndex]` returns a *new* widget instance per build (e.g. `TCIScreen()`, `VolumeScreen()`), so the existing internal `initState` lifecycle already pays this cost. No new perf concern. If a screen later wants to preserve state across tabs, switch to `IndexedStack` + `AnimatedSwitcher` overlay (skip for now — deferred to `M3_MIGRATION_SPEC.md`).

**D.2 — Page route transitions (any future `Navigator.push`)**

Today the app has no `Navigator.push` to a full screen — only `Navigator.pop` from modals. But the spec should set the convention now. Wrap `MaterialApp` in `home_screen.dart`'s parent (`main.dart`) with a `pageTransitionsTheme`:

```dart
// In main.dart
theme: ThemeData(
  colorScheme: lightScheme,
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: {
      TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
    },
  ),
)
```

**Or** more idiomatically: rely on M3's default `FadeForwardsPageTransitionsBuilder` (which is what M3 ships with `useMaterial3: true`). Verify in `flutter run` that the current default is the M3 fade-through; if so, no code change needed — just document that any future `Navigator.push` uses the M3 default.

**D.3 — Snackbar slide-in**

`m3_dropdown_menu.dart:332` has a snackbar with `Duration(seconds: 3)` (literal, not a token). `DESIGN.md:295–298` doesn't explicitly call out snackbar animation, but the M3 default snackbar slides in from the bottom. Verify it's the default; if not, add `behavior: SnackBarBehavior.floating` (which is the M3 default look — line 328 already has it) and let M3 handle the slide.

**D.4 — List reorder (TCI drug selector / volume mode)**

`settings_screen_m3.dart` and `tci_screen.dart` use `SegmentedButton` for selections. No list reorder needed there. But if a future "favourite drugs" or "saved patient profiles" feature is added, use `AnimatedList` or `ReorderableListView` with `kAnimFast`. **Out of scope** for this phase; flag as future work.

**D.5 — Hero transitions**

Where a tap on a summary line should expand into the full input card (and back), use `Hero` with matching `tag` strings. Candidate: `collapsible_input_card.dart` could hero its header into a bottom-sheet expansion, but only if UX justifies it. **Out of scope** for this phase; flag as future work.

**D.6 — Button press feedback**

`DESIGN.md:298` says "Button press: 50ms, immediate". The codebase already has `HapticFeedback.heavyImpact()` and `.lightImpact()` on tab tap (`home_screen.dart:96,137`). For visual press feedback on `FilledButton` / `OutlinedButton`, use the M3 default ink-well response (built-in). For the legacy `PDTextField` stepper +/- buttons, add a `TweenAnimationBuilder<double>` that scales the icon to 0.95 over 50ms on press, then back to 1.0 on release. **Small, isolated** — file under `lib/components/legacy/PDTextField.dart`.

**D.7 — Validation error appearance**

`PDTextField` currently shows `errorText` immediately on validation failure. Wrap the `errorText` widget in an `AnimatedSwitcher` keyed by the error string, with `kAnimFast` `easeInOut` — error text fades in. **Small, isolated** — same file as D.6.

**D.8 — Token additions for animation**

If `kAnimFast` and `kAnimNormal` are used in many more places after D.1–D.7, consider adding `kAnimSlow = Duration(milliseconds: 500)` for "long-form" transitions (page enter, dialog open). **Defer** — the 500ms duration in `volume_screen` / `volume_plus_screen` is a debounce, not an animation. If a real 500ms animation ever ships, add `kAnimSlow` then.

**Order of execution (smallest blast radius first):**

1. D.1 (tab-switch fade) — touches `home_screen.dart` only.
2. D.2 (verify M3 page transition default) — verify with `flutter run`, no code change if default is correct.
3. D.6 + D.7 (button + error polish) — touches `PDTextField.dart` only.
4. D.3 (snackbar) — verify default, no code change if correct.
5. D.4 + D.5 (list reorder / hero) — **deferred** — no current feature requires them.

---

## Usage Convention

```dart
// ✅ DO — use tokens
SizedBox(height: kSp16)
BorderRadius.circular(kRadius)
EdgeInsets.symmetric(horizontal: kSp16, vertical: kSp12)
duration: kAnimNormal
fontSize: 28  // per DESIGN.md typography table (no token needed; the table is the spec)

// ❌ DON'T — hardcode literals for design-scale values
SizedBox(height: 16)
BorderRadius.circular(8)
EdgeInsets.symmetric(horizontal: 16, vertical: 12)
duration: Duration(milliseconds: 300)
```

Tokens cover the *design* scale. Layout-specific one-offs (button offsets of 2dp, scroll padding of 48dp, intra-icon spacing of 6dp) remain as literals — the design token scale is not a replacement for layout math.

---

## Self-Review: Risks & Findings

### Finding 1: M3TextField fillColor is silently ignored — **RESOLVED** ✓
`PDTextField` set `fillColor: onPrimary` directly on `InputDecoration`, silently overriding the Theme wrapper's `inputDecorationTheme(fillColor: surfaceContainerHighest)`. Borders worked because `PDTextField` doesn't set explicit borders. **Fix:** `m3Style` flag on `PDTextField`; in M3 mode, `fillColor: null` lets the global theme win. Merged.

### Finding 2: switchTheme override would make Switch look wrong — **RESOLVED** ✓
M3 Switch is pill-shaped by default. Forcing `BorderRadius.circular(kRadius)` would make it squarish. **Removed from spec.** ✓

### Finding 3: BottomNavigationBar not NavigationBar — **DEFERRED** ⏸
Current `home_screen` uses legacy M2 `BottomNavigationBar`. The `NavigationBarThemeData` in spec is forward-looking. **Will apply when `home_screen` migrates to M3 `NavigationBar` (per `M3_MIGRATION_SPEC.md`).**

### Finding 4: `kDebounce` correctly separates from animation — **RESOLVED** ✓
The 500ms usages are debounce delays (calculator debouncing), not animations. `kDebounce` introduced. The 50ms and 25ms usages are local timing and stay as literals.

### Finding 5: `kRadiusSm = 4` may be unused — **MONITOR**
Legacy components use `5`, not `4`. M3 doesn't use 4px radius except on chips/badges. Keep `kRadiusSm` for chips/badges per `DESIGN.md:252`; remove if still unused after Phase B + two screen migrations.

### Finding 6 (NEW): `MaterialTheme` constructor is dead code, and gets deader
`MaterialTheme(textTheme)` is declared in `theme.dart:7` but never instantiated. `main.dart:107,123` calls the *static* `MaterialTheme.lightScheme()` / `darkScheme()` and builds `ThemeData(colorScheme: …)` with no `textTheme` and no `textTheme` factory call. The `theme(ColorScheme)` function in `theme.dart:340–401` is also dead at runtime — and would NPE on `textTheme.apply(...)` if called.

After Resolved Decision §2 (replace 6 hand-rolled factories with `fromSeed()` one-liners), `MaterialTheme` becomes essentially a 6-line static-method holder with no constructor work. The `MaterialTheme(textTheme)` constructor is still dead. **Action:** Drop the `textTheme` constructor; the typography work (Finding 8) is done in `main.dart` as `ThemeData(textTheme: …)`. Or: rename `MaterialTheme` to `AppColorScheme` to make its scope clear. Pick one before Phase B ships.

### Finding 7 (NEW): Color drift between `DESIGN.md` and `theme.dart` — RESOLVED as a decision
`DESIGN.md` specifies a GitHub-dark blue palette (`#0D1117` surface, `#58A6FF` primary, …). `theme.dart` `darkScheme()` uses a teal palette (`primary = 0xFF86D6BF`). **Decision (Resolved §2):** keep the current teal as the seed, do not migrate to the `DESIGN.md` blue. The drift is no longer a bug — it's an explicit divergence. Logged here so any future reader knows why `DESIGN.md` and the live app disagree. Re-anchoring the seed on `DESIGN.md:151–186` is future work, not in any current phase.

The 6 hand-rolled `ColorScheme` factories in `theme.dart:9–337` are **deleted** and replaced with `ColorScheme.fromSeed(seedColor: kSeedLight/kSeedDark, brightness: …, contrastLevel: …)`. This removes ~330 lines of hand-coded colour values.

### Finding 8 (NEW): Typography drift between `DESIGN.md` and runtime
M3 default Typography has `headlineLarge = 32sp`. `DESIGN.md` says 28sp. `main.dart` doesn't pass a `textTheme`, so the app uses M3 defaults — meaning the live UI has *bigger* screen titles than `DESIGN.md` specifies.

**Action:** Construct a `TextTheme` from `DESIGN.md:201–217` and pass it to `ThemeData` (see Finding 6).

### Finding 9 (NEW): `kRadius = 8` is M3 default — no behaviour change for the `inputDecorationTheme` border
The M3 default `OutlineInputBorder` already uses 8dp corners. Wiring `borderRadius: BorderRadius.circular(kRadius)` in `theme.dart:374–394` is technically a no-op (it matches M3 default). **Keep it** for explicitness and to defend against future M3 default changes — but recognise it doesn't change current rendering.

### Finding 10 (NEW): `kAnimNormal` (300ms) has only one call site
`kAnimNormal` is defined in `design_tokens.dart:24` and used in `collapsible_input_card.dart:73` for the card expand/collapse animation, matching `DESIGN.md:295` ("Card expand/collapse: `kAnimNormal` (300ms) `easeInOutCubic`"). The other 300ms usages in `infusion_regime_table.dart` are paired with `Curves.easeInOutCubic` for table interpolation; these are functional timing, not design-system animation. Leave as literals.

### Finding 11 (NEW): No widget tests cover any M3 component
None of `m3_text_field.dart`, `m3_dropdown_menu.dart`, `collapsible_input_card.dart`, `settings_screen_m3.dart`, or any of the new token-driven code have widget tests. For a medical app this is a quality gap, not a blocker for this spec. **Action:** Flag as follow-up work; not part of any phase here.

### Finding 12 (NEW): `kRadiusSm = 4` is also M3 default for chips — same as Finding 9
M3 default chip shape is already 4dp stadium. Wiring it explicitly doesn't change rendering but documents intent.

---

## Verification

After Phase A (already done):

1. ✓ `dart analyze lib/` — zero errors
2. ⏳ `flutter run -d macos` — visual check of Settings screen
3. ✓ All M3 components use `kRadius` (8.0) consistently
4. ✓ All spacing uses `kSp*` tokens consistently

After Phase B (open work):

1. `dart analyze lib/` — zero errors
2. `flutter run -d macos` — visual check of dropdown menu (verify global theme reaches it; if not, keep local override but reduce duplication)
3. Confirm `_getResponsiveHeight()` has only one implementation

After Resolved Decision §1 (typography) and §2 (colour from seed):

1. `dart analyze lib/` — zero errors
2. `flutter run -d macos` dark + light — visual diff confirms teal palette unchanged
3. `flutter run -d macos` — verify screen titles (`headlineLarge`) render at 28sp, not 32sp
4. Verify `theme.dart` lost ~330 lines (6 hand-rolled factories → 6 one-liners)

After Phase D (animation polish):

1. `flutter run -d macos` — tap between tabs, verify fade visible
2. `flutter run -d macos` — toggle input field validation, verify error text fades in
3. `flutter run -d macos` — verify M3 default page transitions are fade-through (no extra code needed)
4. `dart analyze lib/` — zero errors

After Phase C (per-screen, deferred to M3 migration):

1. `rg "BorderRadius\.circular\(([0-9])" lib/` — should return only calls inside legacy components marked "do not touch" (`infusion_regime_table.dart`, `PDModelSelectorModal.dart`)
2. `rg "Duration\(milliseconds: 200\)|Duration\(milliseconds: 300\)|Duration\(milliseconds: 500\)" lib/` — should return only token definitions
