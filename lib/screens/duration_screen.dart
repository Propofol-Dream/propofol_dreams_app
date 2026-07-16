import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:propofol_dreams_app/l10n/generated/app_localizations.dart';
import '../utils/responsive_helper.dart';
import '../utils/intents.dart';

import 'package:propofol_dreams_app/constants.dart';
import 'package:propofol_dreams_app/config/design_tokens.dart';
import 'package:propofol_dreams_app/models/InfusionUnit.dart';
import 'package:propofol_dreams_app/components/infusion_regime_table.dart';
import 'package:propofol_dreams_app/components/pk_field.dart';
import 'package:propofol_dreams_app/components/collapsible_input_section.dart';

import '../providers/settings.dart';

class DurationScreen extends StatefulWidget {
  const DurationScreen({super.key});

  @override
  State<DurationScreen> createState() => _DurationScreenState();
}

class _DurationScreenState extends State<DurationScreen> {
  final TextEditingController weightController = TextEditingController();
  final TextEditingController infusionRateController = TextEditingController();
  int _selectedUnitIndex = 0;
  final ScrollController tableScrollController = ScrollController();

  List<DurationRowData> durationRows = [];
  bool _didRunInitialCalculation = false;

  List<InfusionUnit> infusionUnits = [
    InfusionUnit.mg_kg_hr,
    InfusionUnit.mcg_kg_min,
    InfusionUnit.mL_hr
  ];

  int infusionRateDecimal = 1;
  Timer _debounceTimer = Timer(Duration.zero, () {});
  static const Duration _debounceDelay = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();

