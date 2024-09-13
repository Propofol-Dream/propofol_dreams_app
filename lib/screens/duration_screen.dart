import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:propofol_dreams_app/constants.dart';
import 'package:propofol_dreams_app/controllers/PDTextField.dart';
import 'package:propofol_dreams_app/controllers/PDSegmentedController.dart';
import 'package:propofol_dreams_app/controllers/PDSegmentedControl.dart';
import 'package:propofol_dreams_app/models/InfusionUnit.dart';

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

  // final PDTableController tableController = PDTableController();

  final List<DataRow> emptyRows = [
    const DataRow(cells: [DataCell(Text('60 mL')), DataCell(Text('-- mins'))]),
    const DataRow(cells: [DataCell(Text('50 mL')), DataCell(Text('-- mins'))]),
    const DataRow(cells: [DataCell(Text('40 mL')), DataCell(Text('-- mins'))]),
    const DataRow(cells: [DataCell(Text('30 mL')), DataCell(Text('-- mins'))]),
    const DataRow(cells: [DataCell(Text('20 mL')), DataCell(Text('-- mins'))]),
    const DataRow(cells: [DataCell(Text('10 mL')), DataCell(Text('-- mins'))]),
  ];

  List<DataRow> durationRows = [];

  List<InfusionUnit> infusionUnits = [
    InfusionUnit.mg_kg_hr,
    InfusionUnit.mcg_kg_min,
    InfusionUnit.mL_hr
  ];

  int infusionRateDecimal = 1;

  @override
  void initState() {
    var settings = context.read<Settings>();

    weightController.text = settings.weight.toString();
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
        settings.infusionRate!.toStringAsFixed(infusionRateDecimal);

    load().then((value) {
      setState(() {});
    });

    super.initState();
  }

  Future<void> load() async {
    var pref = await SharedPreferences.getInstance();
    final settings = context.read<Settings>();

    if (pref.containsKey('weight')) {
      settings.weight = pref.getInt('weight')!;
    } else {
      settings.weight = 70;
    }
    weightController.text = settings.weight.toString();

    if (pref.containsKey('infusionRate')) {
      settings.infusionRate = pref.getDouble('infusionRate')!;
    } else {
      //max_pump_rate cannot be null
      settings.infusionRate = 10.0;
    }
    infusionRateController.text =
        settings.infusionRate!.toStringAsFixed(infusionRateDecimal);

    if (pref.containsKey('infusionUnit')) {
      String? infusionUnit = pref.getString('infusionUnit');

      switch (infusionUnit) {
        case 'mg/kg/h':
          {
            settings.infusionUnit = InfusionUnit.mg_kg_hr;
            // infusionUnitController.val = 0;
          }
          break;

        case 'mcg/kg/min':
          {
            settings.infusionUnit = InfusionUnit.mcg_kg_min;
            // infusionUnitController.val = 1;
          }
          break;

        case 'mL/hr':
          {
            settings.infusionUnit = InfusionUnit.mL_hr;
            // infusionUnitController.val = 2;
          }
          break;

        default:
          {
            settings.infusionUnit = InfusionUnit.mg_kg_hr;
            // infusionUnitController.val = 0;
          }
          break;
      }
    } else {
      settings.infusionUnit = InfusionUnit.mg_kg_hr;
    }
    infusionUnitController.val = settings.infusionUnit == InfusionUnit.mg_kg_hr
        ? 0
        : settings.infusionUnit == InfusionUnit.mcg_kg_min
            ? 1
            : 2;

    run();
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
      return infusionRate * weight / settings.density;
    } else if (previous == InfusionUnit.mL_hr &&
        current == InfusionUnit.mg_kg_hr) {
      return infusionRate / weight * settings.density;
    } else if (previous == InfusionUnit.mL_hr &&
        current == InfusionUnit.mcg_kg_min) {
      return infusionRate / weight * settings.density * 1000 / 60;
    } else if (previous == InfusionUnit.mcg_kg_min &&
        current == InfusionUnit.mL_hr) {
      return infusionRate * weight / settings.density / 1000 * 60;
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
      required int density}) {
    double res = 0.0;
    if (infusionUnit == InfusionUnit.mg_kg_hr) {
      res = volume * density / weight! / infusionRate * 60;
    } else if (infusionUnit == InfusionUnit.mcg_kg_min) {
      res = volume * density / weight! / infusionRate * 1000;
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

  void run() {
    int? weight = int.tryParse(weightController.text);
    double? infusionRate = double.tryParse(infusionRateController.text);
    InfusionUnit infusionUnit = infusionUnits[infusionUnitController.val];

    if (isRunnable(
        weight: weight,
        infusionRate: infusionRate,
        infusionUnit: infusionUnit)) {
      var settings = context.read<Settings>();
      durationRows = [];
      List<DataRow> durations = [];
      var height = MediaQuery.of(context).size.height;
      List<int> volumes = height >= screenBreakPoint2
          ? [100, 90, 80, 70, 60, 50, 40, 30, 20, 10]
          : height >= screenBreakPoint1
              ? [60, 50, 40, 30, 20, 10]
              : [50, 20];
      for (int i = 0; i < volumes.length; i++) {
        // for (int i = 60; i >= 10; i -= 10) {
        double duration = calculate(
            volume: volumes[i],
            weight: weight,
            infusionRate: infusionRate!,
            infusionUnit: infusionUnit,
            density: settings.density);

        if (volumes[i] == 50 || volumes[i] == 20) {
          durations.add(
            DataRow(
              cells: [
                DataCell(
                  Text(
                    '${volumes[i]} mL',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataCell(Text('${duration.toStringAsFixed(0)} ${AppLocalizations.of(context)!.mins}',
                    style: const TextStyle(fontWeight: FontWeight.bold)))
              ],
            ),
          );
        } else {
          durations.add(
            DataRow(
              cells: [
                DataCell(Text('${volumes[i]} mL')),
                DataCell(Text('${duration.toStringAsFixed(0)} ${AppLocalizations.of(context)!.mins}'))
              ],
            ),
          );
        }
      }

      setState(() {
        durationRows = durations;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // final settings = context.watch<Settings>();

    List<DataColumn> durationColumns = [
      DataColumn(
        label: Row(
          children: [
            const Icon(Icons.science_outlined),
            const SizedBox(
              width: 4.0,
            ),
            Text(AppLocalizations.of(context)!.volume),
          ],
        ),
      ),
       DataColumn(
          label: Row(
        children: [
          Icon(Icons.watch_later_outlined),
          SizedBox(
            width: 4.0,
          ),
          Text(AppLocalizations.of(context)!.duration),
        ],
      ))
    ];

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

    final double screenHeight = mediaQuery.size.height -
        (Platform.isAndroid
            ? 48
            : mediaQuery.size.height >= screenBreakPoint1
                ? 88
                : 56);

    // final double UIWidth =
    //     (mediaQuery.size.width - 2 * (horizontalSidesPaddingPixel + 4)) / 2;

    bool weightTextFieldEnabled =
        infusionUnits[infusionUnitController.val] == InfusionUnit.mL_hr
            ? false
            : true;

    int? weight = int.tryParse(weightController.text);
    double? infusionRate = double.tryParse(infusionRateController.text);
    InfusionUnit infusionUnit = infusionUnits[infusionUnitController.val];

    return Container(
      height: screenHeight,
      padding:
          const EdgeInsets.symmetric(horizontal: horizontalSidesPaddingPixel),
      // decoration: BoxDecoration(
      //   borderRadius: BorderRadius.circular(5),
      //   border: Border.all(color: Theme.of(context).colorScheme.primary),
      // ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          DataTable(
              // dataRowHeight
              headingTextStyle: Theme.of(context).textTheme.titleLarge,
              dataTextStyle: Theme.of(context).textTheme.titleMedium,
              columns: durationColumns,
              rows: isRunnable(
                      weight: weight,
                      infusionRate: infusionRate,
                      infusionUnit: infusionUnit)
                  ? durationRows
                  : emptyRows),
          const SizedBox(
            height: 16,
          ),
          Container(
            alignment: Alignment.topCenter,
            height: UIHeight + 24,
            child: PDTextField(
              prefixIcon: Icons.monitor_weight_outlined,
              labelText: '${AppLocalizations.of(context)!.weight} (kg)',
              controller: weightController,
              fractionDigits: 0,
              interval: 1,
              onPressed: updateWeight,
              enabled: weightTextFieldEnabled,
              range: const [0, 250],
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          Container(
            alignment: Alignment.topCenter,
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
              // helperText: '',
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
          const SizedBox(
            height: 8,
          ),
          SizedBox(
            height: UIHeight,
            width: mediaQuery.size.width - 2 * horizontalSidesPaddingPixel,
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
                updateInfusionUnit
              ],
            ),
          ),
          const SizedBox(
            height: 32,
          )
        ],
      ),
    );
  }
}
