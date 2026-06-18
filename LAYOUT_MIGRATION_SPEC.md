# Layout Migration Spec

## Status

| Sub-phase | Description | State |
|---|---|---|
| L0 | Breakpoint reconciliation + shell scaffolding | **Open — must-do first** |
| L1 | `AppBar` in `home_screen.dart` showing current screen name | **Open — zero risk** |
| L2 | Reduce bottom nav to spec-compliant 5 tabs | **Open — small** |
| L3 | 2-column tablet layout (input sidebar + results) | **Open — first real test** |
| L4 | 3-column desktop layout (drawer + input + results) | **Open — bigger change** |
| L5 | Status bar (model / drug / pump info) | **Open** |
| L6 | Keyboard shortcuts (Enter = calculate, Tab between fields) | **Open** |
| L7 | Web max-width 1440px + print styles | **Open — last** |

This spec migrates **one screen at a time** so any sub-phase can be rolled back in a single commit. Each sub-phase ships as its own commit + PR, with the **rollback strategy** spelled out at the end of the sub-phase.

---

## Background

`DESIGN.md:13–143` defines a 3-tier responsive layout (mobile / tablet / desktop / web) with specific column counts, navigation patterns, and shell chrome. The live code (`lib/screens/home_screen.dart`, `lib/utils/responsive_helper.dart`) only implements **2 layouts**: a mobile single-column + bottom-nav, and a web/tablet rail + content. Roughly 75% of the spec is missing.

The pieces are partly in place: `lib/components/adaptive_layout.dart` already defines `AdaptiveLayout`, `ResponsiveContainer`, `ResponsiveRow`, `ResponsiveGrid` — none of which are used by `home_screen.dart` or any active screen. `responsive_helper.dart` already exposes `isMobile`/`isTablet`/`isDesktop` at 768/1024 breakpoints.

The `CollapsibleInputCard` component (`lib/components/collapsible_input_card.dart`) is built but only used in `realtime_screen.dart` and the dead `tci_screen_new.dart`. The active `tci_screen.dart` uses inline widgets.

### Spec vs code discrepancies (must be fixed in L0)

1. **Breakpoint values disagree.** `DESIGN.md:19–22` says mobile < 600px, tablet 600–1024px, desktop > 1024px. `responsive_helper.dart:9–10` uses 768px and 1024px. The code's 768px boundary is **silently wrong** vs the design spec. **Resolution:** Update `DESIGN.md` to match the code (768/1024 is the de-facto standard for M3 apps, and the existing `ResponsiveHelper` already documents it). Don't change the code — it would invalidate layouts on iPad portrait and break existing tests. Update `DESIGN.md:19–22` in L0.

2. **Bottom nav has 7 tabs, spec says 5.** `home_screen.dart:101–122` shows EleMarsh, TCI, Volume, Duration, Settings, M3 Lab, Real-Time. `DESIGN.md:59` shows [TCI] [Vol] [Dur] [ElM] [⚙]. The M3 Lab and Real-Time tabs are extra. **Resolution:** M3 Lab is a demo screen, move it to a hidden route. Real-Time is a TCI feature, merge it into the TCI screen as a mode toggle. Done in L2.

3. **`DESIGN.md` has no `AppBar` requirement, but the mock-ups show one.** All three mobile/tablet/desktop mock-ups (`DESIGN.md:30, 73, 105`) include an `AppBar` with the screen title. `home_screen.dart` has no `appBar` property. **Resolution:** Add `AppBar` showing the current screen's localized name. Done in L1.

4. **`CollapsibleInputCard` is the spec's input pattern, but the active TCI screen doesn't use it.** The "Collapsible Input Card" section in `DESIGN.md:259–272` describes the input as collapsing. `tci_screen.dart` has no card wrapper at all. **Resolution:** Wire `CollapsibleInputCard` into each screen during its migration sub-phase.

---

## L0 — Breakpoint reconciliation + shell scaffolding (must-do first)

**Goal:** align spec and code on breakpoints, then create the shell that all subsequent sub-phases plug into. Zero user-visible change.

**⚠ Bigger problem than the original L0 description:** the codebase has **4 competing breakpoint systems** in active use:
1. `lib/utils/responsive_helper.dart:9–10` — width 768 (mobile) / 1024 (desktop) — used by `home_screen.dart`.
2. `lib/components/collapsible_input_card.dart:296–319` — width 600 (mobile) / 840 (tablet) / 1200 (desktop) — used by `CollapsibleInputCard.getCollapsedHeight()`.
3. `lib/components/input_summary_display.dart:9–13` — width 600 (mobile) only — used by `InputSummaryDisplay`.
4. `lib/constants.dart:72–73` — `screenBreakPoint1 = 704` / `screenBreakPoint2 = 992` — *height-based*, used by `duration_screen.dart:182, 184, 236`.

Plus 2 hardcoded `840` literals in `realtime_screen.dart:37, 494, 609, 670` (uses `_kBreakpointWide`) and `tci_screen_new.dart:302, 620` (uses raw `840`). After L3/L4, these internal checks will conflict with the home screen's breakpoint decisions (e.g. at 768–839px the home thinks "tablet" but the realtime screen thinks "mobile" because 768 < 840).

**Touch:**
- `DESIGN.md:19–22` — update mobile boundary to < 768px (match code).
- `lib/utils/responsive_helper.dart` — no changes to existing 768/1024 values.
- **Add a single source of truth:** create `lib/config/breakpoints.dart` with `kMobileMax = 768, kTabletMax = 1024, kDesktopMin = 1024` constants. Replace all 4 systems above to import from this file.
  - `responsive_helper.dart` → import breakpoints, replace `_mobileBreakpoint` / `_desktopBreakpoint`.
  - `collapsible_input_card.dart:297–299` → import breakpoints, replace `600` / `840` / `1200`. **Decision needed:** what should the card's "tablet" range be after consolidation? Recommend keeping the card's 600/1024/1200 (wider mobile zone) because the card is a focused component, not a layout — but the spec must pick.
  - `input_summary_display.dart:11` → import breakpoints, replace `600`.
  - `constants.dart:72–73` → keep separate (height-based), but rename to `kMobileHeightMax`, `kTabletHeightMax` to clarify they are *height* breakpoints, not *width*.
  - `realtime_screen.dart:37` → replace `_kBreakpointWide = 840` with `kMobileMax` (or add a `kTCITabletMin` if 840 was deliberately different).
- `lib/screens/home_screen.dart` — extract `_buildShell(...)` helper that takes a `Widget body` and wraps it with the existing bottom nav / nav rail. Both `_buildMobileLayout` and `_buildWebLayout` call it. Pure refactor, no behaviour change.

**Why first:** every other sub-phase adds a new layout variant that needs to be selectable by the same breakpoint logic. Lifting the shell now means L3/L4 plug in cleanly. Consolidating breakpoints now means the internal `MediaQuery.of(context).size.width < 840` checks in realtime/tci_screen_new don't fight the home screen's 768/1024 decisions in L3/L4.

