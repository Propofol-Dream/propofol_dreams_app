import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:propofol_dreams_app/constants.dart';
import 'package:propofol_dreams_app/controllers/PDTextField.dart';
import 'package:propofol_dreams_app/controllers/PDSegmentedController.dart';
import 'package:propofol_dreams_app/controllers/PDSegmentedControl.dart';
import 'package:propofol_dreams_app/models/InfusionUnit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'volume_screen.dart';

import '../providers/settings.dart';
import 'package:propofol_dreams_app/constants.dart';

class DurationScreen extends StatefulWidget {
  DurationScreen({Key? key}) : super(key: key);

  @override
  State<DurationScreen> createState() => _DurationScreenState();
}

class _DurationScreenState extends State<DurationScreen> {
  final TextEditingController weightController = TextEditingController();
  final TextEditingController infusionRateController = TextEditingController();
  final PDSegmentedController infusionUnitController = PDSegmentedController();

  // final PDTableController tableController = PDTableController();

  List<DataColumn> durationColumns = [
    DataColumn(
      label: Row(
        children: [
          Icon(Icons.science_outlined),
          SizedBox(
            width: 4.0,
          ),
          Text('Volumes'),
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
        Text('Durations'),
      ],
    ))
  ];
  final List<DataRow> emptyRows = [
    DataRow(cells: [DataCell(Text('60 mL')), DataCell(Text('-- mins'))]),
    DataRow(cells: [DataCell(Text('50 mL')), DataCell(Text('-- mins'))]),
    DataRow(cells: [DataCell(Text('40 mL')), DataCell(Text('-- mins'))]),
    DataRow(cells: [DataCell(Text('30 mL')), DataCell(Text('-- mins'))]),
    DataRow(cells: [DataCell(Text('20 mL')), DataCell(Text('-- mins'))]),
    DataRow(cells: [DataCell(Text('10 mL')), DataCell(Text('-- mins'))]),
  ];

  List<DataRow> durationRows = [];

  List<InfusionUnit> infusionUnits = [
    InfusionUnit.mg_kg_h,
    InfusionUnit.mcg_kg_min,
    InfusionUnit.mL_hr
  ];

  @override
  void initState() {
    var settings = context.read<Settings>();

    weightController.text = settings.weight.toString();
    infusionRateController.text = settings.infusionRate!.toStringAsFixed(1);
    infusionUnitController.val = settings.infusionUnit == InfusionUnit.mg_kg_h
        ? 0
        : settings.infusionUnit == InfusionUnit.mcg_kg_min
        ? 1
        : 2;

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
    infusionRateController.text = settings.infusionRate!.toStringAsFixed(1);

    if (pref.containsKey('infusionUnit')) {
      String? infusionUnit = pref.getString('infusionUnit');

      switch (infusionUnit) {
        case 'mg/kg/h':
          {
            settings.infusionUnit = InfusionUnit.mg_kg_h;
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
            settings.infusionUnit = InfusionUnit.mg_kg_h;
            // infusionUnitController.val = 0;
          }
          break;
      }
    } else {
      settings.infusionUnit = InfusionUnit.mg_kg_h;
    }
    infusionUnitController.val = settings.infusionUnit == InfusionUnit.mg_kg_h
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

    if (previous == InfusionUnit.mg_kg_h &&
        current == InfusionUnit.mcg_kg_min) {
      return infusionRate * 1000 / 60;
    } else if (previous == InfusionUnit.mcg_kg_min &&
        current == InfusionUnit.mg_kg_h) {
      return infusionRate / 1000 * 60;
    } else if (previous == InfusionUnit.mg_kg_h &&
        current == InfusionUnit.mL_hr) {
      return infusionRate * weight / settings.dilution;
    } else if (previous == InfusionUnit.mL_hr &&
        current == InfusionUnit.mg_kg_h) {
      return infusionRate / weight * settings.dilution;
    } else if (previous == InfusionUnit.mL_hr &&
        current == InfusionUnit.mcg_kg_min) {
      return infusionRate / weight * settings.dilution * 1000 / 60;
    } else if (previous == InfusionUnit.mcg_kg_min &&
        current == InfusionUnit.mL_hr) {
      return infusionRate * weight / settings.dilution / 1000 * 60;
    } else {
      return 0;
    }
  }

