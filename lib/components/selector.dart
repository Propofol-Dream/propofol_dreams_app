import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/design_tokens.dart';

class Selector<T> extends StatelessWidget {
  Selector({
    super.key,
    this.prefixIcon,
    this.labelText,
    this.sheetTitle,
    required this.selectedItem,
    required this.items,
    required this.onItemSelected,
    this.itemLabelBuilder,
    this.itemIconBuilder,
    this.enabled = true,
  });

  final IconData? prefixIcon;
  final String? labelText;
  final String? sheetTitle;
  final T? selectedItem;
  final List<T> items;
  final ValueChanged<T> onItemSelected;
  final String Function(T)? itemLabelBuilder;
  final IconData? Function(T)? itemIconBuilder;
  final bool enabled;

  String _label(T item) =>
      itemLabelBuilder?.call(item) ?? item.toString();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayText =
        selectedItem != null ? _label(selectedItem as T) : '';

    return SizedBox(
      height: 48,
      child: TextField(
        controller: TextEditingController(text: displayText),
        readOnly: true,
        enableInteractiveSelection: false,
        style: TextStyle(
          color: theme.colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: theme.colorScheme.onPrimary,
          labelText: labelText,
          labelStyle: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          floatingLabelStyle: TextStyle(
            color: theme.colorScheme.primary,
          ),
          prefixIcon: prefixIcon != null
              ? Icon(
                  prefixIcon,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                )
              : null,
          suffixIcon: Icon(
            Icons.arrow_drop_down,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: kSp16,
            vertical: kSp12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kRadius),
            borderSide: BorderSide(
              color: theme.colorScheme.outline,
              width: 1.0,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kRadius),
            borderSide: BorderSide(
              color: theme.colorScheme.outline,
              width: 1.0,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kRadius),
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 2.0,
            ),
          ),
        ),
        onTap: enabled
            ? () {
                HapticFeedback.lightImpact();
                _showSheet(context);
              }
            : null,
      ),
    );
  }

  void _showSheet(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(kRadius)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                sheetTitle ?? labelText ?? 'Select',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: items.map((item) {
                  final isSelected = item == selectedItem;
                  final itemIcon = itemIconBuilder?.call(item);
                  return ListTile(
                    leading: itemIcon != null
                        ? Icon(
                            itemIcon,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                            size: 20,
                          )
                        : Icon(
                            isSelected
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                    title: Text(_label(item)),
                    onTap: () {
                      Navigator.pop(context);
                      onItemSelected(item);
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}
