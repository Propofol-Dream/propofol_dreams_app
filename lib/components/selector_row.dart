import 'package:flutter/material.dart';
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

    return DropdownMenu<Model>(
      initialSelection: selectedModel,
      controller: TextEditingController(
        text: selectedModel?.name ?? '',
      ),
      enableFilter: true,
      enableSearch: true,
      enabled: enabled,
      label: Text(labelText ?? 'Select Model'),
      leadingIcon: prefixIcon != null
          ? Icon(prefixIcon)
          : const Icon(Icons.psychology_outlined),
      inputDecorationTheme: theme.inputDecorationTheme.copyWith(
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
      menuStyle: MenuStyle(
        elevation: WidgetStateProperty.all(kElev8),
        backgroundColor: WidgetStateProperty.all(
          theme.colorScheme.surfaceContainerLow,
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadius),
          ),
        ),
      ),
      dropdownMenuEntries: models.map((model) {
        return DropdownMenuEntry<Model>(
          value: model,
          label: model.name,
          leadingIcon: Icon(
            Icons.check_circle,
            color: theme.colorScheme.primary,
            size: 20,
          ),
        );
      }).toList(),
      onSelected: (Model? model) {
        if (model != null) {
          onModelSelected(model);
        }
      },
    );
  }
}
