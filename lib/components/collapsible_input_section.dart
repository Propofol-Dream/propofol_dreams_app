import 'package:flutter/material.dart';
import '../config/design_tokens.dart';

class CollapsibleInputSection extends StatefulWidget {
  final Widget summary;
  final Widget child;

  const CollapsibleInputSection({
    super.key,
    required this.summary,
    required this.child,
  });

  @override
  State<CollapsibleInputSection> createState() => _CollapsibleInputSectionState();
}

class _CollapsibleInputSectionState extends State<CollapsibleInputSection> {
  bool _isCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(kRadius),
          onTap: () => setState(() => _isCollapsed = !_isCollapsed),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: kSp16, vertical: 10),
            child: Row(
              children: [
                AnimatedRotation(
                  turns: _isCollapsed ? -0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.chevron_left,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: kSp8),
                Expanded(child: widget.summary),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: widget.child,
          crossFadeState: _isCollapsed
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 300),
          sizeCurve: Curves.fastOutSlowIn,
        ),
      ],
    );
  }
}
