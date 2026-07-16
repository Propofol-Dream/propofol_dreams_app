# PDTci Flutter TCI Replacement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the standalone `https://github.com/propofoldreams/pdtci` static PWA layout with a standalone Flutter web build that uses a new rollback-safe `TCIScreenNew` implementation.

**Architecture:** Keep `propofol_dreams_app` as the source of truth for TCI behavior and UI, but do not modify or replace the current `TCIScreen` until the new screen is approved. Add `TCIScreenNew` as a parallel screen, add a TCI-only Flutter entrypoint/shell that renders `TCIScreenNew` without the full home navigation, build it with `flutter build web --target`, then publish the generated static web output into the `pdtci` repository. Rollback inside this app is switching the standalone shell back to the current `TCIScreen` or deleting `TCIScreenNew`; rollback in `pdtci` remains a Git tag/branch reset plus redeploy of the previous static bundle when static files are manually hosted.

**Tech Stack:** Flutter web, Provider `Settings`, new parallel `TCIScreenNew`, current `TCIScreen` preserved as rollback source, static PWA output, Git/GitHub Pages or equivalent static host.

---

## Findings From `propofoldreams/pdtci`

The current `pdtci` repository is already a built static web app, not a source-code app:

- Root files: `index.html`, `manifest.webmanifest`, `registerSW.js`, `sw.js`, app icons/logo assets.
- Bundled assets: `assets/index-KrLmDjaS.js`, `assets/index-BmgQZth0.css`.
- Runtime model: vanilla JS PWA with a hand-authored DOM layout and a bundled PK/TCI simulator.
- Layout: top nav with logo/title/settings, central results table, bottom input panel.
- Results: initial bolus, scrollable infusion table, time/rate/volume-or-dose columns.
- Inputs: target stepper at top of bottom panel, drug select, sex toggle, age/weight/height steppers, patient-summary minimize mode.
- Settings: drug concentrations, language buttons, time sync modal, paediatric height helper, credits modal.
- Drug/model mapping in pdtci: Propofol and Remifentanil use Eleveld, Dexmedetomidine uses Hannivoort, Remimazolam uses Schnider in the bundled JS.
- Existing pdtci duration is 240 minutes, matching current Flutter TCI screen.

The current Flutter app already covers most required behavior in `lib/screens/tci_screen.dart`, but that file must remain unchanged until approval:

- Uses `TCIScreen` with `PKField`, `SwitchField`, `Selector<Drug>`, `DosageDataTable`, `InfusionRateChart`, `CollapsibleInputSection`.
- Drug selection is deduplicated by `displayName` and concentration is resolved through Settings.
- Duration is fixed at 240 minutes.
- Drug/model mapping currently uses Eleveld by default and Hannivoort for Dexmedetomidine.
- Mobile layout hides chart and chips, uses fixed-bottom input panel.
- Desktop/tablet layout uses RHS 393px input panel.
- Time sync exists through table row selection plus sync controls/state.

Locked behavioral decision:

- Preserve old pdtci behavior in `TCIScreenNew`: Remimazolam maps to Schnider. Keep current `TCIScreen` unchanged until approval, even if its mapping differs.

---

## File Structure

### `propofol_dreams_app` source repo

- Create: `lib/screens/tci_screen_new.dart`
  - New parallel screen for pdtci replacement.
  - Starts as a copy of the current `TCIScreen` behavior.
  - Must not be wired into `HomeScreen` until approved.
  - Must not modify `lib/screens/tci_screen.dart`.

- Create: `lib/main_tci_standalone.dart`
  - Standalone Flutter entrypoint for pdtci.
  - Initializes `Settings` exactly like `lib/main.dart`.
  - Renders a TCI-only MaterialApp shell with `TCIScreenNew` as home.
  - Does not include `HomeScreen`, NavigationRail, NavigationBar, Volume, Duration, EleMarsh, or Settings screen navigation.

- Create: `lib/screens/tci_standalone_shell.dart`
  - Thin shell around `TCIScreenNew`.
  - Contains no navigation; the app title is owned by `PdtciStandaloneApp`.
  - Keeps styling consistent with current app theme.

