import 'package:flutter/material.dart';

enum PDInputStatusType { none, error, warning, info }

class PDInputControlFrame extends StatelessWidget {
  const PDInputControlFrame({
    super.key,
    required this.child,
    this.statusText,
    this.statusType = PDInputStatusType.none,
    this.controlHeight = 56,
    this.statusHeight = 24,
    this.statusIcon,
  });

  final Widget child;
  final String? statusText;
  final PDInputStatusType statusType;
  final double controlHeight;
  final double statusHeight;
  final IconData? statusIcon;

  bool get _hasStatus =>
      statusText != null &&
      statusText!.trim().isNotEmpty &&
      statusType != PDInputStatusType.none;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textScaler = MediaQuery.of(context).textScaler.clamp(
          minScaleFactor: 1.0,
          maxScaleFactor: 1.3,
        );
    final color = switch (statusType) {
      PDInputStatusType.error => theme.colorScheme.error,
      PDInputStatusType.warning => theme.colorScheme.tertiary,
      PDInputStatusType.info => theme.colorScheme.primary,
      PDInputStatusType.none => theme.colorScheme.onSurfaceVariant,
    };
    final icon = statusIcon ??
        switch (statusType) {
          PDInputStatusType.error => Icons.error_outline,
          PDInputStatusType.warning => Icons.warning_amber_outlined,
          PDInputStatusType.info => Icons.info_outline,
          PDInputStatusType.none => null,
        };

    return SizedBox(
      height: controlHeight + statusHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: controlHeight,
            width: double.infinity,
            child: child,
          ),
          SizedBox(
            height: statusHeight,
            width: double.infinity,
            child: _hasStatus
                ? Semantics(
                    label: '${statusType.name}: ${statusText!.trim()}',
                    liveRegion: statusType == PDInputStatusType.error,
                    child: ExcludeSemantics(
                      child: Row(
                        children: [
                          if (icon != null) ...[
                            Icon(icon, size: 14, color: color),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              statusText!.trim(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textScaler: textScaler,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: color,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
