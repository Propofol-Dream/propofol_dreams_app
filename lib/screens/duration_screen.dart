import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:propofol_dreams_app/constants.dart';
import 'package:propofol_dreams_app/controllers/PDTextField.dart';
import 'package:propofol_dreams_app/controllers/PDSegmentedController.dart';
import 'package:propofol_dreams_app/controllers/PDSegmentedControl.dart';
import 'package:propofol_dreams_app/models/InfusionUnit.dart';

import 'volume_screen.dart';

import '../providers/settings.dart';

class DurationScreen extends StatefulWidget {
  DurationScreen({Key? key}) : super(key: key);



  @override
  State<DurationScreen> createState() => _DurationScreenState();
}

class _DurationScreenState extends State<DurationScreen> {
  final TextEditingController weightController = TextEditingController();
  final TextEditingController infusionRateController = TextEditingController();
  final PDSegmentedController infusionUnitController = PDSegmentedController();
  final PDTableController tableController = PDTableController();
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
  List<DataRow> emptyRows = [
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
    final settings = context.read<Settings>();

    weightController.text = settings.weight.toString();
    infusionRateController.text = settings.infusionRate.toString();
    infusionUnitController.val =
        infusionUnits.indexWhere((e) => e == settings.infusionUnit);

    run();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }


  void updateWeight() {
    final settings = context.read<Settings>();
    settings.weight = int.tryParse(weightController.text) ?? 0;
    run();
  }

  void updateInfusionRate() {
    final settings = context.read<Settings>();
    settings.infusionRate = double.tryParse(infusionRateController.text) ?? 0;
    run();
  }

  void updateInfusionUnit() {
    final settings = context.read<Settings>();
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

  void run() {
    int? weight = int.tryParse(weightController.text);
    double? infusionRate = double.tryParse(infusionRateController.text);
    InfusionUnit infusionUnit = infusionUnits[infusionUnitController.val];

    bool durationIsRunnable = infusionUnit == InfusionUnit.mL_hr
        ? infusionRate != null
        : (weight != null && infusionRate != null);

    if (durationIsRunnable) {
      var settings = context.read<Settings>();
      durationRows.clear();
      List<DataRow> durations = [];

      for (int i = 60; i >= 10; i -= 10) {
        double duration = calculate(
            volume: i,
            weight: weight,
            infusionRate: infusionRate,
            infusionUnit: infusionUnit,
            dilution: settings.dilution!);

        if (i == 50 || i == 20) {
          durations.add(
            DataRow(
              cells: [
                DataCell(
                  Row(
                    children: [
                      Icon(Icons.vaccines),
                      SizedBox(
                        width: 4,
                      ),
                      Text('$i mL'),
                    ],
                  ),
                ),
                DataCell(Text('${duration.toStringAsFixed(0)} mins'))
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

      // durationRows = [
      //   DataRow(cells: [DataCell(Text('60 mL')), DataCell(Text('60 mins'))]),
      //   DataRow(cells: [DataCell(Text('50')), DataCell(Text('60'))]),
      //   DataRow(cells: [DataCell(Text('40')), DataCell(Text('60'))]),
      //   DataRow(cells: [DataCell(Text('30')), DataCell(Text('60'))]),
      //   DataRow(cells: [DataCell(Text('20')), DataCell(Text('60'))]),
      //   DataRow(cells: [DataCell(Text('10')), DataCell(Text('60'))]),
      // ];
    } else {
      durationRows = emptyRows;
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
          // PDTable(
          //     tableController: tableController,
          //     tableLabel: 'Volume',
          //     colHeaderIcon: Icon(Icons.watch_later_outlined),
          //     colHeaderLabels: ['Duration (mins)'],
          //     rowHeaderIcon: Icon(Icons.science_outlined),
          //     rowLabels: [
          //       ['60', '10.0'],
          //       ['50', '10.0'],
          //       ['40', '10.0'],
          //       ['30', '10.0'],
          //       ['20', '10.0'],
          //       ['10', '10.0'],
          //     ],showRowNumbers: 6,),

          DataTable(columns: durationColumns, rows: durationRows
              // [
              //   DataRow(
              //       cells: [DataCell(Text('60 mL')), DataCell(Text('60 mins'))]),
              //   DataRow(cells: [DataCell(Text('50')), DataCell(Text('60'))]),
              //   DataRow(cells: [DataCell(Text('40')), DataCell(Text('60'))]),
              //   DataRow(cells: [DataCell(Text('30')), DataCell(Text('60'))]),
              //   DataRow(cells: [DataCell(Text('20')), DataCell(Text('60'))]),
              //   DataRow(cells: [DataCell(Text('10')), DataCell(Text('60'))]),
              // ],
              ),

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
            range: [1, 100],
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