- Preserve: `lib/screens/tci_screen.dart`
  - Do not edit during the pdtci replacement build.
  - This is the in-app rollback screen until `TCIScreenNew` is explicitly approved.
  - Any shared behavior should be copied into `TCIScreenNew` first; extract shared helpers only after approval.

- Preserve: `web/manifest.json`
  - Do not modify the main app manifest in this plan.
  - The build script writes pdtci-specific title and PWA metadata into staged files under `build/pdtci_web/` only.

- Create: `scripts/build_pdtci_web.sh`
  - Builds standalone Flutter web target.
  - Writes static output to `build/pdtci_web/`.
  - Does not require `.gitignore` changes because `build/` is already ignored.

- Test: `test/tci_standalone_shell_test.dart`
  - Verifies standalone app boots and renders `TCIScreenNew` UI without home navigation.

- Test: `test/tci_screen_new_test.dart`
  - Verifies `TCIScreenNew` renders independently and does not require `HomeScreen`.

- Test: `test/tci_screen_drug_model_test.dart`
  - Verifies agreed drug-to-model behavior.
  - Locks legacy pdtci Remimazolam mapping: Remimazolam -> Schnider in `TCIScreenNew`.

### `pdtci` static repo

- Preserve: current `main` branch and all existing files through a rollback tag.
- Replace after build approval: root static files with Flutter web build output.
- Keep or replace icons/title/manifest depending on final product naming.

---

## Rollback Requirements

App-level rollback during development:

- Keep `lib/screens/tci_screen.dart` unchanged.
- Keep `HomeScreen` wired to the current `TCIScreen` until approval.
- Build pdtci from `TCIScreenNew` only through `lib/main_tci_standalone.dart`.
- If `TCIScreenNew` is rejected, delete `lib/screens/tci_screen_new.dart`, `lib/screens/tci_standalone_shell.dart`, `lib/main_tci_standalone.dart`, and associated tests/build scripts, leaving the current app untouched.
- App-level fallback is explicit: replace `lib/screens/tci_standalone_shell.dart` with the fallback code shown in Task 7, then rebuild.

Rollback must be prepared before any replacement commit is pushed to `pdtci`.

- Create a rollback branch from current `pdtci/main`: `rollback/static-pdtci-before-flutter`.
- Create a rollback tag from current `pdtci/main`: `pdtci-static-before-flutter-YYYYMMDD`.
- Save a local archive of the current static bundle.
- Deploy replacement only after confirming rollback branch/tag exists on GitHub.
- If production static hosting is not GitHub Pages, also preserve the current deployed server directory before upload.

Rollback commands for `pdtci` GitHub repository:

```bash
git clone git@github.com:propofoldreams/pdtci.git /tmp/pdtci-rollback-check
cd /tmp/pdtci-rollback-check
git checkout main
git pull --ff-only
git branch rollback/static-pdtci-before-flutter
git tag pdtci-static-before-flutter-YYYYMMDD
git push origin rollback/static-pdtci-before-flutter
git push origin pdtci-static-before-flutter-YYYYMMDD
```

Rollback after replacement if `pdtci/main` must return to old static layout:

```bash
cd /tmp/pdtci-rollback-check
git fetch origin
git checkout main
git reset --hard pdtci-static-before-flutter-YYYYMMDD
git push origin main
```

Rollback without rewriting `main` history:

```bash
cd /tmp/pdtci-rollback-check
git fetch origin
git checkout main
git revert --no-edit <replacement_commit_sha>
git push origin main
```

Server rollback if static files are deployed manually:

```bash
ssh root@172.105.178.138 'cp -a /Docker/pdtci/srv /Docker/pdtci/srv.rollback.$(date +%Y%m%d%H%M%S)'
scp -r /tmp/pdtci-static-before-flutter/* root@172.105.178.138:/Docker/pdtci/srv/
ssh root@172.105.178.138 'docker compose restart caddy'
```

---