**Rollback:** `git revert <L0-commit>`. The shell refactor and breakpoint consolidation are internal — no UI change means nothing for users to notice (assuming the consolidation picks values that match current behaviour, which requires QA on each screen).

---

## L1 — `AppBar` in `home_screen.dart`

**Goal:** add an `AppBar` to the mobile + web layouts showing the localized name of the current screen.

**Touch:** `lib/screens/home_screen.dart` + 4 per-screen files.
- `lib/screens/home_screen.dart`:
  - Add `appBar: AppBar(title: Text(_titleFor(currenIndex, context)), actions: _actionsFor(currenIndex, context))` to both `Scaffold`s. The `actions: []` parameter is set up here so L2 can extend it (see Finding 22).
  - Add `_titleFor(int index, BuildContext context)` mapping the 6 current indices to `AppLocalizations.of(context)!` strings (TCI / Volume / Duration / Settings / EleMarsh / Real-Time / M3 Lab).
  - Add `_actionsFor(int index, BuildContext context)` returning an empty list for now (L2 will add the TCI Real-Time toggle and the M3 Lab M3/Legacy toggle).
  - For mobile, prefer a small AppBar; for web, can be larger.
- `lib/screens/settings_screen_m3.dart:103–107` — remove the inline `AppBar` and the `SizedBox(height: kSp16)` that follow it. The `Column` becomes just `[Expanded(child: ...)]` (the AppBar is now provided by the home `Scaffold`).
- `lib/screens/settings_screen.dart:170–176` — same: remove inline `AppBar` and `SizedBox(height: kSp16)`.
- `lib/screens/m3_test_screen.dart:100–101` — has `Scaffold(appBar: AppBar(title: ..., actions: [...]))`. The `actions` list contains an "M3 / Legacy" toggle (`m3_test_screen.dart:104–113`). **⚠ L1 cannot cleanly migrate this toggle to the home AppBar's `_actionsFor()`** — after L2, M3 Lab is no longer in the nav (no `currenIndex` for it). The toggle must live inside `M3TestScreen` itself. Two sub-options:
  - (a) Keep the inner `Scaffold.appBar` in `M3TestScreen`. Accept that opening M3 Lab shows a double-AppBar (the home's empty AppBar + the screen's AppBar with the toggle). L1's `home_screen.dart` does not need to do anything special for M3 Lab.
  - (b) Move the M3/Legacy toggle into `M3TestScreen`'s body content (e.g. as a `SegmentedButton` or `Switch` row at the top of the body). Then L1's AppBar removal is safe (M3 Lab has no AppBar at all when accessed via Settings).
  - **Recommend (b)** — avoids double-AppBar and keeps M3 Lab visually consistent with the other screens.
- `lib/screens/m3_test_screen_simple.dart:126` — dead code, no action needed (won't ship).
- The `m3_test_screen.dart` migration is **non-trivial** because the M3/Legacy toggle's logic is inside the screen's `actions` widget. L1 should either (a) keep the screen's `Scaffold.appBar` with the toggle, or (b) move the toggle to the screen body. **Recommend (b)** — keeps the toggle visible and avoids the double-AppBar issue.

**Behaviour change:** every screen now has a 56dp (mobile) or 64dp (web) header bar above its content. This is **the most visible change in the whole spec** — verify it doesn't break scroll-offset persistence in the dosage table.

**⚠ Risk: double-AppBar on screens that already have their own.** `settings_screen_m3.dart:104`, `settings_screen.dart:171`, `m3_test_screen.dart:101`, `m3_test_screen_simple.dart:126` each have their own `AppBar`. If L1 adds a home AppBar without removing these, the user sees two AppBars stacked. **Resolution:** the L1 PR removes the per-screen `AppBar` from 3 active files (the 4th is dead code) and migrates the M3/Legacy toggle to the home AppBar's `actions:`. For `settings_screen_m3.dart` and `settings_screen.dart`, also remove the `SizedBox(height: kSp16)` that follows the inline AppBar (it was compensating for the inline AppBar's height). For `m3_test_screen.dart`, move the toggle but keep the screen's `Scaffold` (since it has its own `Scaffold`, the home `Scaffold` is the parent — see ⚠ below).

**⚠ Risk: nested Scaffolds in m3_test_screen.** `m3_test_screen.dart:100` has its own `Scaffold`. `home_screen.dart:75, 130` also has `Scaffold`s. Nested Scaffolds in Flutter are technically allowed but can produce unexpected layout (e.g. the inner `Scaffold` consumes a `MediaQuery` that the outer one expected to see, the inner `Scaffold` is the only one with a `BottomNavigationBar` even on mobile, etc.). The current code works because the inner Scaffold is a child of the body, not the chrome. **Action for L1:** if L1 removes the inner `appBar` from `m3_test_screen.dart`, consider whether the inner `Scaffold` is still needed at all (it has no `bottomNavigationBar` and no other chrome). If not, flatten to a `Container` or `Column`. If the inner `Scaffold` is needed for `floatingActionButton` or other chrome, keep it. Verify in `flutter run`.

