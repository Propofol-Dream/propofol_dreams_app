import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:propofol_dreams_app/l10n/generated/app_localizations.dart';
import '../utils/responsive_helper.dart';
import '../utils/intents.dart';

import 'package:propofol_dreams_app/constants.dart';
import 'package:propofol_dreams_app/config/design_tokens.dart';
import 'package:propofol_dreams_app/components/legacy/PDTextField.dart';
import 'package:propofol_dreams_app/components/legacy/PDSegmentedController.dart';
import 'package:propofol_dreams_app/components/legacy/PDSegmentedControl.dart';
import 'package:propofol_dreams_app/models/InfusionUnit.dart';
import 'package:propofol_dreams_app/components/infusion_regime_table.dart';
import 'package:propofol_dreams_app/components/collapsible_input_card.dart';
import 'package:propofol_dreams_app/components/input_summary_display.dart';

import '../providers/settings.dart';

class DurationScreen extends StatefulWidget {
  const DurationScreen({super.key});

  @override
  State<DurationScreen> createState() => _DurationScreenState();
}

class _DurationScreenState extends State<DurationScreen> {
  final TextEditingController weightController = TextEditingController();
  final TextEditingController infusionRateController = TextEditingController();
  final PDSegmentedController infusionUnitController = PDSegmentedController();
  final ScrollController tableScrollController = ScrollController();

  List<DurationRowData> durationRows = [];
  bool _didRunInitialCalculation = false;

  List<InfusionUnit> infusionUnits = [
    InfusionUnit.mg_kg_hr,
    InfusionUnit.mcg_kg_min,
    InfusionUnit.mL_hr
  ];