## Task 1: Confirm Product Scope And Preserve Rollback

**Files:**
- No source changes.
- External repo: `git@github.com:propofoldreams/pdtci.git`

- [ ] **Step 1: Confirm standalone scope**

Confirm these answers before implementation:

```text
1. Replace pdtci with new Flutter TCIScreenNew only, not the full Flutter app shell.
2. Hide EleMarsh, Volume, Duration, and Settings navigation in pdtci.
3. Keep pdtci as a standalone TCI PWA with title "Propofol Dreams TCI".
4. Use Flutter Settings persistence for concentration and patient fields.
5. Preserve old pdtci Remimazolam mapping in TCIScreenNew: Remimazolam -> Schnider.
6. Keep current TCIScreen and HomeScreen TCI tab unchanged until TCIScreenNew is approved.
```

- [ ] **Step 2: Clone pdtci into temp workspace**

Run:

```bash
git clone git@github.com:propofoldreams/pdtci.git /tmp/pdtci-migration
cd /tmp/pdtci-migration
git status --short
git log --oneline -5
```

Expected:

```text
Clean working tree.
Recent commits visible.
```

- [ ] **Step 3: Create remote rollback branch and tag**

Run:

```bash
cd /tmp/pdtci-migration
git checkout main
git pull --ff-only
git branch rollback/static-pdtci-before-flutter
git tag pdtci-static-before-flutter-YYYYMMDD
git push origin rollback/static-pdtci-before-flutter
git push origin pdtci-static-before-flutter-YYYYMMDD
```

Expected:

```text
Remote branch rollback/static-pdtci-before-flutter exists.
Remote tag pdtci-static-before-flutter-YYYYMMDD exists.
```

- [ ] **Step 4: Archive current static pdtci bundle locally**

Run:

```bash
mkdir -p /tmp/pdtci-static-before-flutter
rsync -a --delete /tmp/pdtci-migration/ /tmp/pdtci-static-before-flutter/
```

Expected:

```text
/tmp/pdtci-static-before-flutter contains current index.html, assets/, sw.js, manifest.webmanifest, icons.
```

---

## Task 2: Add Parallel TCIScreenNew And Standalone Entrypoint

**Files:**
- Create: `lib/screens/tci_screen_new.dart`
- Create: `lib/main_tci_standalone.dart`
- Create: `lib/screens/tci_standalone_shell.dart`
- Test: `test/tci_screen_new_test.dart`
- Test: `test/tci_standalone_shell_test.dart`

- [ ] **Step 1: Write failing TCIScreenNew boot test**

Create `test/tci_screen_new_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:propofol_dreams_app/l10n/generated/app_localizations.dart';
import 'package:propofol_dreams_app/providers/settings.dart';
import 'package:propofol_dreams_app/screens/tci_screen_new.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('TCIScreenNew renders independently', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = Settings();
    await settings.initializeFromDisk();

    await tester.pumpWidget(
      ChangeNotifierProvider<Settings>.value(
        value: settings,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: TCIScreenNew(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Propofol'), findsWidgets);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(NavigationRail), findsNothing);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
flutter test test/tci_screen_new_test.dart
```

Expected:

```text
FAIL because lib/screens/tci_screen_new.dart does not exist.
```

- [ ] **Step 3: Create TCIScreenNew as rollback-safe copy**

Create `lib/screens/tci_screen_new.dart` by copying the current `lib/screens/tci_screen.dart`, then renaming only the widget/state classes.

Run:

```bash
cp lib/screens/tci_screen.dart lib/screens/tci_screen_new.dart
perl -0pi -e 's/class TCIScreen extends StatefulWidget/class TCIScreenNew extends StatefulWidget/g; s/const TCIScreen\(\{super\.key\}\);/const TCIScreenNew({super.key});/g; s/State<TCIScreen> createState\(\) => _TCIScreenState\(\);/State<TCIScreenNew> createState() => _TCIScreenNewState();/g; s/class _TCIScreenState extends State<TCIScreen>/class _TCIScreenNewState extends State<TCIScreenNew>/g' lib/screens/tci_screen_new.dart
```

