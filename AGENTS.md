# AGENTS.md — Propofol Dreams

## Recent Volume Screen Rewrite (v3.0.8+131)

### New Widgets
- `PKField` (`lib/components/pk_field.dart`) — M3 TextField + ± pill-steppers, long press repeat, highlight flash, `hasError` param
- `SwitchField` (`lib/components/switch_field.dart`) — M3 TextField + Switch, toggle highlight flash
- `SelectorRow` (`lib/components/selector_row.dart`) — `TextField` + `showModalBottomSheet` (not `DropdownMenu` — avoids overflow on mobile)

### Layout
- **Mobile**: Fixed-bottom input panel, result label pinned above input, data table expands via `AnimatedSize`
- **Tablet/Desktop**: RHS fixed panel (393px), result label top (60px fixed), table fills remaining height
- `SafeArea` wrapping, `Spacer` pushes reset button far right

### Input Panel Row Structure
```
Row
├── IntrinsicWidth → SelectorRow (48px, PKField-matching colors)
├── SizedBox(12)
├── Container(48px) → [Icon(face/child), Text, Switch]
├── Spacer
└── SizedBox(48×48) → ElevatedButton(reset)
```

### Colors
- Theme via `ThemeData(colorScheme: MaterialTheme.{light,darkScheme}())` (no `useMaterial3: true`)
- SelectorRow uses same `kSp16`/`kSp12` padding as PKField, `onSurfaceVariant` labels, `primary` floating label

## Key Gotchas
- `DropdownMenu` has ~192px minimum width, overflows on mobile. Use `TextField` + `showModalBottomSheet` instead
- `readOnly` TextField mutes colors — use explicit `style: TextStyle(color: theme.colorScheme.onSurface)`
- `useMaterial3: true` changes color scheme — don't set it without updating all token references
- `Spacer` competes with `Expanded` for flex space — use only one per flex direction

## Pushed Commits
- `04f9580` — replace DropdownMenu with TextField+ModalBottomSheet, fix gap 12px
- `eea8e34` — fix selector_row colors/height/width match PKField, Spacer for reset button