    // Settings are already loaded - initialize controllers with final values
    final settings = context.read<Settings>();
    _setControllersFromSettings(settings);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didRunInitialCalculation) return;
    _didRunInitialCalculation = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) run();
    });
  }

  void _setControllersFromSettings(Settings settings) {
    weightController.text = settings.weight?.toString() ?? '';
    _selectedUnitIndex = settings.infusionUnit == InfusionUnit.mg_kg_hr
        ? 0
        : settings.infusionUnit == InfusionUnit.mcg_kg_min
            ? 1
            : 2;
    infusionRateDecimal =
        infusionUnits[_selectedUnitIndex] == InfusionUnit.mg_kg_hr
            ? 1
            : infusionUnits[_selectedUnitIndex] == InfusionUnit.mcg_kg_min
                ? 0
                : 1;
    infusionRateController.text =
        settings.infusionRate?.toStringAsFixed(infusionRateDecimal) ?? '';
  }

  void updateWeight() {
    final settings = context.read<Settings>();
    settings.weight = int.tryParse(weightController.text);
    run();
  }

  void updateInfusionRate() {
    final settings = context.read<Settings>();
    settings.infusionRate = double.tryParse(infusionRateController.text) ?? 0;
    run();
  }

  double convertInfusionRate(
      {required int weight,
      required double infusionRate,
      required InfusionUnit previous,
      required InfusionUnit current}) {
    var settings = context.read<Settings>();

    if (previous == InfusionUnit.mg_kg_hr &&
        current == InfusionUnit.mcg_kg_min) {
      return infusionRate * 1000 / 60;
    } else if (previous == InfusionUnit.mcg_kg_min &&
        current == InfusionUnit.mg_kg_hr) {
      return infusionRate / 1000 * 60;
    } else if (previous == InfusionUnit.mg_kg_hr &&
        current == InfusionUnit.mL_hr) {
      return infusionRate * weight / settings.propofol_concentration;
    } else if (previous == InfusionUnit.mL_hr &&
        current == InfusionUnit.mg_kg_hr) {
      return infusionRate / weight * settings.propofol_concentration;
    } else if (previous == InfusionUnit.mL_hr &&
        current == InfusionUnit.mcg_kg_min) {
      return infusionRate /
          weight *
          settings.propofol_concentration *
          1000 /
          60;
    } else if (previous == InfusionUnit.mcg_kg_min &&
        current == InfusionUnit.mL_hr) {
      return infusionRate *
          weight /
          settings.propofol_concentration /
          1000 *
          60;
    } else {
      return 0;
    }
  }

  void updateInfusionUnit() {
    final settings = context.read<Settings>();

    //update Infusion Rate if conditions met
    InfusionUnit previous = settings.infusionUnit;
    InfusionUnit current = infusionUnits[_selectedUnitIndex];
    infusionRateDecimal =
        infusionUnits[_selectedUnitIndex] == InfusionUnit.mg_kg_hr
            ? 1
            : infusionUnits[_selectedUnitIndex] == InfusionUnit.mcg_kg_min
                ? 0
                : 1;

    int? weight = int.tryParse(weightController.text);
    double? infusionRate = double.tryParse(infusionRateController.text);
    if (previous != current && weight != null && infusionRate != null) {
      settings.infusionRate = convertInfusionRate(
          weight: weight,
          infusionRate: infusionRate,
          previous: previous,
          current: current);
      infusionRateController.text =
          settings.infusionRate!.toStringAsFixed(infusionRateDecimal);
    }

    settings.infusionUnit = infusionUnits[_selectedUnitIndex];
    run();
  }

  double calculate(
      {required int volume,
      int? weight,
      required double infusionRate,
      required InfusionUnit infusionUnit,
      required double concentration}) {
    double res = 0.0;
    if (infusionUnit == InfusionUnit.mg_kg_hr) {
      res = volume * concentration / weight! / infusionRate * 60;
    } else if (infusionUnit == InfusionUnit.mcg_kg_min) {
      res = volume * concentration / weight! / infusionRate * 1000;
    } else if (infusionUnit == InfusionUnit.mL_hr) {
      res = volume / infusionRate * 60;
    }
    return res;
  }

  bool isRunnable(
      {int? weight, double? infusionRate, required InfusionUnit infusionUnit}) {
    return infusionUnit == InfusionUnit.mL_hr
        ? infusionRate != null
        : (weight != null && infusionRate != null);
  }

  void run({bool collapseInput = false}) {
    int? weight = int.tryParse(weightController.text);
    double? infusionRate = double.tryParse(infusionRateController.text);
    InfusionUnit infusionUnit = infusionUnits[_selectedUnitIndex];
    final settings = context.read<Settings>();

    if (isRunnable(
        weight: weight,
        infusionRate: infusionRate,
        infusionUnit: infusionUnit)) {
      List<DurationRowData> durations = [];
      var height = MediaQuery.of(context).size.height;
      List<int> volumes = height >= screenBreakPoint2
          ? [60, 50, 40, 30, 20, 10]
          : height >= screenBreakPoint1
              ? [60, 50, 40, 30, 20, 10]
              : [50, 20];
      for (int i = 0; i < volumes.length; i++) {
        double duration = calculate(
            volume: volumes[i],
            weight: weight,
            infusionRate: infusionRate!,
            infusionUnit: infusionUnit,
            concentration: settings.propofol_concentration);

        // Highlight volumes 50mL and 20mL (commonly used sizes)
        bool isHighlighted = volumes[i] == 50 || volumes[i] == 20;

        durations.add(
          DurationRowData(
            volume: volumes[i],
            duration: duration,
            isHighlighted: isHighlighted,
          ),
        );
      }

      setState(() {
        durationRows = durations;
      });
      settings.statusBarInfo =
          'Rate: ${infusionRate!.toStringAsFixed(infusionRateDecimal)} ${infusionUnit.toString()} · Weight: ${weight ?? '—'}kg';
    } else {
      setState(() {
        durationRows = [];
      });
      settings.statusBarInfo = null;
    }
  }

  @override
  void dispose() {
    _debounceTimer.cancel();
    tableScrollController.dispose();
    super.dispose();
  }

  List<String> _validate() {
    final errors = <String>[];
    final weight = int.tryParse(weightController.text);
    final rate = double.tryParse(infusionRateController.text);
    if (weight != null && (weight < 0 || weight > 250)) {
      errors.add('Weight 0-250 kg');
    }
    if (rate != null && (rate < 1 || rate > 9999)) {
      errors.add('Rate 1-9999');
    }
    return errors;
  }

  Widget _buildErrorPanel(List<String> errors) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: errors.isEmpty
          ? const SizedBox.shrink()
          : SizedBox(
              height: 48,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: kSp8, vertical: 8),
                child: Text(
                  errors.first,
                  style: TextStyle(
                      fontSize: 12, color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
    );
  }

  /// Input fields widget used as input panel content.
  Widget _buildInputFields(Settings settings) {
    final theme = Theme.of(context);
    final errors = _validate();
    final weightEnabled =
        infusionUnits[_selectedUnitIndex] != InfusionUnit.mL_hr;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildErrorPanel(errors),
        const SizedBox(height: kSp12),
        // Weight
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: kSp8),
          child: Row(
            children: [
              Expanded(
                child: PKField(
                  prefixIcon: Icons.monitor_weight_outlined,
                  labelText: '${AppLocalizations.of(context)!.weight} (kg)',
                  controller: weightController,
                  fractionDigits: 0,
                  interval: 1.0,
                  range: const [0, 250],
                  enabled: weightEnabled,
                  onChanged: () {
                    _debounceTimer.cancel();
                    _debounceTimer = Timer(_debounceDelay, updateWeight);
                  },
                  hasError: errors.isNotEmpty,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: kSp12),
        // Infusion rate
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: kSp8),
          child: Row(
            children: [
              Expanded(
                child: PKField(
                  prefixIcon: Icons.water_drop_outlined,
                  labelText:
                      '${AppLocalizations.of(context)!.infusionRate} (${infusionUnits[_selectedUnitIndex].toString()})',
                  controller: infusionRateController,
                  fractionDigits: infusionRateDecimal,
                  interval:
                      infusionUnits[_selectedUnitIndex] == InfusionUnit.mg_kg_hr
                          ? 0.5
                          : infusionUnits[_selectedUnitIndex] ==
                                  InfusionUnit.mcg_kg_min
                              ? 10.0
                              : 1.0,
                  range: const [1, 9999],
                  onChanged: () {
                    _debounceTimer.cancel();
                    _debounceTimer = Timer(_debounceDelay, updateInfusionRate);
                  },
                  hasError: errors.isNotEmpty,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: kSp12),
        // Infusion unit button group
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: kSp8),
          child: SizedBox(
            height: 48,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(infusionUnits.length, (i) {
                final selected = _selectedUnitIndex == i;
                return Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      backgroundColor: selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onPrimary,
                      foregroundColor: selected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.horizontal(
                          left: Radius.circular(i == 0 ? kRadius : 0),
                          right: Radius.circular(
                              i == infusionUnits.length - 1 ? kRadius : 0),
                        ),
                        side: BorderSide(color: theme.colorScheme.outline),
                      ),
                    ),
                    onPressed: () {
                      setState(() => _selectedUnitIndex = i);
                      updateInfusionUnit();
                    },
                    child: Text(infusionUnits[i].toString(),
                        style: const TextStyle(fontSize: 12)),
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: kSp12),
      ],
    );
  }

  Widget _buildInputPanel(Settings settings) {
    final useMobile = ResponsiveHelper.shouldUseMobileLayout(context);
    if (!useMobile) {
      return Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
        ),
        child: _buildInputFields(settings),
      );
    }
    return CollapsibleInputSection(
      child: _buildInputFields(settings),
      collapsedChipRows: _buildCollapsedChips(),
    );
  }

  List<List<Widget>> _buildCollapsedChips() {
    final errors = _validate();
    final theme = Theme.of(context);
    final weightText = weightController.text;
    final rateText = infusionRateController.text;

    Widget chip({
      required String displayValue,
      required String emptyLabel,
      required IconData icon,
      required bool isEmpty,
      required bool hasError,
    }) {
      final chipColor = hasError
          ? theme.colorScheme.error
          : (isEmpty ? theme.colorScheme.outline : null);
      final bgColor = hasError
          ? theme.colorScheme.errorContainer.withValues(alpha: 0.5)
          : null;
      return Chip(
        avatar: Icon(hasError ? Icons.error_outline : icon,
            size: 16, color: chipColor),
        label: Text(isEmpty ? emptyLabel : displayValue,
            style: TextStyle(fontSize: 11, color: chipColor)),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        backgroundColor: bgColor,
      );
    }

    return [
      [
        chip(
          displayValue: '${weightText}kg',
          emptyLabel: 'Weight',
          icon: Icons.monitor_weight,
          isEmpty: weightText.isEmpty,
          hasError: errors.any((e) => e.startsWith('Weight')),
        ),
        chip(
          displayValue:
              '$rateText ${infusionUnits[_selectedUnitIndex].toString()}',
          emptyLabel: 'Rate',
          icon: Icons.water_drop,
          isEmpty: rateText.isEmpty,
          hasError: errors.any((e) => e.startsWith('Rate')),
        ),
      ],
    ];
  }

  /// Results table section.
  Widget _buildResultsTable(Settings settings, double mediaQueryHeight) {
    return DurationDataTable(
      rows: durationRows,
      maxVisibleRows: mediaQueryHeight >= screenBreakPoint1 ? 6 : 2,
      scrollController: tableScrollController,
      selectedRowIndex: settings.selectedDurationTableRow,
      onRowTap: (index) {
        if (settings.selectedDurationTableRow == index) {
          settings.selectedDurationTableRow = null;
        } else {
          settings.selectedDurationTableRow = index;
        }
      },
    );
  }

  /// Desktop/tablet 2-column layout: results on left, input panel on right (393px).
  Widget _buildDesktopLayout(Settings settings) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: horizontalSidesPaddingPixel,
          right: horizontalSidesPaddingPixel,
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 12),
                child: _buildResultsTable(
                    settings, MediaQuery.of(context).size.height),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 393,
              child: _buildInputPanel(settings),
            ),
          ],
        ),
      ),
    );
  }

  /// Wraps [child] in [Shortcuts] + [Actions] for Enter=run() on desktop/web.
  Widget _wrapWithKeyboardShortcuts(Widget child) {
    final enable = ResponsiveHelper.isDesktop(context) || kIsWeb;
    if (!enable) return child;
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): CalculateIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          CalculateIntent: CallbackAction<CalculateIntent>(
            onInvoke: (intent) {
              run();
              return null;
            },
          ),
        },
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktopLayout = ResponsiveHelper.isDesktop(context);
    final isTabletLayout =
        ResponsiveHelper.isTablet(context) && !isDesktopLayout;

    final settings = context.watch<Settings>();

    infusionRateDecimal =
        infusionUnits[_selectedUnitIndex] == InfusionUnit.mg_kg_hr
            ? 1
            : infusionUnits[_selectedUnitIndex] == InfusionUnit.mcg_kg_min
                ? 0
                : 1;

    if (isDesktopLayout) {
      return _wrapWithKeyboardShortcuts(_buildDesktopLayout(settings));
    }
    if (isTabletLayout) {
      return _wrapWithKeyboardShortcuts(_buildDesktopLayout(settings));
    }

    // Mobile: fixed-bottom input panel with results above
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: true,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: horizontalSidesPaddingPixel,
                      right: horizontalSidesPaddingPixel,
                      bottom: 12,
                    ),
                    child: Column(
                      children: [
                        const Spacer(),
                        _buildResultsTable(
                            settings, MediaQuery.of(context).size.height),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: _buildInputPanel(settings),
          ),
        ],
      ),
    );
  }
}