Expected declarations in `lib/screens/tci_screen_new.dart`:

```dart
class TCIScreenNew extends StatefulWidget {
  const TCIScreenNew({super.key});

  @override
  State<TCIScreenNew> createState() => _TCIScreenNewState();
}

class _TCIScreenNewState extends State<TCIScreenNew> {
  // Existing copied TCIScreen implementation remains here.
}
```

After copying, ensure there are no remaining declarations named `TCIScreen` or `_TCIScreenState` in `lib/screens/tci_screen_new.dart`.

Run:

```bash
grep -n "class TCIScreen\|const TCIScreen(\|State<TCIScreen>\|_TCIScreenState" lib/screens/tci_screen_new.dart
```

Expected:

```text
No output.
```

- [ ] **Step 4: Run TCIScreenNew boot test to verify it passes**

Run:

```bash
flutter test test/tci_screen_new_test.dart
```

Expected:

```text
All tests passed.
```

- [ ] **Step 5: Write failing shell boot test**

Create `test/tci_standalone_shell_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:propofol_dreams_app/l10n/generated/app_localizations.dart';
import 'package:propofol_dreams_app/providers/settings.dart';
import 'package:propofol_dreams_app/screens/tci_screen_new.dart';
import 'package:propofol_dreams_app/screens/tci_standalone_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('standalone TCI shell renders TCI screen without home navigation', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = Settings();
    await settings.initializeFromDisk();

    await tester.pumpWidget(
      ChangeNotifierProvider<Settings>.value(
        value: settings,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: TciStandaloneShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.textContaining('Propofol'), findsWidgets);
    expect(find.byType(TCIScreenNew), findsOneWidget);
  });
}
```

- [ ] **Step 6: Run shell test to verify it fails**

Run:

```bash
flutter test test/tci_standalone_shell_test.dart
```

Expected:

```text
FAIL because lib/screens/tci_standalone_shell.dart does not exist.
```

- [ ] **Step 7: Create standalone shell**

Create `lib/screens/tci_standalone_shell.dart`:

```dart
import 'package:flutter/material.dart';
import 'tci_screen_new.dart';

class TciStandaloneShell extends StatelessWidget {
  const TciStandaloneShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const TCIScreenNew();
  }
}
```

- [ ] **Step 8: Create standalone entrypoint**

Create `lib/main_tci_standalone.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'l10n/generated/app_localizations.dart';
import 'providers/settings.dart';
import 'screens/tci_standalone_shell.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settings = Settings();
  await settings.initializeFromDisk();

  runApp(
    ChangeNotifierProvider<Settings>.value(
      value: settings,
      child: const PdtciStandaloneApp(),
    ),
  );
}

class PdtciStandaloneApp extends StatelessWidget {
  const PdtciStandaloneApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<Settings>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Propofol Dreams TCI',
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ja'),
        Locale.fromSubtags(languageCode: 'zh'),
        Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
        Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      ],
      theme: ThemeData(colorScheme: MaterialTheme.lightScheme()),
      darkTheme: ThemeData(colorScheme: MaterialTheme.darkScheme()),
      themeMode: settings.themeModeSelection,
      home: const TciStandaloneShell(),
    );
  }
}
```

- [ ] **Step 9: Run tests to verify shell passes**

Run:

```bash
flutter test test/tci_screen_new_test.dart test/tci_standalone_shell_test.dart
```

Expected:

```text
All tests passed.
```

- [ ] **Step 10: Commit standalone entrypoint**

Run:

```bash
git add lib/screens/tci_screen_new.dart lib/main_tci_standalone.dart lib/screens/tci_standalone_shell.dart test/tci_screen_new_test.dart test/tci_standalone_shell_test.dart
git commit -m "feat: add rollback-safe standalone TCI screen"
```

---

## Task 3: Preserve Old PDTci Drug Model Mapping In TCIScreenNew

