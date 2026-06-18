# UI/UX Optimization Research

## Scope

Research target: optimize the full Propofol Dreams UI/UX for a safety-critical medical calculator used by anesthetists across mobile, tablet, desktop, and web.

Primary app surfaces reviewed:
- `lib/screens/home_screen.dart`
- `lib/screens/tci_screen.dart`
- `lib/screens/volume_screen.dart`
- `lib/screens/volume_plus_screen.dart`
- `lib/screens/duration_screen.dart`
- `lib/screens/elemarsh_screen.dart`
- `lib/components/collapsible_input_card.dart`
- `lib/components/input_summary_display.dart`
- `lib/components/infusion_regime_table.dart`
- `lib/components/legacy/PDTextField.dart`
- `lib/components/legacy/PDSwitchField.dart`
- `lib/config/design_tokens.dart`
- `lib/config/breakpoints.dart`

## External Research Sources

- FDA, "Applying Human Factors and Usability Engineering to Medical Devices"  
  https://www.fda.gov/regulatory-information/search-fda-guidance-documents/applying-human-factors-and-usability-engineering-medical-devices
- FDA, "Human Factors Considerations"  
  https://www.fda.gov/medical-devices/human-factors-and-medical-devices/human-factors-considerations
- Material Design 3, "Text fields"  
  https://m3.material.io/components/text-fields
- Material Design 3, "Text fields guidelines"  
  https://m3.material.io/components/text-fields/guidelines
- Nielsen Norman Group, "10 Design Guidelines for Reporting Errors in Forms"  
  https://www.nngroup.com/articles/errors-forms-design-guidelines/
- Nielsen Norman Group, "Few Guesses, More Success: 4 Principles to Reduce Cognitive Load in Forms"  
  https://www.nngroup.com/articles/4-principles-reduce-cognitive-load/
- Nielsen Norman Group, "A Checklist for Designing Mobile Input Fields"  
  https://www.nngroup.com/articles/mobile-input-checklist/
- Healthcare app UX best-practice references collected in `.firecrawl/uiux-*.json`

## Research Takeaways

### Safety-Critical UX

- Treat UI changes as human-factors risk controls, not visual polish.
- Reduce use errors by making inputs, constraints, current model/drug, and output units visible at the point of decision.
- Do not rely on color alone for errors or drug identity. Pair color with text/icon labels.
- Avoid surprise recalculation/collapse during editing. Explicit calculation actions are safer for medication-related workflows.
- Preserve clinical auditability: result values should remain visibly tied to patient/model/drug/pump parameters.

### Forms And Inputs

- Inline validation should sit next to the field causing the problem.
- Do not validate while the user is still typing incomplete values unless the field is stepper-only.
- Complex fields should have clear successful/invalid states.
- Input labels should stay close to their controls.
- Numeric inputs need explicit units, ranges, and predictable increment behavior.
- On mobile, field layouts should avoid horizontally cramped paired controls when labels or localized strings get longer.

### Material 3

- Use one consistent field style. Mixing custom legacy fields, M3 wrappers, and hand-built `TextField` dropdowns increases visual drift and layout bugs.
- Outlined fields are a good fit for data-entry-heavy calculator screens because they are lower emphasis than filled fields and support dense forms.
- Supporting/error text should not create blank reserved space unless a field needs stable vertical height for a specific reason.
- Touch targets should remain at least 48dp, with 56dp a good default for mobile medical use.

### Responsive Layout

- The current two-pane tablet/desktop direction is correct: inputs left, results right.
- Calculator screens duplicate layout code, which makes bugs recur unevenly across TCI, Volume, Duration, and EleMarsh.
- Width should be derived from parent constraints, not whole screen width, for anything inside cards or rows.
- Result tables need bounded scroll areas and stable headers; they should not rely on intrinsic-height layout inside scroll views.

## Current App Findings

### Strengths

- TCI is correctly treated as the primary workflow and opens by default.
- `CollapsibleInputCard` gives a clear input/results separation and supports edit-after-result workflows.
- Mobile, tablet, and desktop layouts already exist for key screens.
- The app has initial design tokens and breakpoint files.
- Material 3 migration wrappers exist, so a staged migration is feasible.

### Main UX Debt