  int infusionRateDecimal = 1;
  final CollapsibleInputCardController _inputCardController =
      CollapsibleInputCardController();

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
    infusionUnitController.val = settings.infusionUnit == InfusionUnit.mg_kg_hr
        ? 0
        : settings.infusionUnit == InfusionUnit.mcg_kg_min
            ? 1
            : 2;
    infusionRateDecimal = infusionUnits[infusionUnitController.val] ==
            InfusionUnit.mg_kg_hr
        ? 1
        : infusionUnits[infusionUnitController.val] == InfusionUnit.mcg_kg_min
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
      return infusionRate / weight * settings.propofol_concentration * 1000 / 60;
    } else if (previous == InfusionUnit.mcg_kg_min &&
        current == InfusionUnit.mL_hr) {
      return infusionRate * weight / settings.propofol_concentration / 1000 * 60;
    } else {
      return 0;
    }
  }

  void updateInfusionUnit() {
    final settings = context.read<Settings>();

    //update Infusion Rate if conditions met
    InfusionUnit previous = settings.infusionUnit;
    InfusionUnit current = infusionUnits[infusionUnitController.val];
    infusionRateDecimal = infusionUnits[infusionUnitController.val] ==
            InfusionUnit.mg_kg_hr
        ? 1
        : infusionUnits[infusionUnitController.val] == InfusionUnit.mcg_kg_min
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

    settings.infusionUnit = infusionUnits[infusionUnitController.val];
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
    InfusionUnit infusionUnit = infusionUnits[infusionUnitController.val];
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
      if (collapseInput) _inputCardController.collapse();
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
    tableScrollController.dispose();
    super.dispose();
  }

  /// Input fields widget used as [CollapsibleInputCard] expandedContent.
  Widget _buildInputFields(double UIHeight, double cardWidth) {
    bool weightEnabled = infusionUnits[infusionUnitController.val] ==
            InfusionUnit.mL_hr
        ? false
        : true;
    return Column(
      children: [
        // Weight input field
        SizedBox(
          height: UIHeight + 24,
          child: PDTextField(
            prefixIcon: Icons.monitor_weight_outlined,
            labelText: '${AppLocalizations.of(context)!.weight} (kg)',
            controller: weightController,
            fractionDigits: 0,
            interval: 1,
            onPressed: updateWeight,
            enabled: weightEnabled,
            range: const [0, 250],
          ),
        ),
        const SizedBox(height: 8),
        // Infusion rate input field
        SizedBox(
          height: UIHeight + 24,
          child: PDTextField(
            prefixIcon: Icons.water_drop_outlined,
            labelText: '${AppLocalizations.of(context)!.infusionRate} (${[
              InfusionUnit.mg_kg_hr.toString(),
              InfusionUnit.mcg_kg_min.toString(),
              InfusionUnit.mL_hr.toString()
            ][infusionUnitController.val]})',
            controller: infusionRateController,
            fractionDigits: infusionRateDecimal,
            interval: infusionUnits[infusionUnitController.val] ==
                    InfusionUnit.mg_kg_hr
                ? 0.5
                : infusionUnits[infusionUnitController.val] ==
                        InfusionUnit.mcg_kg_min
                    ? 10
                    : 1,
            onPressed: updateInfusionRate,
            range: const [1, 9999],
          ),
        ),
        const SizedBox(height: 8),
        // Infusion unit segmented control
        SizedBox(
          height: UIHeight,
          width: cardWidth,
          child: PDSegmentedControl(
            fitWidth: true,
            fitHeight: true,
            fontSize: 14,
            defaultColor: Theme.of(context).colorScheme.primary,
            defaultOnColor: Theme.of(context).colorScheme.onPrimary,
            labels: [...infusionUnits.map((e) => e.toString())],
            segmentedController: infusionUnitController,
            onPressed: [
              updateInfusionUnit,
              updateInfusionUnit,
              updateInfusionUnit,
            ],
          ),
        ),
      ],
    );
  }

  /// Collapsible input card wrapping the Duration input fields.
  Widget _buildInputCard(double UIHeight, double cardWidth) {
    final weight = int.tryParse(weightController.text);
    final infusionRate = double.tryParse(infusionRateController.text);
    final infusionUnit = infusionUnits[infusionUnitController.val];

    return CollapsibleInputCard(
      title: AppLocalizations.of(context)!.duration,
      controller: _inputCardController,
      expandedContent: _buildInputFields(UIHeight, cardWidth),
      collapsedSummary: InputSummaryDisplay(
        calculatorType: CalculatorType.duration,
        weight: weight,
        infusionRate: infusionRate,
        infusionUnit: infusionUnit,
      ),
      onCalculate: () => run(collapseInput: true),
      showCalculateButton: false,
    );
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

  /// Tablet 2-column layout: input card on left (320px), results on right.
  Widget _buildTabletLayout(Settings settings, double UIHeight, double mediaQueryHeight) {
    return Padding(
      padding: EdgeInsets.only(
        left: horizontalSidesPaddingPixel,
        right: horizontalSidesPaddingPixel,
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 320,
            child: _buildInputCard(UIHeight, 320 - 2 * kSp16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SingleChildScrollView(
              child: _buildResultsTable(settings, mediaQueryHeight),
            ),
          ),
        ],
      ),
    );
  }

  /// Desktop 2-column layout: input card on left (360px), results on right.
  Widget _buildDesktopLayout(Settings settings, double UIHeight, double mediaQueryHeight) {
    return Padding(
      padding: EdgeInsets.only(
        left: horizontalSidesPaddingPixel,
        right: horizontalSidesPaddingPixel,
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 360,
            child: _buildInputCard(UIHeight, 360 - 2 * kSp16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SingleChildScrollView(
              child: _buildResultsTable(settings, mediaQueryHeight),
            ),
          ),
        ],
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
    final isTabletLayout = ResponsiveHelper.isTablet(context) && !isDesktopLayout;

    final settings = context.watch<Settings>();

    infusionRateDecimal = infusionUnits[infusionUnitController.val] ==
            InfusionUnit.mg_kg_hr
        ? 1
        : infusionUnits[infusionUnitController.val] == InfusionUnit.mcg_kg_min
            ? 0
            : 1;

    final mediaQuery = MediaQuery.of(context);
    final double UIHeight = mediaQuery.size.aspectRatio >= 0.455
        ? mediaQuery.size.height >= screenBreakPoint1
            ? 56
            : 48
        : 48;

    final double cardWidth =
        mediaQuery.size.width - 2 * horizontalSidesPaddingPixel;

    if (isDesktopLayout) {
      return _wrapWithKeyboardShortcuts(
        _buildDesktopLayout(settings, UIHeight, mediaQuery.size.height),
      );
    }
    if (isTabletLayout) {
      return _wrapWithKeyboardShortcuts(
        _buildTabletLayout(settings, UIHeight, mediaQuery.size.height),
      );
    }

    // Mobile: single-column scrollable layout
    return _wrapWithKeyboardShortcuts(
      LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            padding: EdgeInsets.only(
              left: horizontalSidesPaddingPixel,
              right: horizontalSidesPaddingPixel,
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              reverse: true,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight -
                      MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildResultsTable(settings, mediaQuery.size.height),
                    const SizedBox(height: 16),
                    _buildInputCard(UIHeight, cardWidth),
                    SizedBox(
                      height: MediaQuery.of(context).padding.bottom + 24,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