**Files:**
- Modify: `lib/screens/tci_screen_new.dart`
- Preserve: `lib/screens/tci_screen.dart`
- Test: `test/tci_screen_drug_model_test.dart`

- [ ] **Step 1: Write failing mapping test for legacy pdtci behavior**

Create `test/tci_screen_drug_model_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:propofol_dreams_app/models/drug.dart';
import 'package:propofol_dreams_app/models/model.dart';
import 'package:propofol_dreams_app/screens/tci_screen_new.dart';

void main() {
  test('TCIScreenNew drug mapping matches legacy pdtci behavior', () {
    expect(TCIScreenNew.modelForDrug(Drug.propofol10mg), Model.Eleveld);
    expect(TCIScreenNew.modelForDrug(Drug.remifentanil50mcg), Model.Eleveld);
    expect(TCIScreenNew.modelForDrug(Drug.dexmedetomidine), Model.Hannivoort);
    expect(TCIScreenNew.modelForDrug(Drug.remimazolam1mg), Model.Schnider);
  });
}
```

- [ ] **Step 2: Run mapping test to verify it fails**

Run:

```bash
flutter test test/tci_screen_drug_model_test.dart
```

Expected before wiring:

```text
FAIL because TCIScreenNew.modelForDrug does not exist or Remimazolam still maps to Eleveld.
```

- [ ] **Step 3: Add static mapping helper to TCIScreenNew only**

Modify `lib/screens/tci_screen_new.dart` inside `class TCIScreenNew`:

```dart
class TCIScreenNew extends StatefulWidget {
  const TCIScreenNew({super.key});

  static Model modelForDrug(Drug? drug) {
    if (drug == null) return Model.Eleveld;
    if (drug.isDexmedetomidine) return Model.Hannivoort;
    if (drug.isRemimazolam) return Model.Schnider;
    return Model.Eleveld;
  }

  @override
  State<TCIScreenNew> createState() => _TCIScreenNewState();
}
```

Then replace only `TCIScreenNew`'s copied private resolver implementation:

```dart
Model _getModelForDrug(Drug? drug) => TCIScreenNew.modelForDrug(drug);
```

Do not modify `lib/screens/tci_screen.dart`.

- [ ] **Step 4: Run mapping and TCI tests**

Run:

```bash
flutter test test/tci_screen_drug_model_test.dart test/tci_screen_new_test.dart test/tci_standalone_shell_test.dart
```

Expected:

```text
All tests passed.
```

- [ ] **Step 5: Commit mapping decision**

Run:

```bash
git add lib/screens/tci_screen_new.dart test/tci_screen_drug_model_test.dart
git commit -m "test: preserve pdtci drug model mapping in new TCI screen"
```

---

## Task 4: Add Build Script For PDTci Static Output

**Files:**
- Create: `scripts/build_pdtci_web.sh`

- [ ] **Step 1: Create build script**

Create `scripts/build_pdtci_web.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$ROOT_DIR/build/pdtci_web"

rm -rf "$OUT_DIR"

flutter build web \
  --release \
  --target lib/main_tci_standalone.dart

mkdir -p "$OUT_DIR"
rsync -a --delete "$ROOT_DIR/build/web/" "$OUT_DIR/"

python3 - <<'PY'
import json
from pathlib import Path

index = Path('build/pdtci_web/index.html')
text = index.read_text()
text = text.replace('<title>propofol_dreams_app</title>', '<title>Propofol Dreams TCI</title>')
text = text.replace('<title>Propofol Dreams</title>', '<title>Propofol Dreams TCI</title>')
index.write_text(text)

manifest = Path('build/pdtci_web/manifest.json')
if manifest.exists():
    data = json.loads(manifest.read_text())
    data['name'] = 'Propofol Dreams TCI'
    data['short_name'] = 'PDTci'
    data['description'] = 'Standalone Propofol Dreams TCI calculator'
    data['theme_color'] = '#000000'
    data['background_color'] = '#000000'
    manifest.write_text(json.dumps(data, indent=2) + '\n')
PY

printf 'Built standalone PDTci web output at %s\n' "$OUT_DIR"
```

