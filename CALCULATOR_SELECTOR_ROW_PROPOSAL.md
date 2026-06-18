# CalculatorSelectorRow Proposal

## Goal

Create one shared component for the common calculator pattern:

```text
[ selector field........................ ] [ reset ]
  error or validation message, when present
```

This should replace the duplicated selector/reset rows in TCI, Volume, and later Volume Plus, Duration, and EleMarsh where applicable.

## Why

The recent Volume model dropdown overflow came from screen-specific layout code that calculated selector width from the whole screen while the selector was inside a narrower card row beside a reset button.

A shared row prevents that bug class from recurring and gives validation messages one consistent location and style.

## Proposed File

`lib/components/calculator_selector_row.dart`

## Component Responsibilities

- Lay out a selector and reset button without overflow.
- Derive selector width from parent constraints, never whole-screen width.
- Keep reset button fixed square size.
- Show validation/error text consistently below the selector row.
- Keep spacing, radius, tooltip, semantics, and alignment consistent across calculator screens.
- Keep error messages close to the selector that caused them.

## Non-Responsibilities

This component should not own:

- Model validation logic.
- Drug/model modal behavior.
- Text measurement for selector labels.
- Screen-specific reset behavior.
- Pharmacokinetic or clinical rules.

The screen still decides:

- Which selector widget to render.
- What the current error text is.
- What reset means.
- Whether the message is about model, drug, concentration, patient constraints, or target constraints.

## Proposed API

```dart
class CalculatorSelectorRow extends StatelessWidget {
  const CalculatorSelectorRow({
    super.key,
    required this.selector,
    required this.onReset,
    required this.resetTooltip,
    this.errorText,
    this.height = 56,
    this.spacing = 8,
  });

  final Widget selector;
  final VoidCallback onReset;
  final String resetTooltip;
  final String? errorText;
  final double height;
  final double spacing;
}
```

## Layout Behavior

The component should render:

```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: selector),
        SizedBox(width: spacing),
        SizedBox(
          width: height,
          height: height,
          child: resetButton,
        ),
      ],
    ),
    if (hasError) errorMessage,
  ],
)
```

The selector is always inside `Expanded`, so it can only use the row width left after the reset button and gap.

## Error Display

Error display must be relevant and consistent.

Rules:

- Only render error UI when `errorText != null && errorText.trim().isNotEmpty`.
- Place the message directly below the selector row.
- Align the message with the selector, not under the reset button.
- Use `Theme.of(context).colorScheme.error`.
- Use the same small text style everywhere, likely `theme.textTheme.bodySmall` or `labelSmall`.
- Include a small error icon for scanning.
- Do not rely on color alone.
- Do not reserve blank vertical space when there is no error.

Example:

```text
[ Model: Eleveld.......................v ] [ reset ]
  ! Eleveld unavailable: age must be 1-16 years for pediatric mode
```

## Accessibility

Reset button should have:

- `Tooltip(resetTooltip)`.
- `Semantics(button: true, label: resetTooltip)`.
- A consistent icon, currently `Icons.restart_alt_outlined`.

Error text should have:

- Error icon plus readable text.
- A semantics label such as `Error: $errorText` if needed.

## Styling

Use existing tokens where possible:

- Gap: `kSp8`
- Radius: `kRadius`
- Error icon size: `16`
- Reset button size: same as field height, usually `UIHeight`

The row should not define selector styling. Selector styling stays inside the selector widget so TCI drug selectors, model selectors, and future Material 3 selectors can all be hosted.

## Initial Rollout

1. Add `CalculatorSelectorRow`.
2. Replace the model selector/reset row in `VolumeScreen`.
3. Replace the drug/model selector/reset row in `TCIScreen` where it matches the pattern.
4. Pass existing validation text into `errorText`.
5. Verify mobile/tablet/desktop screenshots.
6. Verify runtime logs for overflow/assertion errors.
7. If stable, migrate `VolumePlusScreen`, `DurationScreen`, and `EleMarshScreen` where applicable.

## Success Criteria

- No right-side selector overflow on mobile, tablet, or desktop.
- Error messages look and behave the same in TCI and Volume.
- Reset button has tooltip and semantic label.
- No blank reserved helper/error space when there is no message.
- No change to clinical calculation behavior.
