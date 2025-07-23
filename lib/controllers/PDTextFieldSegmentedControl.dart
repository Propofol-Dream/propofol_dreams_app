import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'PDSegmentedController.dart';

/// A TextField-based segmented control that provides better alignment consistency
/// with other TextField components in the app
class PDTextFieldSegmentedControl extends StatefulWidget {
  const PDTextFieldSegmentedControl({
    super.key,
    required this.labels,
    required this.segmentedController,
    required this.onPressed,
    this.fontSize = 14,
    this.height = 56,
    this.helperText = '',
    this.labelText,
    this.prefixIcon,
    this.enabled = true,
  });

  final List<String> labels;
  final PDSegmentedController segmentedController;
  final List<VoidCallback?> onPressed;
  final double fontSize;
  final double height;
  final String helperText;
  final String? labelText;
  final IconData? prefixIcon;
  final bool enabled;

  @override
  State<PDTextFieldSegmentedControl> createState() => _PDTextFieldSegmentedControlState();
}

class _PDTextFieldSegmentedControlState extends State<PDTextFieldSegmentedControl> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _updateTextController();
    widget.segmentedController.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.segmentedController.removeListener(_onControllerChanged);
    _textController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    _updateTextController();
    if (mounted) setState(() {});
  }

  void _updateTextController() {
    final selectedText = widget.segmentedController.val < widget.labels.length 
        ? widget.labels[widget.segmentedController.val]
        : widget.labels.first;
    _textController.text = selectedText;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Stack(
      children: [
        // Background TextField for consistent styling - following PDAdvancedSegmentedControl pattern
        SizedBox(
          width: double.infinity,
          child: TextField(
            enabled: false,
            decoration: InputDecoration(
              filled: true,
              fillColor: theme.colorScheme.onPrimary,
              helperText: widget.helperText.isNotEmpty ? widget.helperText : null,
              helperStyle: const TextStyle(fontSize: 10),
              border: const OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                ),
              ),
              prefixIcon: widget.prefixIcon != null 
                  ? Icon(
                      widget.prefixIcon,
                      color: theme.colorScheme.primary,
                    )
                  : null,
              labelText: widget.labelText,
              labelStyle: TextStyle(
                color: theme.colorScheme.primary,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            ),
          ),
        ),
        // Segmented control buttons - following PDAdvancedSegmentedControl pattern
        Positioned.fill(
          child:  Row(
              children: List.generate(widget.labels.length, (index) {
                final isSelected = widget.segmentedController.val == index;
                final isFirst = index == 0;
                final isLast = index == widget.labels.length - 1;
                
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.enabled && widget.onPressed[index] != null 
                        ? () async {
                            await HapticFeedback.lightImpact();
                            widget.segmentedController.val = index;
                            widget.onPressed[index]!();
                          }
                        : null,
                    child: Container(
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? theme.colorScheme.primary 
                            : theme.colorScheme.onPrimary,
                        border: Border.all(
                          color: theme.colorScheme.primary,
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(isFirst ? 5 : 0),
                          bottomLeft: Radius.circular(isFirst ? 5 : 0),
                          topRight: Radius.circular(isLast ? 5 : 0),
                          bottomRight: Radius.circular(isLast ? 5 : 0),
                        ),
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0), // Match PDAdvancedSegmentedControl padding
                          child: Text(
                            widget.labels[index],
                            style: TextStyle(
                              fontSize: widget.fontSize,
                              fontWeight: FontWeight.w500,
                              color: isSelected 
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

      ],
    );
  }

}