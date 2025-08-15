import 'package:flutter/material.dart';
import '../models/drug.dart';
import '../models/model.dart';
import '../models/sex.dart';
import '../models/InfusionUnit.dart';
import '../l10n/generated/app_localizations.dart';

// Forward declaration for ResponsiveBreakpoints
class ResponsiveBreakpoints {
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }
}

/// A widget that displays a compact summary of input parameters
/// for medical calculators when in collapsed state
class InputSummaryDisplay extends StatelessWidget {
  const InputSummaryDisplay({
    super.key,
    required this.calculatorType,
    this.age,
    this.sex,
    this.weight,
    this.height,
    this.drug,
    this.model,
    this.target,
    this.duration,
    this.infusionRate,
    this.infusionUnit,
    this.targetCe,
    this.flow,
    this.maintenanceCe,
  });

  /// Type of calculator for summary formatting
  final CalculatorType calculatorType;

  // Patient parameters
  final int? age;
  final Sex? sex;
  final int? weight;
  final int? height;

  // Drug parameters
  final Drug? drug;
  final Model? model;
  final double? target;
  final int? duration;

  // Duration calculator specific
  final double? infusionRate;
  final InfusionUnit? infusionUnit;

  // EleMarsh specific
  final double? targetCe;
  final String? flow;
  final double? maintenanceCe;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBreakpoints.isMobile(context)
        ? _buildMobileSummary(context)
        : _buildDesktopSummary(context);
  }

  Widget _buildMobileSummary(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFirstRow(context),
        const SizedBox(height: 8.0),
        _buildSecondRow(context),
      ],
    );
  }

  Widget _buildDesktopSummary(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildFirstRow(context)),
        const SizedBox(width: 16.0),
        Expanded(child: _buildSecondRow(context)),
      ],
    );
  }

  Widget _buildFirstRow(BuildContext context) {
    switch (calculatorType) {
      case CalculatorType.tci:
        return Row(
          children: [
            _buildPatientSummary(context),
            const SizedBox(width: 16.0),
            _buildDrugSummary(context),
          ],
        );

      case CalculatorType.volume:
        return Row(
          children: [
            _buildPatientSummary(context),
            const SizedBox(width: 16.0),
            _buildModelSummary(context),
          ],
        );

      case CalculatorType.duration:
        return Row(
          children: [
            _buildWeightSummary(context),
            const SizedBox(width: 16.0),
            _buildInfusionRateSummary(context),
          ],
        );

      case CalculatorType.elemarsh:
        return Row(
          children: [
            _buildPatientSummary(context),
            const SizedBox(width: 16.0),
            _buildTargetCeSummary(context),
          ],
        );
    }
  }

  Widget _buildSecondRow(BuildContext context) {
    switch (calculatorType) {
      case CalculatorType.tci:
        return Row(
          children: [
            _buildModelSummary(context),
            const SizedBox(width: 16.0),
            _buildTargetSummary(context),
            const SizedBox(width: 16.0),
            _buildDurationSummary(context),
          ],
        );

      case CalculatorType.volume:
        return Row(
          children: [
            _buildTargetSummary(context),
            const SizedBox(width: 16.0),
            _buildDurationSummary(context),
            const Spacer(),
            _buildCalculatorIcon(context, Icons.science_outlined),
          ],
        );

      case CalculatorType.duration:
        return Row(
          children: [
            _buildCalculatorIcon(context, Icons.schedule),
            const SizedBox(width: 8.0),
            Text(
              AppLocalizations.of(context)?.duration ?? 'Duration Analysis',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );

      case CalculatorType.elemarsh:
        return Row(
          children: [
            _buildFlowSummary(context),
            const SizedBox(width: 16.0),
            _buildModelSummary(context),
            const Spacer(),
            _buildCalculatorIcon(context, Icons.hub_outlined),
          ],
        );
    }
  }

  Widget _buildPatientSummary(BuildContext context) {
    final patientText = _formatPatientInfo();
    return _buildSummaryItem(
      context,
      icon: Icons.person_outline,
      text: patientText,
      color: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildWeightSummary(BuildContext context) {
    final weightText = weight != null ? '${weight}kg' : '--';
    return _buildSummaryItem(
      context,
      icon: Icons.monitor_weight_outlined,
      text: weightText,
      color: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildDrugSummary(BuildContext context) {
    if (drug == null) return _buildEmptyItem(context, Icons.medication);
    
    return _buildSummaryItem(
      context,
      icon: drug!.icon,
      text: _formatDrugInfo(),
      color: drug!.getColor(context),
    );
  }

  Widget _buildModelSummary(BuildContext context) {
    final modelText = model?.toString() ?? '--';
    return _buildSummaryItem(
      context,
      icon: Icons.psychology,
      text: modelText,
      color: Theme.of(context).colorScheme.secondary,
    );
  }

  Widget _buildTargetSummary(BuildContext context) {
    final targetText = target != null ? '${target!.toStringAsFixed(1)}${_getTargetUnit()}' : '--';
    return _buildSummaryItem(
      context,
      icon: Icons.gps_fixed,
      text: targetText,
      color: Theme.of(context).colorScheme.tertiary,
    );
  }

  Widget _buildDurationSummary(BuildContext context) {
    final durationText = duration != null ? '${duration}min' : '--';
    return _buildSummaryItem(
      context,
      icon: Icons.schedule,
      text: durationText,
      color: Theme.of(context).colorScheme.outline,
    );
  }

  Widget _buildInfusionRateSummary(BuildContext context) {
    if (infusionRate == null || infusionUnit == null) {
      return _buildEmptyItem(context, Icons.water_drop_outlined);
    }

    final rateText = '${infusionRate!.toStringAsFixed(1)} ${infusionUnit!.toString()}';
    return _buildSummaryItem(
      context,
      icon: Icons.water_drop_outlined,
      text: rateText,
      color: Theme.of(context).colorScheme.secondary,
    );
  }

  Widget _buildTargetCeSummary(BuildContext context) {
    final ceText = targetCe != null ? '${targetCe!.toStringAsFixed(1)}Ce' : '--';
    return _buildSummaryItem(
      context,
      icon: Icons.gps_fixed,
      text: ceText,
      color: Theme.of(context).colorScheme.tertiary,
    );
  }

  Widget _buildFlowSummary(BuildContext context) {
    final flowIcon = flow == 'induce' ? Icons.play_arrow : Icons.tune;
    final flowText = flow ?? '--';
    return _buildSummaryItem(
      context,
      icon: flowIcon,
      text: flowText,
      color: Theme.of(context).colorScheme.secondary,
    );
  }

  Widget _buildCalculatorIcon(BuildContext context, IconData icon) {
    return Icon(
      icon,
      size: 20,
      color: Theme.of(context).colorScheme.outline,
    );
  }

  Widget _buildSummaryItem(
    BuildContext context, {
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 4.0),
        Flexible(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyItem(BuildContext context, IconData icon) {
    return _buildSummaryItem(
      context,
      icon: icon,
      text: '--',
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }

  String _formatPatientInfo() {
    final List<String> parts = [];
    
    if (age != null) parts.add('${age}y');
    if (sex != null) parts.add(sex == Sex.Male ? 'M' : 'F');
    if (weight != null) parts.add('${weight}kg');
    if (height != null && calculatorType == CalculatorType.tci) {
      parts.add('${height}cm');
    }
    
    return parts.isEmpty ? '--' : parts.join('/');
  }

  String _formatDrugInfo() {
    if (drug == null) return '--';
    
    final concentration = drug!.concentration;
    final unit = drug!.concentrationUnit.displayName;
    final name = drug!.displayName;
    
    final concentrationStr = concentration < 1 
        ? concentration.toStringAsFixed(1) 
        : concentration.toStringAsFixed(0);
    
    return '$name $concentrationStr$unit';
  }

  String _getTargetUnit() {
    if (drug != null) {
      return drug!.targetUnit.displayName;
    }
    return 'μg/mL'; // Default unit
  }
}

/// Enum for different calculator types
enum CalculatorType {
  tci,
  volume,
  duration,
  elemarsh,
}

/// Extension to get calculator type display names
extension CalculatorTypeExtension on CalculatorType {
  String getDisplayName(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    switch (this) {
      case CalculatorType.tci:
        return localizations?.tci ?? 'TCI';
      case CalculatorType.volume:
        return localizations?.volume ?? 'Volume';
      case CalculatorType.duration:
        return localizations?.duration ?? 'Duration';
      case CalculatorType.elemarsh:
        return 'EleMarsh';
    }
  }

  IconData getIcon() {
    switch (this) {
      case CalculatorType.tci:
        return Icons.ssid_chart;
      case CalculatorType.volume:
        return Icons.science_outlined;
      case CalculatorType.duration:
        return Icons.schedule;
      case CalculatorType.elemarsh:
        return Icons.hub_outlined;
    }
  }
}