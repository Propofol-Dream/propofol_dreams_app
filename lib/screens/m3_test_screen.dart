import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/ui_config.dart';
import '../components/material3/m3_text_field.dart';
import '../components/material3/m3_dropdown_menu.dart';
import '../components/adaptive_text_field.dart';
import '../components/adaptive_dropdown.dart';
import '../components/legacy/PDAdvancedSegmentedController.dart';
import '../components/legacy/PDSwitchController.dart';
import '../providers/settings.dart';
import '../models/drug.dart';
import '../models/model.dart';
import '../l10n/generated/app_localizations.dart';

/// Test screen to showcase Material 3 components
///
/// This screen demonstrates all the new Material 3 components in action,
/// allowing for visual comparison and testing of the new design system.
class M3TestScreen extends StatefulWidget {
  const M3TestScreen({super.key});

  @override
  State<M3TestScreen> createState() => _M3TestScreenState();
}

class _M3TestScreenState extends State<M3TestScreen> {
  // Controllers for testing components
  final TextEditingController _ageController = TextEditingController(text: '35');
  final TextEditingController _weightController = TextEditingController(text: '70');
  final TextEditingController _heightController = TextEditingController(text: '175');
  final TextEditingController _targetController = TextEditingController(text: '3.5');
  final TextEditingController _durationController = TextEditingController(text: '60');

  final PDAdvancedSegmentedController _modelController = PDAdvancedSegmentedController();
  final PDSwitchController _sexController = PDSwitchController();

  bool _m3Enabled = false;
  Drug _selectedDrug = Drug.propofol20mg;
  bool _controllersDisposed = false;

  @override
  void initState() {
    super.initState();
    _modelController.selection = Model.Marsh;
    _sexController.val = false;
  }

  @override
  void dispose() {
    // Only dispose controllers if they haven't been disposed already
    if (!_controllersDisposed) {
      _ageController.dispose();
      _weightController.dispose();
      _heightController.dispose();
      _targetController.dispose();
      _durationController.dispose();
      _controllersDisposed = true;
    }
    super.dispose();
  }

