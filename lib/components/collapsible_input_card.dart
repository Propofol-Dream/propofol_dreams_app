import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/design_tokens.dart';
import '../config/breakpoints.dart';

/// Controller for programmatic collapse/expand of [CollapsibleInputCard].
///
/// Created by the parent widget and passed to [CollapsibleInputCard.controller].
/// Call [collapse] or [expand] to control the card state from outside.
class CollapsibleInputCardController {
  void Function()? _collapse;
  void Function()? _expand;

  void collapse() => _collapse?.call();
  void expand() => _expand?.call();
}

/// A collapsible card that can show a compact summary when collapsed
/// and full input fields when expanded. Optimized for medical calculator UIs.
class CollapsibleInputCard extends StatefulWidget {
  const CollapsibleInputCard({
    super.key,
    required this.title,
    required this.expandedContent,
    required this.collapsedSummary,
    this.controller,
    this.isInitiallyExpanded = true,
    this.onExpansionChanged,
    this.showCalculateButton = true,
    this.onCalculate,
    this.calculateButtonText = 'Calculate',
    this.isCalculating = false,
    this.hasValidationError = false,
    this.forceExpanded = false,
  });

  /// Title shown in the card header
  final String title;

  /// Content shown when the card is expanded (input fields)
  final Widget expandedContent;

  /// Compact summary shown when collapsed
  final Widget collapsedSummary;

  /// Optional external controller for programmatic collapse/expand.
  final CollapsibleInputCardController? controller;

  /// Whether the card should be expanded initially
  final bool isInitiallyExpanded;

  /// Callback when expansion state changes
  final ValueChanged<bool>? onExpansionChanged;

  /// Whether to show the calculate button
  final bool showCalculateButton;

  /// Callback when calculate button is pressed
  final VoidCallback? onCalculate;

  /// Text for the calculate button
  final String calculateButtonText;

  /// Whether calculation is in progress (shows loading)
  final bool isCalculating;

  /// Whether there's a validation error (forces expansion)
  final bool hasValidationError;

  /// Force the card to stay expanded (for validation errors)
  final bool forceExpanded;

  @override
  State<CollapsibleInputCard> createState() => _CollapsibleInputCardState();
}

class _CollapsibleInputCardState extends State<CollapsibleInputCard>
    with TickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _animationController;
  late Animation<double> _iconRotationAnimation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isInitiallyExpanded;

    _animationController = AnimationController(
      duration: kAnimNormal,
      vsync: this,
    );

    _iconRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5, // 180 degrees
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (_isExpanded) {
      _animationController.value = 1.0;
    }

    // Wire external controller, if provided.
    widget.controller?._collapse = () {
      if (_isExpanded) _setExpanded(false, haptic: false);
    };
    widget.controller?._expand = () {
      if (!_isExpanded) _setExpanded(true, haptic: false);
    };
  }

  @override
  void didUpdateWidget(CollapsibleInputCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Force expansion for validation errors
    if (widget.hasValidationError && !_isExpanded) {
      _toggleExpansion();
    }
    
    // Force expansion if explicitly requested
    if (widget.forceExpanded && !_isExpanded) {
      _toggleExpansion();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    _setExpanded(!_isExpanded);
  }

  void _setExpanded(bool expanded, {bool haptic = true}) {
    setState(() {
      _isExpanded = expanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });

    if (haptic) HapticFeedback.selectionClick();
    widget.onExpansionChanged?.call(_isExpanded);
  }

  /// Auto-collapse after successful calculation
  void autoCollapse() {
    if (_isExpanded && !widget.hasValidationError && !widget.forceExpanded) {
      _toggleExpansion();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      elevation: _isExpanded ? kElev3 : kElev1,
      margin: const EdgeInsets.symmetric(horizontal: kSp16, vertical: kSp8),
      child: AnimatedContainer(
        duration: kAnimFast,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kRadiusLg),
          border: widget.hasValidationError
              ? Border.all(color: colorScheme.error, width: 1.5)
              : null,
        ),
        child: Column(
          children: [
            // Header with title and expand/collapse button
            InkWell(
              onTap: widget.forceExpanded ? null : _toggleExpansion,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(kRadiusLg),
                bottom: Radius.circular(kRadiusLg),
              ),
              child: Padding(
                padding: const EdgeInsets.all(kSp16),
                child: Row(
                  children: [
                    Icon(
                      Icons.calculate_outlined,
                      color: widget.hasValidationError
                          ? colorScheme.error
                          : colorScheme.primary,
                    ),
                    const SizedBox(width: kSp12),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: widget.hasValidationError
                              ? colorScheme.error
                              : null,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (!widget.forceExpanded)
                      RotationTransition(
                        turns: _iconRotationAnimation,
                        child: Icon(
                          Icons.expand_more,
                          color: widget.hasValidationError
                              ? colorScheme.error
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Collapsible content
            ClipRect(
              child: AnimatedSwitcher(
                duration: kAnimFast,
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,
                child: _isExpanded
                    ? _buildExpandedContent()
                    : _buildCollapsedContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedContent() {
    return SizedBox(
      key: const ValueKey('expanded'),
      width: double.infinity,
      child: Column(
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(kSp16),
            child: widget.expandedContent,
          ),
          const SizedBox.shrink(),
          if (widget.showCalculateButton) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(kSp16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: widget.isCalculating ? null : _handleCalculate,
                  icon: widget.isCalculating
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.play_arrow),
                  label: Text(
                    widget.isCalculating
                        ? 'Calculating...'
                        : widget.calculateButtonText,
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: kSp16),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCollapsedContent() {
    return SizedBox(
      key: const ValueKey('collapsed'),
      width: double.infinity,
      child: Column(
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: kSp16,
              vertical: kSp12,
            ),
            child: widget.collapsedSummary,
          ),
        ],
      ),
    );
  }

  void _handleCalculate() {
    widget.onCalculate?.call();
    
    // Auto-collapse after a short delay to allow for calculation completion
    Future.delayed(kDebounce, () {
      if (mounted && !widget.hasValidationError) {
        autoCollapse();
      }
    });
  }
}

/// Responsive breakpoints for the card component.
///
/// **Deprecated in L0 (see `LAYOUT_MIGRATION_SPEC.md` Finding 24).** The
/// constants and methods here are now thin wrappers around the canonical
/// helpers in `lib/config/breakpoints.dart`. New code should use those
/// helpers directly. This class is kept for backward compatibility with
/// any external callers; the duplicate `ResponsiveBreakpoints` class that
/// used to live in `lib/components/input_summary_display.dart` has been
/// removed in favour of these wrappers.
class ResponsiveBreakpoints {
  /// Mobile max width. Deprecated; use `kCardMobileMax` from
  /// `lib/config/breakpoints.dart`.
  static const double mobile = kCardMobileMax;

  /// Tablet max width. Deprecated; use `kCardTabletMax` from
  /// `lib/config/breakpoints.dart`.
  static const double tablet = kCardTabletMax;

  /// Desktop min width. Deprecated; use `kCardDesktopMin` from
  /// `lib/config/breakpoints.dart`.
  static const double desktop = kCardDesktopMin;

  static bool isMobile(BuildContext context) => isCardMobile(context);

  static bool isTablet(BuildContext context) => isCardTablet(context);

  static bool isDesktop(BuildContext context) => isCardDesktop(context);

  static double getCollapsedHeight(BuildContext context) =>
      getCardCollapsedHeight(context);
}