- [ ] **Step 2: Make build script executable**

Run:

```bash
chmod +x scripts/build_pdtci_web.sh
```

- [ ] **Step 3: Run build script**

Run:

```bash
scripts/build_pdtci_web.sh
```

Expected:

```text
Built standalone PDTci web output at .../build/pdtci_web
```

- [ ] **Step 4: Smoke test built output locally**

Run:

```bash
python3 -m http.server 8091 --directory build/pdtci_web
```

Open:

```text
http://localhost:8091
```

Expected:

```text
TCI screen loads directly.
No EleMarsh/Volume/Duration/Settings navigation.
Drug selector, patient fields, target field, table, and sync controls work.
```

- [ ] **Step 5: Commit build script**

Run:

```bash
git add scripts/build_pdtci_web.sh
git commit -m "chore: add pdtci standalone web build script"
```

---

## Task 5: Replace PDTci Static Bundle In The PDTci Repo

**Files:**
- External repo: `/tmp/pdtci-migration`
- Source output: `build/pdtci_web/`

- [ ] **Step 1: Confirm rollback exists before replacement**

Run:

```bash
cd /tmp/pdtci-migration
git fetch origin --tags
git rev-parse origin/rollback/static-pdtci-before-flutter
git rev-parse pdtci-static-before-flutter-YYYYMMDD
```

Expected:

```text
Both commands print commit SHAs.
```

- [ ] **Step 2: Replace pdtci repo contents with Flutter build output**

Run from `propofol_dreams_app` repo:

```bash
rsync -a --delete \
  --exclude '.git' \
  build/pdtci_web/ \
  /tmp/pdtci-migration/
```

- [ ] **Step 3: Inspect replacement diff**

Run:

```bash
cd /tmp/pdtci-migration
git status --short
git diff --stat
```

Expected:

```text
Old static app files replaced by Flutter web build files.
No unrelated secrets or local files.
```

- [ ] **Step 4: Local static smoke test from pdtci repo**

Run:

```bash
cd /tmp/pdtci-migration
python3 -m http.server 8092
```

Open:

```text
http://localhost:8092
```

Expected:

```text
Standalone Flutter TCI loads.
Refresh works.
TCI calculation renders a non-empty infusion table.
Settings persist after refresh through Flutter web local storage.
```

- [ ] **Step 5: Commit pdtci replacement**

Run:

```bash
cd /tmp/pdtci-migration
git add -A
git commit -m "replace static pdtci with Flutter TCI app"
```

- [ ] **Step 6: Push pdtci replacement**

Run:

```bash
cd /tmp/pdtci-migration
git push origin main
```

Expected:

```text
pdtci/main contains replacement commit.
Rollback branch/tag remain available.
```

---

## Task 6: Post-Deploy Verification

**Files:**
- No source changes unless verification reveals a bug.

- [ ] **Step 1: Verify deployed URL**

Open production/staging pdtci URL.

Expected:

```text
Standalone Flutter TCI app loads, not old glass-panel static layout.
```

- [ ] **Step 2: Verify core calculation path**

Use defaults:

```text
Drug: Propofol
Sex: Female or Male
Age: 40
Height: 170
Weight: 70
Target: 3.0
```

Expected:

```text
Dashboard cards show bolus/max rate/total.
Infusion table rows render.
No Flutter red-screen/console errors.
```

- [ ] **Step 3: Verify concentration settings**

Change Propofol concentration to 20 mg/mL in settings, return to TCI, recalculate.

Expected:

```text
Drug chip/display resolves Propofol (20 mg/mL).
Calculation uses the selected concentration.
```

- [ ] **Step 4: Verify all pdtci drug paths**

Check:

```text
Propofol
Remifentanil
Dexmedetomidine
Remimazolam
```

Expected:

```text
Each drug calculates without error and displays appropriate target units.
```

- [ ] **Step 5: Verify mobile behavior**

On mobile viewport:

```text
Input panel is fixed at bottom.
Table scrolls.
Fields remain usable.
No keyboard-induced unusable layout.
```