  void _toggleM3() {
    setState(() {
      _m3Enabled = !_m3Enabled;
    });

    // Show snackbar with current state
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _m3Enabled
            ? 'Material 3 components enabled'
            : 'Legacy components enabled',
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _onModelSelected() {
    setState(() {
      // Trigger rebuild to show changes
    });
  }

  void _onFieldUpdated() {
    setState(() {
      // Trigger rebuild for validation
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<Settings>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Material 3 Test Lab'),
        backgroundColor: theme.colorScheme.surfaceContainer,
        actions: [
          // Toggle switch for M3 vs Legacy
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'M3',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: _m3Enabled
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: _m3Enabled,
                  onChanged: (_) => _toggleM3(),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.science_outlined,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Component Test Laboratory',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Toggle the switch above to compare Material 3 components with legacy implementations. '
                      'All components maintain identical functionality while showcasing modern design patterns.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Status indicators
                    Wrap(
                      spacing: 12,
                      children: [
                        _StatusChip(
                          label: _m3Enabled ? 'Material 3' : 'Legacy',
                          color: _m3Enabled
                            ? theme.colorScheme.primary
                            : theme.colorScheme.tertiary,
                        ),
                        _StatusChip(
                          label: 'Safe Migration',
                          color: theme.colorScheme.secondary,
                        ),
                        _StatusChip(
                          label: 'Medical Grade',
                          color: theme.colorScheme.error,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Text Field Components Section
            _SectionHeader(
              title: 'Text Field Components',
              subtitle: 'Input fields with increment/decrement controls',
              icon: Icons.edit_outlined,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _m3Enabled
                    ? M3TextField(
                        prefixIcon: Icons.person_outline,
                        labelText: 'Age (years)',
                        helperText: 'Patient age for calculations',
                        interval: 1,
                        fractionDigits: 0,
                        controller: _ageController,
                        onPressed: _onFieldUpdated,
                        range: const [0, 120],
                      )
                    : AdaptiveTextField(
                        prefixIcon: Icons.person_outline,
                        labelText: 'Age (years)',
                        helperText: 'Patient age for calculations',
                        interval: 1,
                        fractionDigits: 0,
                        controller: _ageController,
                        onPressed: _onFieldUpdated,
                        range: const [0, 120],
                      ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _m3Enabled
                    ? M3TextField(
                        prefixIcon: Icons.monitor_weight_outlined,
                        labelText: 'Weight (kg)',
                        interval: 1,
                        fractionDigits: 0,
                        controller: _weightController,
                        onPressed: _onFieldUpdated,
                        range: const [1, 200],
                      )
                    : AdaptiveTextField(
                        prefixIcon: Icons.monitor_weight_outlined,
                        labelText: 'Weight (kg)',
                        interval: 1,
                        fractionDigits: 0,
                        controller: _weightController,
                        onPressed: _onFieldUpdated,
                        range: const [1, 200],
                      ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _m3Enabled
                    ? M3TextField(
                        prefixIcon: Icons.height_outlined,
                        labelText: 'Height (cm)',
                        interval: 1,
                        fractionDigits: 0,
                        controller: _heightController,
                        onPressed: _onFieldUpdated,
                        range: const [100, 250],
                      )
                    : AdaptiveTextField(
                        prefixIcon: Icons.height_outlined,
                        labelText: 'Height (cm)',
                        interval: 1,
                        fractionDigits: 0,
                        controller: _heightController,
                        onPressed: _onFieldUpdated,
                        range: const [100, 250],
                      ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _m3Enabled
                    ? M3TextField(
                        prefixIcon: Icons.gps_fixed,
                        labelText: 'Target (mcg/ml)',
                        interval: 0.1,
                        fractionDigits: 1,
                        controller: _targetController,
                        onPressed: _onFieldUpdated,
                        range: const [0.5, 10.0],
                      )
                    : AdaptiveTextField(
                        prefixIcon: Icons.gps_fixed,
                        labelText: 'Target (mcg/ml)',
                        interval: 0.1,
                        fractionDigits: 1,
                        controller: _targetController,
                        onPressed: _onFieldUpdated,
                        range: const [0.5, 10.0],
                      ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Dropdown Components Section
            _SectionHeader(
              title: 'Dropdown Components',
              subtitle: 'Model selection with validation',
              icon: Icons.arrow_drop_down_circle_outlined,
            ),
            const SizedBox(height: 16),

            _m3Enabled
              ? M3DropdownMenu(
                  controller: _modelController,
                  inAdultView: true,
                  sexController: _sexController,
                  ageController: _ageController,
                  heightController: _heightController,
                  weightController: _weightController,
                  targetController: _targetController,
                  durationController: _durationController,
                  onModelSelected: _onModelSelected,
                  currentDrug: _selectedDrug,
                  isTCIScreen: true,
                  labelText: 'Pharmacokinetic Model',
                  helperText: 'Select appropriate model for patient',
                )
              : AdaptiveDropdown(
                  controller: _modelController,
                  inAdultView: true,
                  sexController: _sexController,
                  ageController: _ageController,
                  heightController: _heightController,
                  weightController: _weightController,
                  targetController: _targetController,
                  durationController: _durationController,
                  onModelSelected: _onModelSelected,
                  currentDrug: _selectedDrug,
                  isTCIScreen: true,
                  labelText: 'Pharmacokinetic Model',
                ),

            const SizedBox(height: 24),

            // Drug Selection Section
            _SectionHeader(
              title: 'Drug Selection',
              subtitle: 'Choose drug to see compatible models',
              icon: Icons.medication_outlined,
            ),
            const SizedBox(height: 16),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: Drug.values.take(4).map((drug) {
                final isSelected = drug == _selectedDrug;
                return FilterChip(
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedDrug = drug;
                        _modelController.selection = Model.Marsh; // Reset model selection
                      });
                    }
                  },
                  label: Text(drug.displayName),
                  avatar: Icon(
                    drug.icon,
                    size: 18,
                    color: isSelected
                      ? theme.colorScheme.onSecondaryContainer
                      : theme.colorScheme.primary,
                  ),
                  backgroundColor: isSelected
                    ? theme.colorScheme.secondaryContainer
                    : null,
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            // Feature Comparison Section
            _SectionHeader(
              title: 'Design System Comparison',
              subtitle: 'Key improvements in Material 3',
              icon: Icons.compare_arrows_outlined,
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _ComparisonRow(
                      feature: 'Color System',
                      legacy: 'Custom colors',
                      material3: 'Dynamic color tokens',
                      isM3Better: true,
                    ),
                    const Divider(),
                    _ComparisonRow(
                      feature: 'Accessibility',
                      legacy: 'Basic support',
                      material3: 'Enhanced navigation',
                      isM3Better: true,
                    ),
                    const Divider(),
                    _ComparisonRow(
                      feature: 'Touch Targets',
                      legacy: '44px minimum',
                      material3: '48px minimum',
                      isM3Better: true,
                    ),
                    const Divider(),
                    _ComparisonRow(
                      feature: 'Visual Feedback',
                      legacy: 'Static states',
                      material3: 'Animated transitions',
                      isM3Better: true,
                    ),
                    const Divider(),
                    _ComparisonRow(
                      feature: 'Medical Safety',
                      legacy: 'Proven stable',
                      material3: 'Identical calculations',
                      isM3Better: false,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Configuration Status
            _SectionHeader(
              title: 'Migration Configuration',
              subtitle: 'Current feature flag status',
              icon: Icons.settings_outlined,
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _ConfigRow('Global M3 Components', UIConfig.useMaterial3Components),
                    _ConfigRow('M3 Text Fields', UIConfig.useMaterial3TextField),
                    _ConfigRow('M3 Dropdown Menus', UIConfig.useMaterial3DropdownMenu),
                    _ConfigRow('Emergency Fallback', UIConfig.emergencyFallbackActive),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'All flags are currently set to false for production safety. '
                              'Enable in lib/config/ui_config.dart when ready for testing.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(
        color: color.withValues(alpha: 0.3),
        width: 1,
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.feature,
    required this.legacy,
    required this.material3,
    required this.isM3Better,
  });

  final String feature;
  final String legacy;
  final String material3;
  final bool isM3Better;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              feature,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              legacy,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    material3,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                if (isM3Better) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.trending_up,
                    color: theme.colorScheme.primary,
                    size: 16,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfigRow extends StatelessWidget {
  const _ConfigRow(this.label, this.value);

  final String label;
  final bool value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: value
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value ? 'Enabled' : 'Disabled',
              style: theme.textTheme.labelSmall?.copyWith(
                color: value
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}