  void updateInfusionUnit() {
    final settings = context.read<Settings>();

    //update Infusion Rate if conditions met
    InfusionUnit previous = settings.infusionUnit;
    InfusionUnit current = infusionUnits[infusionUnitController.val];
    int? weight = int.tryParse(weightController.text);
    double? infusionRate = double.tryParse(infusionRateController.text);
    if (previous != current && weight != null && infusionRate != null) {
      settings.infusionRate = convertInfusionRate(
          weight: weight,
          infusionRate: infusionRate,
          previous: previous,
          current: current);
      infusionRateController.text = settings.infusionRate!.toStringAsFixed(1);
    }

    settings.infusionUnit = infusionUnits[infusionUnitController.val];
    run();
  }

  double calculate(
      {required int volume,
      int? weight,
      required double infusionRate,
      required InfusionUnit infusionUnit,
      required int dilution}) {
    double res = 0.0;
    if (infusionUnit == InfusionUnit.mg_kg_h) {
      res = volume * dilution / weight! / infusionRate * 60;
    } else if (infusionUnit == InfusionUnit.mcg_kg_min) {
      res = volume * dilution / weight! / infusionRate * 1000;
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

      for (int i = 60; i >= 10; i -= 10) {
        double duration = calculate(
            volume: i,
            weight: weight,
            infusionRate: infusionRate!,
            infusionUnit: infusionUnit,
            dilution: settings.dilution);

        if (i == 50 || i == 20) {
          durations.add(
            DataRow(
              cells: [
                DataCell(
                  Text(
                    '$i mL',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataCell(Text('${duration.toStringAsFixed(0)} mins',
                    style: TextStyle(fontWeight: FontWeight.bold)))
              ],
            ),
          );
        } else {
          durations.add(
            DataRow(
              cells: [
                DataCell(Text('$i mL')),
                DataCell(Text('${duration.toStringAsFixed(0)} mins'))
              ],
            ),
          );
        }
      }
      durationRows = durations;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<Settings>();

    final mediaQuery = MediaQuery.of(context);
    final UIHeight =
        mediaQuery.size.width / mediaQuery.size.height >= 0.455 ? 56 : 48;
    final double UIWidth =
        (mediaQuery.size.width - 2 * (horizontalSidesPaddingPixel + 4)) / 2;

    bool weightTextFieldEnabled =
        infusionUnits[infusionUnitController.val] == InfusionUnit.mL_hr
            ? false
            : true;

    int? weight = int.tryParse(weightController.text);
    double? infusionRate = double.tryParse(infusionRateController.text);
    InfusionUnit infusionUnit = infusionUnits[infusionUnitController.val];

    return Container(
      height:
          MediaQuery.of(context).size.height - (Platform.isAndroid ? 48 : 88),
      padding: EdgeInsets.symmetric(horizontal: horizontalSidesPaddingPixel),
      // decoration: BoxDecoration(
      //   borderRadius: BorderRadius.circular(5),
      //   border: Border.all(color: Theme.of(context).colorScheme.primary),
      // ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          DataTable(
              columns: durationColumns,
              rows: isRunnable(
                      weight: weight,
                      infusionRate: infusionRate,
                      infusionUnit: infusionUnit)
                  ? durationRows
                  : emptyRows),
          SizedBox(
            height: 16,
          ),
          PDTextField(
            labelText: 'Weight (kg)',
            controller: weightController,
            fractionDigits: 0,
            helperText: '',
            interval: 1,
            onPressed: updateWeight,
            enabled: weightTextFieldEnabled,
            range: [0, 250],
          ),
          SizedBox(
            height: 8,
          ),
          PDTextField(
            labelText: 'Infusion Rate (${[
              InfusionUnit.mg_kg_h.toString(),
              InfusionUnit.mcg_kg_min.toString(),
              InfusionUnit.mL_hr.toString()
            ][infusionUnitController.val]})',
            controller: infusionRateController,
            fractionDigits: 1,
            helperText: '',
            interval: 0.5,
            onPressed: updateInfusionRate,
            range: [1, 1000],
          ),
          SizedBox(
            height: 8,
          ),
          PDSegmentedControl(
            height: 56,
            fontSize: 14,
            labels: [...infusionUnits.map((e) => e.toString())],
            segmentedController: infusionUnitController,
            onPressed: [
              updateInfusionUnit,
              updateInfusionUnit,
              updateInfusionUnit
            ],
          ),
          SizedBox(
            height: 32,
          )
        ],
      ),
    );
  }
}
