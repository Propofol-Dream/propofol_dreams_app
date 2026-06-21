# Swipe-to-Collapse Spec (Revised)

## Problem
The collapsible input panel requires a tap on the header to expand/collapse. A swipe gesture would feel more natural.

## Solution
Add a `Listener` on top of the existing `InkWell` to detect vertical drag. No changes to the animation widget (`AnimatedCrossFade`). No `GestureDetector` replacement (keeps InkWell's tap ripple).

## Implementation

### Add drag tracking to `_CollapsibleInputSectionState`

```dart
bool _isCollapsed = false;
double _dragAccumulator = 0;
static const double _dragThreshold = 100.0;
```

### Add drag overlay widget

During drag, overlay a semi-transparent bar on top of the content that scales with drag progress:

```dart
// During active drag (not after release), show a visual indicator
if (_dragAccumulator.abs() > 10) {
  // Show a drag progress indicator — a thin bar that fills from top
  // This gives haptic-feel feedback without fighting AnimatedCrossFade
  child = Stack(
    children: [
      child,
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        height: (_dragAccumulator.abs() / _dragThreshold * 48).clamp(0, 48),
        child: Container(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        ),
      ),
    ],
  );
}
```

### Replace top-level column with a Listener-wrapped column

The current `Column(children: [header, AnimatedCrossFade])` becomes:

```dart
Listener(
  onPointerDown: (_) => _dragAccumulator = 0,
  onPointerMove: (event) {
    if (_isCollapsed) {
      // Only allow drag UP when collapsed (negative delta)
      if (event.delta.dy < 0) _dragAccumulator += event.delta.dy.abs();
    } else {
      // Only allow drag DOWN when expanded (positive delta)
      if (event.delta.dy > 0) _dragAccumulator += event.delta.dy;
    }
    if (_dragAccumulator.abs() > 10) setState(() {});
  },
  onPointerUp: (_) {
    if (_dragAccumulator > _dragThreshold && !_isCollapsed) {
      setState(() => _isCollapsed = true);
    } else if (_dragAccumulator > _dragThreshold && _isCollapsed) {
      setState(() => _isCollapsed = false);
    }
    _dragAccumulator = 0;
    setState(() {});
  },
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      header,  // unchanged InkWell
      AnimatedCrossFade(  // unchanged
        firstChild: const SizedBox.shrink(),
        secondChild: widget.child,
        ...
      ),
    ],
  ),
)
```

### Visual feedback during drag
- A thin overlay fills from top: `_dragAccumulator / _dragThreshold * 48px` height
- Primary color at 10% opacity
- Grows as user drags further
- Disappears on release (whether toggle or snap-back)
- Subtle — doesn't obscure content, just signals "keep going to collapse"

### What this avoids
- No `Transform.translate` on `AnimatedCrossFade` (which breaks when collapsed)
- No replacing `InkWell` — tap ripple preserved
- No fighting with `AnimatedCrossFade`'s internal animation
- No sign convention confusion — accumulator is always positive, direction limited per state:
  - Expanded → only track drag DOWN (positive delta)
  - Collapsed → only track drag UP (negative delta → converted to positive accumulator)

### Files
- Modify: `lib/components/collapsible_input_section.dart`

### Behavior
- Tap header → toggle (unchanged, via InkWell)
- Swipe down on expanded header → visual fill grows → release past 100px → collapse
- Swipe up on collapsed header → visual fill grows → release past 100px → expand
- Release before threshold → visual fill resets (no toggle)
- Total change: ~40 lines added

### No screen changes needed — the widget's interface stays identical.