import 'package:flutter/material.dart';

/// Single source of truth for responsive breakpoints.
///
/// Two breakpoint scales are defined because two systems were in active use
/// before this file was created:
///
/// 1. **Layout breakpoints** (`kLayoutMobileMax`, `kLayoutTabletMax`) — used by
///    `home_screen.dart` and `ResponsiveHelper` to choose between mobile,
///    tablet, and desktop layouts. Matches M3 convention and `DESIGN.md`.
///
/// 2. **Card-internal breakpoints** (`kCardMobileMax`, `kCardTabletMax`) —
///    used by `CollapsibleInputCard` and `InputSummaryDisplay` to choose
///    internal rendering (collapsed height, summary layout). The card uses a
///    wider mobile zone (600px) and a higher desktop threshold (1200px)
///    because cards are focused components, not full layouts. See
///    `LAYOUT_MIGRATION_SPEC.md` Finding 24 for rationale.
///
/// **Do not add new breakpoint definitions elsewhere.** All new code should
/// import from this file. The duplicate `ResponsiveBreakpoints` classes that
/// used to live in `collapsible_input_card.dart` and
/// `input_summary_display.dart` have been removed; their callers now use the
/// helpers below.

// ── Layout breakpoints (width, in logical pixels) ──────────

/// Maximum width of the mobile range. Below this, the app uses the mobile
/// layout (bottom nav, single column). Default 768px.
const double kLayoutMobileMax = 768;

/// Maximum width of the tablet range. Below this and at or above
/// `kLayoutMobileMax`, the app uses the tablet layout (nav rail, 2-column).
/// At or above this value, the app uses the desktop layout. Default 1024px.
const double kLayoutTabletMax = 1024;

// ── Card-internal breakpoints (width, in logical pixels) ───

/// Maximum width of the card's "mobile" range. Below this, `CollapsibleInputCard`
/// returns its 68dp collapsed height and `InputSummaryDisplay` renders its
/// mobile multi-line summary. Default 600px.
const double kCardMobileMax = 600;

/// Maximum width of the card's "tablet" range. At or above this and below
/// `kCardDesktopMin`, `CollapsibleInputCard` returns its 56dp collapsed height
/// and `InputSummaryDisplay` renders its desktop row summary. Default 840px.
const double kCardTabletMax = 840;

/// Minimum width of the card's "desktop" range. At or above this,
/// `CollapsibleInputCard` returns its 48dp collapsed height. Default 1200px.
const double kCardDesktopMin = 1200;

// ══════════════════════════════════════════════════════════════════════════════
// Height breakpoints remain in `lib/constants.dart` as `int` values
// (`screenBreakPoint1 = 704`, `screenBreakPoint2 = 992`), with named aliases
// `kButtonHeightMobileMax` and `kButtonHeightTabletMax`. They are not replicated
// here because the 19 existing call sites import `constants.dart` and these
// breakpoints describe screen-height (not layout-width) concerns, so they live
// in the general constants file rather than the layout-config file.
// See LAYOUT_MIGRATION_SPEC.md Finding 30.
// ══════════════════════════════════════════════════════════════════════════════

// ── Layout helpers ─────────────────────────────────────────

/// True if the screen is mobile size (< 768px width).
bool isLayoutMobile(BuildContext context) {
  return MediaQuery.of(context).size.width < kLayoutMobileMax;
}

/// True if the screen is tablet size (768px–1023px width).
bool isLayoutTablet(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  return width >= kLayoutMobileMax && width < kLayoutTabletMax;
}

/// True if the screen is desktop size (>= 1024px width).
bool isLayoutDesktop(BuildContext context) {
  return MediaQuery.of(context).size.width >= kLayoutTabletMax;
}

// ── Card-internal helpers ──────────────────────────────────

/// True if the card is in its mobile range (< 600px width).
bool isCardMobile(BuildContext context) {
  return MediaQuery.of(context).size.width < kCardMobileMax;
}

/// True if the card is in its tablet range (600px–1199px width).
bool isCardTablet(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  return width >= kCardMobileMax && width < kCardDesktopMin;
}

/// True if the card is in its desktop range (>= 1200px width).
bool isCardDesktop(BuildContext context) {
  return MediaQuery.of(context).size.width >= kCardDesktopMin;
}

/// Returns the recommended collapsed height for `CollapsibleInputCard` based
/// on the card-internal breakpoints. Migrated from
/// `lib/components/collapsible_input_card.dart:314–318`.
double getCardCollapsedHeight(BuildContext context) {
  if (isCardDesktop(context)) return 48.0;
  if (isCardTablet(context)) return 56.0;
  return 68.0; // Mobile
}
