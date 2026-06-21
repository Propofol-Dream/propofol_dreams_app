import 'package:flutter/material.dart';
import '../config/design_tokens.dart';

class CollapsibleInputSection extends StatefulWidget {
  final Widget child;
  final List<Widget>? collapsedChips;
  final ValueChanged<bool>? onCollapsedChanged;

  const CollapsibleInputSection({
    super.key,
    required this.child,
    this.collapsedChips,
    this.onCollapsedChanged,
  });

  @override
  State<CollapsibleInputSection> createState() => _CollapsibleInputSectionState();
}

class _CollapsibleInputSectionState extends State<CollapsibleInputSection> {
  bool _isCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity == null) return;
        final wasCollapsed = _isCollapsed;
        if (details.primaryVelocity! > 300) {
          _isCollapsed = true;
        } else if (details.primaryVelocity! < -300) {
          _isCollapsed = false;
        }
        if (wasCollapsed != _isCollapsed) {
          setState(() {});
          widget.onCollapsedChanged?.call(_isCollapsed);
        }
      },
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 24,
              child: Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: _isCollapsed ? 1.0 : 0.0,
              child: _isCollapsed && widget.collapsedChips != null
                  ? Padding(
                      padding: const EdgeInsets.only(left: kSp16, right: kSp16, bottom: kSp8),
                      child: Wrap(
                        spacing: kSp8,
                        runSpacing: kSp4,
                        children: widget.collapsedChips!,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: Alignment.bottomCenter,
              child: _isCollapsed
                  ? const SizedBox(height: 0)
                  : widget.child,
            ),
          ],
        ),
      ),
    );
  }
}