- Calculator screens duplicate input-card, results, shortcuts, reset-button, and responsive layout logic.
- Some selectors are hand-built `TextField + Stack + GestureDetector` controls while others use legacy or M3 components.
- Several widths are content/screen-based instead of parent-constrained, causing overflow risks.
- Error handling is inconsistent: some fields show local errors, some rely on modal messages, and some preserve helper-space while others do not.
- Reset buttons are icon-only and can be mistaken for refresh/recalculate without accessible text or tooltip.
- Result prominence differs by screen; users may not always see which patient/model/drug produced the currently visible output.
- The design token layer is too thin: spacing, radius, elevation, animation exist, but field heights, card widths, result typography, table density, and semantic colors are scattered.
- Accessibility semantics are likely weak on Flutter web CanvasKit and custom controls.

## Recommended Optimization Strategy

### Phase 1: Stabilize Shared UI Primitives

Goal: stop recurring overflow/layout bugs and make all calculator screens behave the same.

Tasks:
- Create a shared `CalculatorInputRow` for model/drug selector + reset button rows.
- Create a shared parent-constrained selector shell for dropdown-like controls.
- Add tokens for field height, card width, form gap, button radius, table row height, and result typography.
- Add tooltips/semantics to reset, calculate, expand/collapse, plus/minus buttons.
- Standardize reset button shape and size across screens.

Risk: low. Mostly component consolidation and layout constraints.

### Phase 2: Unify Calculator Screen Layouts

Goal: one responsive layout pattern for TCI, Volume, Duration, and EleMarsh.

Tasks:
- Extract a `CalculatorScaffold` or `CalculatorPaneLayout` with mobile single-column and tablet/desktop two-pane behavior.
- Make input pane widths consistent: mobile full width, tablet about 320px, desktop about 360-400px.
- Make results pane scroll independently and keep tables bounded.
- Keep input card expanded while editing; collapse only on explicit Calculate.
- Add a persistent result context strip: drug/model/patient/pump summary near results.

Risk: medium. Needs regression screenshots for every calculator screen.

### Phase 3: Improve Medical Safety UX

Goal: reduce dosing/calculation use errors.

Tasks:
- Add inline range hints for age, height, weight, target, duration, and pump limits.
- Show validation messages next to the exact field or selector.
- Add visible success/current-state indicators for model compatibility.
- Make disabled fields explain why they are disabled, for example Marsh age or plasma-target constraints.
- Require visually explicit model/drug/concentration state near the primary result.
- Use unit labels consistently: `kg`, `cm`, `min`, `mcg/mL`, `mL/hr`, `mg/hr`.

Risk: medium. Needs clinical review of wording and thresholds.

### Phase 4: Visual Polish And Material 3 Migration

Goal: make the app feel coherent, modern, and reliable without changing clinical behavior.

Tasks:
- Decide on one field implementation path: enhanced legacy PD fields or full M3 wrappers.
- Apply consistent outlined field styling, 8px radius, filled surface, focused/error states.
- Reduce visual noise in forms by using consistent icon sizes and label hierarchy.
- Improve table readability with sticky-ish header treatment, row density tokens, and selected-row highlight consistency.
- Refine color semantics: drug identity colors should be accents, not the only identifier.
- Add high-contrast and text-scaling verification.

Risk: medium-high. Visual migration can accidentally alter field behavior.

### Phase 5: Accessibility And QA

Goal: verify the optimized UI under real usage constraints.

Tasks:
- Add semantic labels for custom controls.
- Verify keyboard navigation on web/desktop.
- Verify screen sizes: 375x812, 430x932, 768x1024, 1024x768, 1280x720, 1440x900.
- Verify text scale 1.0, 1.3, 1.5.
- Run screenshot regression passes for every tab.
- Run Flutter analyzer and targeted widget tests where feasible.

Risk: low-medium. Mostly verification and semantics.

## Priority Recommendations

1. Consolidate selector/reset rows first. This directly addresses the latest overflow class of bugs.
2. Extract the calculator pane layout second. This prevents future TCI/Volume/Duration/EleMarsh divergence.
3. Standardize validation and disabled-field explanations third. This is the highest patient-safety UX value.
4. Only then migrate visuals deeper into Material 3. Visual polish should sit on stable behavior.

## Suggested First Implementation Slice

Implement one narrow, reversible slice:

1. Add `CalculatorSelectorRow` shared component.
2. Use it in TCI and Volume only.
3. Add semantics/tooltips to the reset button.
4. Verify mobile/tablet/desktop screenshots.
5. If stable, migrate Duration and EleMarsh.

This addresses active pain without taking a risky full-screen rewrite first.
