import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A collapsible card that can show a compact summary when collapsed
/// and full input fields when expanded. Optimized for medical calculator UIs.
class CollapsibleInputCard extends StatefulWidget {
  const CollapsibleInputCard({
    super.key,
    required this.title,
    required this.expandedContent,
    required this.collapsedSummary,
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
  late Animation<double> _heightFactorAnimation;
  late Animation<double> _iconRotationAnimation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isInitiallyExpanded;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _heightFactorAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
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
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });

    // Add haptic feedback for better user experience
    HapticFeedback.selectionClick();

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
      elevation: _isExpanded ? 3.0 : 1.0,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
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
                top: Radius.circular(12.0),
                bottom: Radius.circular(12.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.calculate_outlined,
                      color: widget.hasValidationError
                          ? colorScheme.error
                          : colorScheme.primary,
                    ),
                    const SizedBox(width: 12.0),
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
                duration: const Duration(milliseconds: 200),
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
    return Container(
      key: const ValueKey('expanded'),
      width: double.infinity,
      child: Column(
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: widget.expandedContent,
          ),
          if (widget.showCalculateButton) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
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
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
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
    return Container(
      key: const ValueKey('collapsed'),
      width: double.infinity,
      child: Column(
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
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
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && !widget.hasValidationError) {
        autoCollapse();
      }
    });
  }
}

/// Responsive breakpoints for adaptive UI
class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 840;
  static const double desktop = 1200;

  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobile;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobile && width < desktop;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktop;
  }

  static double getCollapsedHeight(BuildContext context) {
    if (isDesktop(context)) return 48.0;
    if (isTablet(context)) return 56.0;
    return 68.0; // Mobile
  }
}