- [ ] **Step 6: Verify rollback path is still intact**

Run:

```bash
cd /tmp/pdtci-migration
git fetch origin --tags
git rev-parse origin/rollback/static-pdtci-before-flutter
git rev-parse pdtci-static-before-flutter-YYYYMMDD
```

Expected:

```text
Both rollback refs still resolve.
```

---

## Task 7: Rollback Drill

**Files:**
- External repo only: `/tmp/pdtci-migration`

- [ ] **Step 1: Prepare non-destructive rollback command**

Prefer revert first:

```bash
cd /tmp/pdtci-migration
git checkout main
git pull --ff-only
git revert --no-edit <replacement_commit_sha>
```

Expected:

```text
New revert commit restores old static pdtci files.
```

- [ ] **Step 2: Validate rollback diff locally before pushing**

Run:

```bash
cd /tmp/pdtci-migration
python3 -m http.server 8093
```

Open:

```text
http://localhost:8093
```

Expected:

```text
Old static pdtci glass-panel layout loads again.
```

- [ ] **Step 3: Push rollback during actual rollback**

Run during actual rollback after Step 2 confirms the old static layout loads:

```bash
cd /tmp/pdtci-migration
git push origin main
```

- [ ] **Step 4: Emergency hard rollback with explicit approval**

Run with explicit approval when the revert path cannot be used:

```bash
cd /tmp/pdtci-migration
git fetch origin --tags
git checkout main
git reset --hard pdtci-static-before-flutter-YYYYMMDD
git push origin main
```

Expected:

```text
main points exactly to pre-replacement static app commit.
```

---

## Task 8: App-Level Fallback To Current TCIScreen

**Files:**
- Modify: `lib/screens/tci_standalone_shell.dart`
- Preserve: `lib/screens/tci_screen_new.dart`
- Preserve: `lib/screens/tci_screen.dart`

- [ ] **Step 1: Replace standalone shell with current TCIScreen fallback**

Use this after `TCIScreenNew` is rejected and the standalone pdtci build is approved to ship from the current screen.

Replace `lib/screens/tci_standalone_shell.dart` with:

```dart
import 'package:flutter/material.dart';
import 'tci_screen.dart';

class TciStandaloneShell extends StatelessWidget {
  const TciStandaloneShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const TCIScreen();
  }
}
```

- [ ] **Step 2: Build fallback output**

Run:

```bash
scripts/build_pdtci_web.sh
```

Expected:

```text
Built standalone PDTci web output at .../build/pdtci_web
```

- [ ] **Step 3: Commit fallback after approval**

Run after approval:

```bash
git add lib/screens/tci_standalone_shell.dart
git commit -m "chore: fallback standalone pdtci to current TCIScreen"
```

---

## Self-Review

### Spec coverage

- Read through pdtci repository: covered via `index.html`, bundled JS/CSS, manifest, and asset structure.
- Replace pdtci layout with rollback-safe `TCIScreenNew`: planned through standalone Flutter entrypoint and static build replacement.
- Preserve current in-app `TCIScreen` until approval: covered by file structure, rollback requirements, and Task 2/Task 3 constraints.
- Preserve old pdtci Remimazolam behavior: covered by Task 3 mapping test and `TCIScreenNew.modelForDrug()`.
- App-level fallback to current `TCIScreen`: covered by Task 8.
- Plan only: no production behavior changes are part of this plan document.
- Rollback: covered by branch, tag, local archive, Git revert, hard reset, and server file restore options.

### Placeholder scan

- Placeholder scan passed: all implementation steps include concrete files, commands, and expected output.
- Remimazolam model mapping is now explicit: `TCIScreenNew` preserves old pdtci behavior and maps Remimazolam to Schnider.

### Type consistency

- `TCIScreenNew`, `TCIScreenNew.modelForDrug`, `TciStandaloneShell`, and `PdtciStandaloneApp` names are consistent across tasks.
- Existing `Settings`, `TCIScreen`, `Drug`, and `Model` references match current Flutter source names.
