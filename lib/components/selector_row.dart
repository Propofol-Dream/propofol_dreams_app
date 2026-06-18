import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/design_tokens.dart';
import '../models/model.dart';

class SelectorRow extends StatelessWidget {
  const SelectorRow({
    super.key,
    this.prefixIcon,
    this.labelText,
    required this.selectedModel,
    required this.models,
    required this.onModelSelected,
    this.enabled = true,
  });

  final IconData? prefixIcon;
  final String? labelText;
  final Model? selectedModel;
  final List<Model> models;
  final ValueChanged<Model> onModelSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: TextEditingController(text: selectedModel?.name ?? ''),
      readOnly: true,
      decoration: InputDecoration(
        labelText: labelText ?? 'Select Model',
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon)
            : const Icon(Icons.psychology_outlined),
        suffixIcon: const Icon(Icons.arrow_drop_down),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest,
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
              _showModelSheet(context);
            }
          : null,
    );
  }

  void _showModelSheet(BuildContext context) {
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
                'Select Model',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: models.map((model) {
                  final isSelected = model == selectedModel;
                  return ListTile(
                    leading: Icon(
                      isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    title: Text(model.name),
                    onTap: () {
                      Navigator.pop(context);
                      onModelSelected(model);
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