import 'package:flutter/widgets.dart';

/// Intent triggered by pressing Enter on a calculator screen.
///
/// Bound to a [CallbackAction] in the active screen's `Actions` widget.
/// The bound action calls the screen's `calculate()` method.
///
/// Added in L6 (LAYOUT_MIGRATION_SPEC.md) for keyboard-driven calculate
/// on desktop (≥ 1024px) and web. The wrapping `Shortcuts` widget catches
/// the Enter key *before* `PDTextField.onSubmitted` handles it, so the
/// stepper-increment behaviour is suppressed in favour of calculate.
class CalculateIntent extends Intent {
  const CalculateIntent();
}
