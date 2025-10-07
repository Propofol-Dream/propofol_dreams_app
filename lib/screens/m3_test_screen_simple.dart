import 'package:flutter/material.dart';
import '../components/material3/m3_text_field.dart';
import '../components/legacy/PDTextField.dart';

/// Simplified Material 3 Test Screen
///
/// A basic test environment that demonstrates the Material 3 text field
/// component in comparison to the legacy implementation.
class M3TestScreenSimple extends StatefulWidget {
  const M3TestScreenSimple({super.key});

  @override
  State<M3TestScreenSimple> createState() => _M3TestScreenSimpleState();
}

class _M3TestScreenSimpleState extends State<M3TestScreenSimple> {
  final TextEditingController _ageController = TextEditingController(text: '35');
  final TextEditingController _weightController = TextEditingController(text: '70');
  final TextEditingController _heightController = TextEditingController(text: '175');
  final TextEditingController _targetController = TextEditingController(text: '3.5');

  bool _useMaterial3 = false;
  Set<String> _selectedDrugCategory = {'propofol'};

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  void _toggleComponentType() {
    setState(() {
      _useMaterial3 = !_useMaterial3;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _useMaterial3
            ? 'Now showing Material 3 components'
            : 'Now showing Legacy components',
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _onFieldUpdated() {
    // Handle field updates for calculations
    setState(() {});
  }

  double _getResponsiveHeight() {
    final screenWidth = MediaQuery.of(context).size.width;
    final textScale = MediaQuery.of(context).textScaler.scale(1.0);

    // Base height calculation with responsive scaling
    double baseHeight = 56.0;

    // Adjust for screen width (mobile vs tablet vs desktop)
    if (screenWidth > 1200) {
      // Desktop: Larger touch targets
      baseHeight = 64.0;
    } else if (screenWidth > 600) {
      // Tablet: Medium touch targets
      baseHeight = 60.0;
    } else {
      // Mobile: Standard size but scale with text
      baseHeight = 56.0;
    }

    // Scale with accessibility text size
    baseHeight = baseHeight * textScale.clamp(1.0, 1.5);

    // Ensure minimum usable height for accessibility
    return baseHeight.clamp(56.0, 88.0);
  }

  Widget _buildTextField({
    required IconData icon,
    required String label,
    String? helperText,
    required TextEditingController controller,
    required List<num> range,
    required double interval,
    required int fractionDigits,
  }) {
    if (_useMaterial3) {
      return M3TextField(
        prefixIcon: icon,
        labelText: label,
        helperText: helperText ?? '',
        interval: interval,
        fractionDigits: fractionDigits,
        controller: controller,
        onPressed: _onFieldUpdated,
        range: range,
        // height is now handled by PDTextField responsively
      );
    } else {
      return PDTextField(
        prefixIcon: icon,
        labelText: label,
        helperText: helperText ?? '',
        interval: interval,
        fractionDigits: fractionDigits,
        controller: controller,
        onPressed: _onFieldUpdated,
        range: range,
        // height is now handled by PDTextField responsively
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Material 3 Test Lab'),
        backgroundColor: theme.colorScheme.surfaceContainer,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'M3',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: _useMaterial3
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: _useMaterial3,
                  onChanged: (_) => _toggleComponentType(),
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
            // Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.science,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Component Testing',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Switch between Material 3 and Legacy components to compare behavior, styling, and functionality.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Patient Data Section
            Text(
              'Patient Data',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),

            // Age and Weight Row - Responsive height for alignment
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildTextField(
                    icon: Icons.cake_outlined,
                    label: 'Age (years)',
                    helperText: 'Patient age for calculations',
                    controller: _ageController,
                    range: const [0, 120],
                    interval: 1,
                    fractionDigits: 0,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    icon: Icons.monitor_weight_outlined,
                    label: 'Weight (kg)',
                    helperText: 'Patient weight',
                    controller: _weightController,
                    range: const [1, 200],
                    interval: 1,
                    fractionDigits: 0,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Height and Target Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildTextField(
                    icon: Icons.height_outlined,
                    label: 'Height (cm)',
                    helperText: 'Patient height measurement',
                    controller: _heightController,
                    range: const [50, 250],
                    interval: 1,
                    fractionDigits: 0,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    icon: Icons.my_location_outlined,
                    label: 'Target (µg/ml)',
                    helperText: 'Target plasma concentration',
                    controller: _targetController,
                    range: const [0.5, 10.0],
                    interval: 0.1,
                    fractionDigits: 1,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Drug Selection Section
            Text(
              'Drug Selection',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select drug using connected button groups (Material 3 SegmentedButton)',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            // Material 3 Connected Button Groups - Drug Selection
            SizedBox(
              height: _getResponsiveHeight(),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment<String>(
                    value: 'propofol',
                    label: Text('Propofol'),
                    icon: Icon(Icons.medication_liquid),
                  ),
                  ButtonSegment<String>(
                    value: 'remifentanil',
                    label: Text('Remifentanil'),
                    icon: Icon(Icons.healing),
                  ),
                  ButtonSegment<String>(
                    value: 'dexmedetomidine',
                    label: Text('Dexmedetomidine'),
                    icon: Icon(Icons.medical_services),
                  ),
                ],
                selected: _selectedDrugCategory,
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _selectedDrugCategory = newSelection;
                  });
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return theme.colorScheme.secondaryContainer;
                    }
                    return theme.colorScheme.surfaceContainerHighest;
                  }),
                  foregroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return theme.colorScheme.onSecondaryContainer;
                    }
                    return theme.colorScheme.onSurfaceVariant;
                  }),
                  side: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2.0,
                      );
                    }
                    return BorderSide(
                      color: theme.colorScheme.outline,
                      width: 1.0,
                    );
                  }),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Status Card
            Card(
              color: theme.colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _useMaterial3 ? Icons.new_releases : Icons.history,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _useMaterial3 ? 'Material 3 Mode' : 'Legacy Mode',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _useMaterial3
                        ? 'Currently showing Material 3 components with enhanced styling, animations, and accessibility features.'
                        : 'Currently showing legacy components for comparison. Toggle the switch to see Material 3 variants.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}