**Verify:**
- Scroll to bottom of TCI results, switch to Settings, switch back to TCI — scroll position should restore (`tci_screen.dart:106–117` saves and restores via `settings.dosageTableScrollPosition`).
- All 3 active screens that had their own AppBar (`settings_screen.dart`, `settings_screen_m3.dart`, `m3_test_screen.dart`) now have only the home AppBar. The 4th (`m3_test_screen_simple.dart`) is dead code.
- For `m3_test_screen.dart`: the M3/Legacy toggle still works (now in the screen's own body, per option (b) above). The home `AppBar`'s `_actionsFor()` is reserved for L2's TCI Real-Time toggle.
- No double-AppBar visual artifact in the 3 affected screens.
- No nested-Scaffold layout artifacts (test by switching between tabs and verifying the body fills the available space correctly).

**Rollback:** `git revert <L1-commit>`. The AppBar is purely additive — removing it restores the current look. The only thing that could break is the scroll-offset restoration if the AppBar changes the available height; if so, the issue is in the offset math, not the AppBar, and would surface in QA.

---

## L2 — Reduce bottom nav to 5 tabs

**Goal:** move the 2 extra tabs (M3 Lab, Real-Time) out of the bottom nav.

**Touch:**
- `lib/screens/home_screen.dart:101–122` — remove the 2 extra `BottomNavigationBarItem`s (M3 Lab, Real-Time) from the mobile nav.
- `lib/screens/home_screen.dart:144–173` — remove the same 2 destinations from the web `NavigationRail`.
- For M3 Lab: the app currently has **no routing system** — `main.dart:125` uses `home: const HomeScreen()` and there's no `onGenerateRoute` or `routes:`. Adding a hidden route is a bigger lift than the L2 description implies.
  - **Approach:** add a new section to `settings_screen_m3.dart` (after the existing list, before the closing `]`) that contains a "Material 3 Test Lab" `ListTile` with `onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const M3TestScreen()))`.
  - **Scope correction:** the spec originally said "10 lines". The settings screen has no `ExpansionTile` or section headers today (just a flat `ListView` of widgets) — adding an "About" section with a styled header is closer to **30–40 lines** of new code. The L2 PR is bigger than originally implied.
- For Real-Time: add a toggle inside the TCI screen (e.g. a `SegmentedButton` in the AppBar with "Standard" / "Real-Time" modes). When toggled to Real-Time, the TCI screen renders the existing `realtime_screen.dart` content in place. **The toggle is rendered in the home `AppBar`'s `_actionsFor()` (set up in L1), conditional on `currenIndex == 1` (TCI).** This is the L1 + L2 interaction called out in Finding 22 — L1 must set up `_actionsFor()` returning `[]` initially so L2 can add the toggle without refactoring L1.
- Update `Settings._currentScreenIndex` valid range from `[0..6]` to `[0..4]`. Add a clamp on read/write so any persisted value `> 4` falls back to `1` (TCI). **Note:** the runtime default in `home_screen.dart:26` is `1` (TCI), but the persisted default in `settings.dart:1036` is `0` (EleMarsh). On first launch, the widget overrides to 1, but if the persisted value is later read as 0 and the nav has only 5 items, the EleMarsh index (0) is still valid. **Verify** both runtime and persisted defaults are sane after L2.
- **Migrate the M3/Legacy toggle from `m3_test_screen.dart`'s AppBar `actions` to the screen body content** (as a `SegmentedButton` or `Switch` row). After L2, M3 Lab is no longer a nav destination, so the home AppBar's `_actionsFor()` can't host the toggle. The toggle moves *into* `m3_test_screen.dart`'s body. If L1 already did this (it should have, per L1's instructions), L2 is a no-op here. If L1 kept the inner `Scaffold.appBar` to preserve the toggle, L2 removes the inner `appBar` and moves the toggle to the body as part of the M3 Lab cleanup.

**Behaviour change:** mobile users see [EleMarsh] [TCI] [Vol] [Dur] [Settings] instead of 7 tabs. M3 Lab is reachable via Settings → "Material 3 Test Lab". Real-Time is a mode on the TCI screen (toggle in the home AppBar).

**Verify:** no broken routing, `settings.currentScreenIndex` always within `[0..4]`, no test references the 7-tab layout (per CLAUDE.md, no widget tests exist for `home_screen.dart`).

**Rollback:** `git revert <L2-commit>`. The 7-tab layout is restored.

---

## L3 — 2-column tablet layout (input sidebar + results)

**Goal:** on tablet (768–1023px), the screen body becomes a 2-column `Row`: input sidebar (left, fixed width) + results (right, flex). Mobile stays 1-column. Desktop stays rail+content (until L4).

**Touch:** per-screen. **Migrate one screen at a time.**

For each screen in priority order:
1. **TCI** (`lib/screens/tci_screen.dart`) — most important, primary screen.
2. **Volume** (`lib/screens/volume_screen.dart` + `lib/screens/volume_plus_screen.dart` — pick one).
3. **Duration** (`lib/screens/duration_screen.dart`).
4. **EleMarsh** (`lib/screens/elemarsh_screen.dart`).
5. **Settings** (`lib/screens/settings_screen_m3.dart`).
6. **Real-Time** (folded into TCI per L2).

For each screen, the migration is:
- Wrap the screen body in `LayoutBuilder` (or use `AdaptiveLayout` from `lib/components/adaptive_layout.dart:6`).
- On mobile (`< 768px`): return the existing body unchanged.
- On tablet (`768–1023px`): return a `Row` with the input section on the left in a `SizedBox(width: 320)` and the results on the right in `Expanded`.
- Use `CollapsibleInputCard` for the input section if not already (replaces the inline input widgets per the spec's "Collapsible Input Card" requirement). **⚠ The card requires both `expandedContent` and `collapsedSummary` widgets.** For TCI, the `collapsedSummary` is a multi-field display. The existing `InputSummaryDisplay` widget (`lib/components/input_summary_display.dart`) supports all of TCI's fields and is the right building block — see Finding 32 for the corrected scope (10-20 lines, not 50-100). For TCI: `collapsedSummary: InputSummaryDisplay(calculatorType: CalculatorType.tci, age: ..., sex: ..., weight: ..., height: ..., drug: ..., model: ..., target: ..., duration: ...)`. **Verify** the `InputSummaryDisplay`'s `_buildDesktopSummary` `Row` lays out within the card's available width on tablet (see Finding 32 note).
- On desktop (`≥ 1024px`): unchanged from L0/L1 (will be replaced in L4).
- **If the screen has its own `AppBar`** (only `settings_screen_m3.dart`, `settings_screen.dart`, `m3_test_screen.dart`, `m3_test_screen_simple.dart` in the current code — none of the L3 priority screens do), remove it; the home AppBar from L1 covers it.

**Verify per screen:** calculator math unchanged (run `flutter test`), scroll position restores, `CollapsibleInputCard` auto-collapses on calculate (see ⚠ below), input fields still validate.

**⚠ Risk: "auto-collapse on calculate" is not wired anywhere in the codebase.** `CollapsibleInputCard` exposes `onCalculate: VoidCallback?` and `onExpansionChanged: ValueChanged<bool>?` but **no caller** programmatically collapses the card. `realtime_screen.dart:285` and the dead `tci_screen_new.dart` both pass `onCalculate: _onCalculate` but `_onCalculate` only calls `calculate()` — it never invokes a collapse method. The card has no public `collapse()` / `expand()` API either (`lib/components/collapsible_input_card.dart:60–319` only has one internal `setState` and no exposed methods). **Action for L3:** add a public `collapse()` and `expand()` method to `CollapsibleInputCard` (use a `GlobalKey<State<CollapsibleInputCard>>` to call them from the screen, or expose a controller class). Then in each screen's `calculate()` success path, call `_inputCardKey.currentState?.collapse()`. The L3 PR is incomplete without this.

**⚠ Risk: L3 TCI's 2-way Standard / Real-Time mode (after L2) means TCI's tablet view needs to render two UIs.** If L2 made Real-Time a mode toggle inside TCI, then L3 TCI's tablet view must support both `tci_screen.dart` body and `realtime_screen.dart` body in the right column. That's per-mode routing inside the screen. Document the approach (e.g. `isRealtime ? RealtimeBody() : TCIBody()`) in the TCI L3 PR.

**Why per-screen:** each screen's input section has different fields, validation, and TCI-specific dynamic UI. Doing them all at once risks breaking 6 things at once and making rollback impossible. One screen per commit, one PR.

**Rollback per screen:** `git revert <L3-TCI-commit>` (or whichever screen). The mobile layout is unchanged. The tablet layout is removed. The other screens keep their old single-column tablet behaviour.

**Suggested order based on user impact:** TCI → Volume → Duration → EleMarsh → Settings → Real-Time. (TCI is the primary screen per CLAUDE.md and the demo target for the App Store screenshots, so getting it right first is the highest-value test.)

---

## L4 — 2-/3-column desktop layout (input panel + results, optionally + drawer)

**Goal:** on wide desktop (≥ 1280px), the screen body becomes a 3-column `Row`: nav drawer (left, collapsible) + input panel (320–420px) + results (flex). On narrow desktop (1024–1279px), the body is 2-column: input panel + results (no drawer — too tight to fit). The 1024px boundary is the spec's "desktop" minimum, but at 1024px the 3-column layout is too cramped (only ~344px for results).

**Touch:** per-screen, same order as L3.

For each screen:
- On **wide desktop (≥ 1280px)**: return a `Row` with a `NavigationDrawer` (or `Drawer` widget with a collapse toggle) on the left (`DESIGN.md:108` says **320–420px expanded**; pick a value, e.g. **320px** for expanded, **64px** for collapsed) and a `SizedBox(width: 360)` for the input panel (within the spec's 320-420 range, see Finding 10), and `Expanded` for the results.
- On **narrow desktop (1024–1279px)**: use a 2-column layout (input panel + results, no drawer). The drawer + input panel + results would be 320 + 360 = 680px of fixed chrome, leaving only ~344px for results on a 1024px screen — too narrow for a usable table. The home-screen `NavigationRail` from L1 stays in this range to provide nav.
- On tablet: unchanged from L3.
- On mobile: unchanged from L1.

**⚠ Risk: two simultaneous navigation systems.** `home_screen.dart:134–174` already renders a `NavigationRail` for desktop on every screen. L4's per-screen `NavigationDrawer` would be a *second* nav system on top of the existing rail. That's confusing UX (two icons for "Settings" in the same view). **Resolution (re-evaluate at L4 time, not now):**
- **Option A:** Move the global nav into the per-screen `NavigationDrawer`. Remove the home-screen `NavigationRail` for desktop (L4 responsibility). The per-screen drawer becomes the only nav, plus the input panel and results. This is the cleanest UX.
- **Option B:** Keep the home-screen `NavigationRail` for global nav, and use the per-screen `NavigationDrawer` for *screen-specific* navigation (e.g. "TCI → Standard / Real-Time / Saved Profiles" in the TCI drawer). Requires adding per-screen sub-routes first.
- **Option C:** Skip the per-screen drawer entirely. L4 becomes "2-column desktop: input panel + results", with the existing `NavigationRail` unchanged. This deviates from `DESIGN.md`'s 3-column mock-up but is the smallest change.

**Recommend Option A** — the spec is clear that the desktop nav should be a drawer, not a rail, and "two navs at once" is bad UX. L4 would include a small home-screen refactor (remove the rail, add a `Drawer` wrapper) alongside the per-screen changes. Rollback is still per-screen because each screen's L4 commit is independent.

**Rollback per screen:** `git revert <L4-TCI-commit>`. The desktop layout returns to rail+content (L1 behaviour). If Option A is taken, the rail-removal is part of the same commit, so the revert restores both.

---

## L5 — Status bar (model / drug / pump info)

**Goal:** on desktop (≥ 1024px), add a status bar at the bottom of the screen showing "Model: {modelName} · Drug: {drugName} · Pump: {pumpRate}".

**Touch:**
- `lib/screens/home_screen.dart` — the mobile `Scaffold` (line 75) already has `bottomNavigationBar: BottomNavigationBar(...)`. The web `Scaffold` (line 130) currently has **no `bottomNavigationBar` property at all** (it's just a `Row` with rail + content). L5 adds a `bottomNavigationBar` to the web `Scaffold` for the first time, rendering a 32dp-tall `Container` with the status info. Mobile keeps the existing 64dp `BottomNavigationBar` (or shows a slimmer 32dp footer above the nav — design decision for L5).
- Each screen needs a way to expose its current model/drug/pump to the home screen. Two options:
  - (a) Push the state up: each screen exposes a `String get statusInfo` getter, and `home_screen.dart` reads it via `Provider` or a callback.
  - (b) Use an `InheritedNotifier` / `ValueNotifier` in the root widget tree that each screen updates.

Recommend (a) — each screen already has access to the controllers. Add a method to `Settings` provider: `String get tciStatusInfo` (or similar) and let each screen write to it on `calculate()`.

**⚠ Risk: L5 may need to be per-screen, not a single commit.** The status bar content depends on the active screen. If TCI writes to `tciStatusInfo` and the user navigates to Settings, the status bar should show *something* — or clear. Decide the behaviour (per-screen, fixed-empty on non-medical screens, or "last updated by TCI"). For L5 to be a single commit, the status bar is "always shows TCI's last state" — simplest, least correct. For per-screen status, each screen adds a write in its own L5 commit.

**Verify:** status bar updates when TCI model / drug / pump rate changes. Status bar hidden on mobile (or shown as a small 24dp footer? — TBD in L5).

**Rollback:** `git revert <L5-commit>`. Status bar removed, no other change.

---

## L6 — Keyboard shortcuts (Enter = calculate, Tab between fields)

**Goal:** on desktop (≥ 1024px) and on web, Enter in any input triggers calculate, and Tab moves between fields in the spec'd order (age → height → weight → sex → drug → model → target → duration → calculate).

**Touch:**
- `lib/components/legacy/PDTextField.dart:135–137` — **`onSubmitted` is already bound to `widget.onPressed()` (the stepper `+` button)**. L6 needs to **suppress** this on desktop/web, not add a new handler. Two options:
  - (a) Add a new `onCalculate` prop to `PDTextField` that takes precedence over `onPressed` when set. In M3/desktop/web callers, pass `onCalculate: screen.calculate`.
  - (b) Use a `Focus` widget or `Shortcuts` widget higher in the tree that catches Enter *before* the field handles it. The `Shortcuts` example below does this.
  - Recommend (a) — explicit, no focus-tree surprises. The L6 PR adds the prop and changes the default desktop/web callers to use it.
- Each screen — wrap the body in a `Shortcuts` + `Actions` widget pair on desktop/web only. Example for the calculate shortcut:
  ```dart
  Shortcuts(
    shortcuts: const <ShortcutActivator, Intent>{
      SingleActivator(LogicalKeyboardKey.enter): CalculateIntent(),
    },
    child: Actions(
      actions: <Type, Action<Intent>>{
        CalculateIntent: CallbackAction<CalculateIntent>(
          onInvoke: (intent) { calculate(); return null; },
        ),
      },
      child: Focus(autofocus: true, child: body),
    ),
  )
  ```
  Define `CalculateIntent extends Intent` once in a shared file (e.g. `lib/utils/intents.dart`).
- **⚠ Tab order doesn't currently match the spec.** The TCI build method (`tci_screen.dart`) renders fields in this order: **age → height → weight → target → drug selector → model selector → duration**. The L6 spec describes the order as: **age → height → weight → sex → drug → model → target → duration → calculate**. Two differences:
  1. **sex** is rendered via `PDSwitchField` (a switch, not a text field) — Tab skips switches by default. Decide whether the spec means switches should be Tab-stoppable (likely yes for keyboard parity).
  2. **target** is rendered after weight, not after drug/model. Reorder or add `FocusTraversalGroup` to enforce the spec order.
  **Action for L6:** decide Tab order. If the spec's order is desired, reorder the TCI fields (and equivalents) and set explicit `focusNode` traversal via `FocusTraversalGroup`. If not, update the spec.

**Verify:** Enter in any field triggers the same `calculate()` as tapping the Calculate button. Enter does **not** increment the stepper on desktop/web (it's intercepted by the `Shortcuts` widget). Tab order matches the spec. Enter does **not** trigger on mobile (the spec says keyboard shortcuts are for desktop only). Gate the `Shortcuts` widget on `ResponsiveHelper.isDesktop(context) || ResponsiveHelper.isWeb()`.

**Rollback:** `git revert <L6-commit>`. Enter and Tab revert to default TextField behaviour (Enter increments the stepper, which is the current behaviour).

---

## L7 — Web max-width 1440px + print styles

**Goal:** on web (any width), constrain the body to max 1440px wide, centered. On `window.print()`, render a print-friendly version (white background, no nav, no status bar, just the results).

**Touch:**
- `lib/screens/home_screen.dart` — wrap the `Scaffold.body` in `Center(child: ConstrainedBox(constraints: BoxConstraints(maxWidth: 1440), child: body))` on web. **Important:** the `Center` + `ConstrainedBox` is applied to the `body` parameter of the `Scaffold`, not to the whole `Scaffold`. The `Scaffold`'s `appBar` (L1), `bottomNavigationBar` (mobile), and any `drawer` (L4) are **outside** the constraint, so they remain full-width on a 1920px screen. This is intentional: chrome (AppBar, nav) is full-width, content (body) is constrained and centered. The spec should be explicit about this so a future implementer doesn't wrap the wrong widget.
- **Caveat:** the `Center` widget constrains the child to its *intrinsic* size by default, not to fill the available space. If the body is a `Column` with `mainAxisSize: MainAxisSize.min`, the body will be narrower than 1440px and the centering will look like floating content. The screens should already be filling widgets (`Column` with `Expanded` children), so this is usually fine, but verify in `flutter run` on a 1920px window. If a screen renders narrower than 1440px, add `SizedBox(width: double.infinity, child: ...)` or use `Align(alignment: Alignment.topCenter, ...)` instead of `Center`.
- New `lib/screens/print_view.dart` (or a print mode flag on each screen) — renders a single-column print-friendly view of the current screen's results, no chrome.

**Verify:** on a 1920px-wide browser window, the AppBar spans 1920px (full width) and the body content is centered at 1440px max. `Cmd+P` opens the browser print dialog with a clean print preview.

**Rollback:** `git revert <L7-commit>`. Web fills the full width again; print reverts to the current (ugly) print output.

---

## Rollback Strategy Summary

Each sub-phase ships as its own commit + PR. To roll back:

| Sub-phase | Rollback command | User-visible effect of revert |
|---|---|---|
| L0 | `git revert <L0>` | None (refactor only) |
| L1 | `git revert <L1>` | No `AppBar` (back to current look) |
| L2 | `git revert <L2>` | 7-tab bottom nav restored, M3 Lab/Real-Time in nav |
| L3 (per screen) | `git revert <L3-TCI>`, etc. | That screen reverts to single-column on tablet; others stay migrated |
| L4 (per screen) | `git revert <L4-TCI>`, etc. | That screen reverts to rail+content on desktop; others stay migrated |
| L5 | `git revert <L5>` | No status bar |
| L6 | `git revert <L6>` | Enter/Tab revert to default |
| L7 | `git revert <L7>` | Web fills full width; no print styles |

**Key safety property:** at any point during L3/L4, if a screen's migration breaks, that one screen reverts and the rest of the app stays migrated. The 6 commits are independent.

---

## Per-Screen Migration Checklist (L3 + L4)

For each screen, complete these checks before merging:

- [ ] Run `flutter test` — all existing tests pass (no calculator regression).
- [ ] Visual diff on mobile (≤ 480px width) — must look identical to pre-migration.
- [ ] Visual diff on tablet (768px width) — new 2-column layout, input on left, results on right.
- [ ] Visual diff on desktop (1280px width) — L3 keeps rail+content, L4 swaps to 3-column.
- [ ] `CollapsibleInputCard` auto-collapses on successful calculate.
- [ ] `CollapsibleInputCard` re-expands on validation error.
- [ ] Scroll position restored after tab switch.
- [ ] No new lint warnings (`flutter analyze`).
- [ ] No new imports of dead code (e.g. `tci_screen_new.dart` should remain unused).

---

## Self-Review: Risks & Findings

### Finding 1: `DESIGN.md` and `responsive_helper.dart` disagree on breakpoints
`DESIGN.md:19` says mobile < 600px. `responsive_helper.dart:9` says mobile < 768px. L0 reconciles by updating `DESIGN.md` to 768px (matches the code, matches M3 app convention).

### Finding 2: `CollapsibleInputCard` already works — but the live TCI screen doesn't use it
The component is built, tested, and used in `realtime_screen.dart`. The active `tci_screen.dart` uses inline widgets. **Reuse, don't rebuild.** Each screen migration in L3 swaps the inline widgets for `CollapsibleInputCard`.

### Finding 3: `tci_screen_new.dart` is a 600-line dead-code reference implementation
It already does the L3 split (mobile vs desktop, 2-way at 840px) and uses `CollapsibleInputCard` correctly. **Read it as a reference for L3 TCI migration, but don't try to "rescue" it** — its 840px breakpoint is different from L0's 768/1024, and it has its own controller / model logic that may not match the live `tci_screen.dart`. Migrate the live file instead.

### Finding 4: No widget tests for any layout
Per `DESIGN_TOKENS_SPEC.md` Finding 11. Layout migration is verified by `flutter run` + visual diff only. For a medical app, this is a quality gap. **Action:** flag as separate follow-up; not in this spec's scope.

### Finding 5: `AppBar` may break TCI scroll-offset persistence
TCI saves scroll position via `settings.dosageTableScrollPosition = tableScrollController.offset` (`tci_screen.dart:115`). The offset is relative to the scrollable, not the screen — adding an `AppBar` reduces the available scroll area, but the saved offset is still valid. **Verify** in L1: scroll to bottom, switch tab, switch back — position restores. If not, the fix is in the offset math, not the `AppBar`.

### Finding 6: L4 drawer might conflict with the home screen's bottom nav / rail
L4 puts a `NavigationDrawer` *inside* each screen, on desktop. But `home_screen.dart` already has a `NavigationRail` for desktop. Two nav systems simultaneously is confusing. **Resolution:** the L4 spec now proposes three options (A: move global nav into the per-screen drawer and remove the home rail; B: keep rail for global nav, drawer for screen-specific; C: skip the drawer, use 2-column desktop). **Recommend A** for cleanest UX. The L4 spec is updated to give these three options explicitly.

### Finding 7: `CollapsibleInputCard` doesn't currently auto-collapse on calculate
The component is built but the "auto-collapse" wiring isn't done in any caller. `realtime_screen.dart:285` uses the card but doesn't listen to calculate results. `tci_screen_new.dart:323, 365` has a comment "Auto-collapse is handled by the CollapsibleInputCard itself" but this is incorrect — the card has no built-in auto-collapse behaviour, and no caller actually invokes a collapse. **Action for L3:** add a public `collapse()` / `expand()` API to `CollapsibleInputCard` (currently none exists — see L3 ⚠ Risk above), and wire it from each screen's `calculate()` success path. This is part of L3, not a follow-up.

### Finding 8: The M3 Lab tab is referenced in CLAUDE.md and `home_screen.dart`
Per CLAUDE.md, M3 Lab is "the Material 3 test lab" used for development. Removing it from the bottom nav (L2) and moving it to a hidden route is a developer-experience change. **Confirm with the team** before L2 ships: is the M3 Lab still useful as a development tool? If yes, keep it in the nav (means spec stays 7-tab). If no, move it.

### Finding 9: Real-Time screen has unique value (real-time clock display)
Per `DESIGN.md`, Real-Time is not a separate screen — it's a TCI mode. But it's been built as a separate screen. **Confirm with the team** before L2: is Real-Time a *feature of* TCI (and should be a mode toggle), or a *peer of* TCI (and should keep its own tab)? The spec says the former; the live code says the latter. L2 forces this decision.

### Finding 10: L4's "input panel 320–420px" is a range, not a value
`DESIGN.md:108` says "320–420px" for the desktop input panel. Pick a value (recommend 360px) and document it. The "responsive" part is for tablet (320px) vs desktop (360px).

### Finding 11: Status bar info per screen is duplicated
Each screen needs to expose "model · drug · pump rate" for the status bar (L5). If TCI is migrated first and the status bar reads from TCI state, what shows when the user is on the Settings screen? **Resolution:** status bar is screen-specific (TCI shows TCI model; Volume shows pump rate only; Settings shows nothing). Per-screen, not global.

### Finding 12: Print styles are out of scope for a normal medical app
`DESIGN.md:142` says "Print-friendly styles for clinical printouts." For an iOS/Android medical app, this is rarely used (clinicians print from a computer, not a phone). **Recommendation:** defer L7 entirely unless the user reports needing it. The spec keeps L7 in the table for completeness, but the priority is L1–L5.

### Finding 13: `Settings._currentScreenIndex` default is 0, not 1
The provider default in `settings.dart:1036` is `0` (EleMarsh). The runtime widget default in `home_screen.dart:26` is `1` (TCI). The widget overrides on first build, but persisted values can be 0–6. After L2 (5 tabs), persisted values 5 and 6 are out of range. **Action:** L2 must add a clamp on read/write (`value.clamp(0, 4)`), not just trust the widget's local default.

### Finding 14: L1 will create double `AppBar` on 4 screens
`settings_screen.dart:171`, `settings_screen_m3.dart:104`, `m3_test_screen.dart:101`, `m3_test_screen_simple.dart:126` each render their own `AppBar`. L1 adds a home `AppBar`. Without coordination, the user sees two AppBars stacked. **Action:** L1's commit removes the per-screen `AppBar` from these 4 files; this is part of the L1 PR, not a follow-up. None of the L3-priority screens (`tci_screen.dart`, `volume_screen.dart`, `duration_screen.dart`, `elemarsh_screen.dart`) have per-screen AppBars, so L3 is clean.

### Finding 15: App has no routing infrastructure
`main.dart:125` uses `home: const HomeScreen()`. There is no `onGenerateRoute`, no `routes:` map, no `Router`. L2's "hidden route for M3 Lab" cannot be implemented with `MaterialApp.onGenerateRoute` because the field doesn't exist. The spec is updated to use `Navigator.push` from a Settings tile (no new routing infrastructure). This is a 10-line addition vs the originally-implied routing system.

### Finding 16: Desktop `Scaffold` has no `bottomNavigationBar` to extend
L5 was specified as "add a `bottomNavigationBar` to the desktop `Scaffold`" — but the desktop `Scaffold` (`home_screen.dart:130–183`) currently has *no* `bottomNavigationBar` property at all. L5 is "add `bottomNavigationBar` for the first time on desktop", not "extend an existing one". This is a bigger change than the L5 description implies. Spec updated to call this out.

### Finding 17: L3 TCI is harder after L2 makes Real-Time a mode toggle
L2 (per spec) folds Real-Time into TCI as a mode toggle. L3 TCI's tablet view then needs to render either the standard TCI body or the realtime body in the right column. The L3 spec's "wrap in `AdaptiveLayout`" is correct, but the `tabletLayout` callback becomes a mode switch. Document this in the L3 TCI PR.

### Finding 18: Three demo/test screens have different status
- `lib/screens/m3_test_screen.dart` — **active**, imported by `home_screen.dart:16, 37` (one of the 6 nav destinations). Has its own `AppBar` at line 101.
- `lib/screens/m3_test_screen_simple.dart` — **dead code**. Defined but not imported anywhere. Has its own `AppBar` at line 126.
- `lib/screens/test_screen.dart` — **dead code**. Defined but not imported anywhere. No `AppBar`.

**Action:** L1 needs to remove the per-screen `AppBar` from `m3_test_screen.dart:101` (active) but can leave the dead `m3_test_screen_simple.dart` and `test_screen.dart` alone (they don't ship). L2 should consider deleting the two dead files as a small cleanup commit (or leave for a future "delete dead code" sweep — not in this spec).

### Finding 19: `CollapsibleInputCard` has no public collapse/expand API
`lib/components/collapsible_input_card.dart:60–319` has no `collapse()`, `expand()`, or controller pattern. The card is fully tap-driven. `tci_screen_new.dart` claims "Auto-collapse is handled by the CollapsibleInputCard itself" but this is a misleading comment — no such behaviour exists. **Action for L3:** add `void collapse()` and `void expand()` to `_CollapsibleInputCardState` (toggle `_isExpanded` and call `setState`). Expose them via a controller class or `GlobalKey<State<CollapsibleInputCard>>`. Wire each screen's `calculate()` success path to call `_inputCardKey.currentState?.collapse()`.

### Finding 20: `PDTextField.onSubmitted` is already bound to the stepper
`lib/components/legacy/PDTextField.dart:135–137`: `onSubmitted: (val) { widget.onPressed(); }` — Enter on any PDTextField currently increments the stepper (the `+` button action). L6's spec said "add an `onSubmitted` callback" but the callback is already there doing the wrong thing. **Action for L6:** either (a) add a new `onCalculate` prop that takes precedence on desktop/web, or (b) wrap the body in a `Shortcuts` widget that catches Enter before the field handles it. L6 is "override the existing binding", not "add a new one".

### Finding 21: TCI field order doesn't match the L6 spec
`tci_screen.dart`'s build method renders fields in this order: age → height → weight → target → drug selector → model selector → duration. The L6 spec lists: age → height → weight → sex → drug → model → target → duration → calculate. Two real differences:
1. The `PDSwitchField` for sex is a switch, not a text field — Tab skips it by default.
2. The target field is rendered *before* the drug/model selectors, not after.

**Action for L6:** decide the intended Tab order. If the L6 spec's order is the goal, reorder the TCI fields and add `FocusTraversalGroup` to enforce it. If not, update the L6 spec to match the current order.

### Finding 22: L1 + L2 + L3 collide on screen-specific AppBar actions
L1 puts a single home `AppBar`. L2 wants a "Standard / Real-Time" `SegmentedButton` inside the TCI screen. L3 wants `CollapsibleInputCard` to be the input section. The TCI screen has no `AppBar` of its own currently — so the L2 mode toggle has nowhere to live. **Action:** L2's Real-Time toggle should be rendered **inside** the home `AppBar`'s `actions:` list, conditional on `currenIndex == 1` (TCI). Or, alternatively, rendered as a `SegmentedButton` at the top of the TCI screen body. Decide at L2 implementation. Either way, the home `AppBar` needs an `actions:` parameter, and L1 should set that up as `actions: []` so L2 can extend it.

### Finding 23: `home_screen.dart` has 7 screens in `_getScreens`; L2 says reduce to 5
After L2, the screens list at `home_screen.dart:28–40` should be reduced from 7 widgets to 5 (drop M3TestScreen and RealtimeScreen). But `_buildMobileLayout` and `_buildWebLayout` build their `BottomNavigationBarItem` and `NavigationRailDestination` lists from the same index set. **Action for L2:** the two lists (mobile items at lines 101–122, rail destinations at lines 144–173) and the screens list (lines 28–40) must all be edited together. Indices in `_titleFor` (when L1 is added) must be re-numbered to match. Easy to get out of sync — recommend extracting a single `List<({Widget screen, String label, IconData icon})> _navDestinations` and rendering both the bottom nav, the rail, and the AppBar title from it.

### Finding 24: 4 competing breakpoint systems in the codebase
The codebase has 4 different breakpoint definitions in active use:
1. `lib/utils/responsive_helper.dart:9–10` — width 768 / 1024 — used by `home_screen.dart`.
2. `lib/components/collapsible_input_card.dart:296–319` — width 600 / 840 / 1200 — used by `CollapsibleInputCard.getCollapsedHeight()`.
3. `lib/components/input_summary_display.dart:9–13` — width 600 — used by `InputSummaryDisplay`.
4. `lib/constants.dart:72–73` — height 704 / 992 — used by `duration_screen.dart`.

Plus 2 hardcoded `840` literals in `realtime_screen.dart:37` (constant `_kBreakpointWide`) and `tci_screen_new.dart:302, 620` (raw `840`). **The L0 spec is updated to consolidate all 4 systems into a single `lib/config/breakpoints.dart` file. The card's specific values (600/840/1200) need a decision: keep them as "card-internal" semantics (wider mobile zone) or unify with the home screen's 768/1024.** This decision blocks L0.

### Finding 25: Per-screen `AppBar` patterns are not all the same
3 screens have per-screen `AppBar`s, and the patterns differ:
- `settings_screen_m3.dart:103–107` and `settings_screen.dart:170–176` — inline `AppBar` as a child of `Column`, followed by `SizedBox(height: kSp16)`. The `SizedBox` is compensating for the inline AppBar's height.
- `m3_test_screen.dart:100` — proper `Scaffold(appBar: AppBar(...))` with custom `actions` (an M3/Legacy toggle at lines 104–113).
- `m3_test_screen_simple.dart:126` — proper `Scaffold(appBar: AppBar(...))`, but dead code.

**L1's "remove the per-screen AppBar" needs to handle all 3 patterns differently:**
- For inline `AppBar` + `SizedBox`: remove both.
- For `Scaffold(appBar:)` with `actions`: migrate the `actions` to the home `AppBar`'s `_actionsFor()`.

The spec's L1 section is updated with this distinction.

### Finding 26: L2's "10-line About section" is understated
The spec originally said the M3 Lab Settings tile is "a 10-line addition". The settings screen (`settings_screen_m3.dart`) has no `ListTile`, no `ExpansionTile`, no section headers — it's a flat `ListView` of widgets. Adding a styled "About" section with a header is closer to **30–40 lines**. L2 is bigger than originally implied.

### Finding 27: Nested `Scaffold` in `m3_test_screen.dart`
`m3_test_screen.dart:100` has its own `Scaffold` *inside* the home screen's `Scaffold` (since the home `Scaffold` renders the body which is the screen widget). Nested Scaffolds in Flutter are technically allowed but can produce unexpected layout (e.g. the inner `Scaffold` consumes a `MediaQuery` that the outer one expected). If L1 removes the inner `appBar`, consider whether the inner `Scaffold` is still needed (it has no `bottomNavigationBar` or other chrome). **Action for L1:** if the inner `Scaffold` is purely for `appBar`, flatten to `Container` or `Column` after removing `appBar`. If the inner `Scaffold` is needed for `floatingActionButton` or other chrome, keep it. Verify in `flutter run`.

### Finding 28: L7 chrome-vs-body scope was implicit
The original L7 spec said "wrap the `Scaffold` body in a `Center(child: ConstrainedBox(maxWidth: 1440))`". The `Scaffold` chrome (AppBar from L1, bottomNavigationBar on mobile, drawer from L4, status bar from L5) sits *outside* the body. So on a 1920px screen, the AppBar spans 1920px (full width) and the body is centered at 1440px max. The spec is updated to be explicit: **chrome full-width, body constrained**. This is intentional and matches common web-app design (e.g. a fixed-width content area with a full-bleed header).

### Finding 29: L1 should set up `actions: []` even if no actions exist yet
L1 should define `_actionsFor(int index, BuildContext context)` returning `List<Widget>[]` initially. L2 will populate it for the TCI Real-Time toggle and the M3 Lab M3/Legacy toggle. If L1 doesn't set up the function, L2 has to refactor L1 to add it, breaking the "one commit per sub-phase" promise. **Action:** L1 PR includes the empty `_actionsFor()` function with a comment "L2 will populate this for TCI and M3 Lab".

### Finding 30: `screenBreakPoint1` / `screenBreakPoint2` are height-based, not width-based
`lib/constants.dart:72–73` defines `screenBreakPoint1 = 704` and `screenBreakPoint2 = 992` for *height* checks in `duration_screen.dart:182, 184, 236`. These are not the same as the home screen's *width* breakpoints. L0's breakpoint consolidation should leave the height-based constants separate (rename to `kMobileHeightMax`, `kTabletHeightMax` to clarify), but a future reader might confuse them. **Action for L0:** rename the constants in `constants.dart` to make the unit (height vs width) explicit.

### Finding 31: L4 originally specified the wrong drawer width
`DESIGN.md:108` says the desktop nav drawer should be 320–420px wide, matching the input panel's range. The L4 spec originally said "240px expanded, 64px collapsed" — wrong on both numbers. Spec is updated: **320px expanded, 64px collapsed** (picking the lower end of the spec's range, leaving 40px buffer for the right side). The 240px value was made up. **Action for L4:** implement 320/64, not 240/64.

### Finding 32: L3 requires `collapsedSummary` widgets, but `InputSummaryDisplay` already exists
`CollapsibleInputCard` requires both `expandedContent` and `collapsedSummary`. The existing `InputSummaryDisplay` widget (`lib/components/input_summary_display.dart`) is designed for this purpose and supports TCI's exact field set (`calculatorType`, `age`, `sex`, `weight`, `height`, `drug`, `model`, `target`, `duration`, plus duration/elemarsh extras). **For TCI, the collapsedSummary is a single `InputSummaryDisplay` call (~10-20 lines including prop wiring), not 50-100 lines.** The widget is already used in `realtime_screen.dart:458` and the dead `tci_screen_new.dart:541`. **Action for L3:** each screen's PR includes an `InputSummaryDisplay` instantiation with the screen's current values. For TCI, this is a few lines. The earlier 50-100 line estimate was an overcorrection — corrected here.

⚠ Note: `InputSummaryDisplay` has its own `ResponsiveBreakpoints` class with mobile < 600px (Finding 24). At 768-1023px (L3 tablet range), it renders `_buildDesktopSummary` (a `Row` with `Expanded` children), not the mobile multi-line version. Verify on tablet that the Row lays out within the available card width. If it overflows, fall back to the mobile summary by passing a `width` constraint, or split the summary into two stacked rows manually.

### Finding 33: L4's 3-column layout doesn't fit at 1024px
At the 1024px lower bound of "desktop", a 3-column layout with 320px drawer + 360px input panel = 680px of fixed chrome, leaving only ~344px for results. That's too narrow for a usable table. **Resolution:** L4 splits desktop into two sub-ranges: **narrow desktop (1024-1279px)** uses a 2-column layout (no drawer, just input panel + results); **wide desktop (≥ 1280px)** uses the full 3-column. The home-screen `NavigationRail` from L1 stays in the narrow-desktop range to provide nav. The spec is updated.

### Finding 34: L7's `Center` + `ConstrainedBox` only constrains the *body*, and the body must fill
`Scaffold.body` is wrapped in `Center(child: ConstrainedBox(maxWidth: 1440))` on web. The chrome (AppBar, nav) sits outside, so it stays full-width. But the body itself must be a widget that fills the available width (e.g. `Column` with `Expanded` children) — not a fixed-width widget — otherwise the centering makes the content float in the middle of a 1920px window. Verify each screen's body is fill-width in L7 QA. If a screen is narrower than 1440px after the wrap, add `SizedBox(width: double.infinity)` or use `Align(alignment: Alignment.topCenter, ...)` instead of `Center`.

### Finding 35: L2 changes are mobile-only
The 6 → 5 tab reduction (M3 Lab and Real-Time removed) is a **mobile-only** change. The web `NavigationRail` already has 7 destinations (lines 144-173), but the mobile `BottomNavigationBar` has 7 destinations (lines 101-122) — both 7, not 6. After L2, both reduce to 5. **The spec's L2 "Touch" section is correct (mentions both `101-122` and `144-173`) but the L2 spec body says "6 tabs" once and "7 destinations" once — both wrong.** The current count is 7 in both layouts. Spec is updated.

### Finding 36: `BottomNavigationBar` type is `fixed`, which constrains label visibility
`home_screen.dart:93` uses `BottomNavigationBarType.fixed` (not `shifting`). With `fixed`, all labels are always visible — at 7 items, the labels are very small on a phone (e.g. "EleMarsh" might truncate to "EleMar…"). After L2 reduces to 5, the labels have more room and truncation is less likely. **Verify in L2 QA** that labels don't truncate on small phones (≤ 360px width). If they do, switch to `BottomNavigationBarType.shifting` (icons only, label on selection) or shorten labels.

### Finding 37: Two `ResponsiveBreakpoints` classes with the same name
`lib/components/collapsible_input_card.dart:296` and `lib/components/input_summary_display.dart:9` both define a class named `ResponsiveBreakpoints` with similar but not identical APIs. The `input_summary_display` one is at mobile < 600 (single breakpoint, line 11). The `collapsible_input_card` one is mobile 600 / tablet 840 / desktop 1200 (3 breakpoints, lines 297-299). They are file-private (no library exports), so no import collision *today*, but if a future file imports both, the names will collide. L0's consolidation should make a single canonical `ResponsiveBreakpoints` in `lib/config/breakpoints.dart` and remove the duplicates.

### Finding 38: L1 originally proposed `currenIndex == 5` for the M3/Legacy toggle — wrong after L2
L1 originally said "migrate the M3/Legacy toggle to the home `AppBar`'s `_actionsFor()` for `currenIndex == 5`". But L2 reduces the nav from 7 to 5 tabs, so after L2, M3 Lab is no longer at any `currenIndex` — it's accessed via the Settings tile. The M3/Legacy toggle has to live inside `M3TestScreen` itself (in the body or in its own `Scaffold.appBar`). Spec is updated to recommend (b) — move the toggle to the screen body, no AppBar needed.

### Finding 39: Finding 32's 50-100 line estimate for L3 `collapsedSummary` was 3-5x too high
The previous self-review pass estimated TCI's `collapsedSummary` would be 50-100 lines of new code. After re-reading `InputSummaryDisplay` (`lib/components/input_summary_display.dart:30-58`), the widget already supports TCI's exact field set. TCI's `collapsedSummary` is a single `InputSummaryDisplay` call (~10-20 lines including prop wiring), not 50-100. **Corrected.**
