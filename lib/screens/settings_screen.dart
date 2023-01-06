import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:propofol_dreams_app/constants.dart';
import 'package:propofol_dreams_app/providers/settings.dart';

import 'package:propofol_dreams_app/controllers/PDTextField.dart';
import 'package:propofol_dreams_app/controllers/PDSegmentedController.dart';
import 'package:propofol_dreams_app/controllers/PDSegmentedControl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final PDSegmentedController dilutionController = PDSegmentedController();
  final PDSegmentedController themeController = PDSegmentedController();
  final TextEditingController pumpController = TextEditingController();

  @override
  void initState() {
    final settings = context.read<Settings>();
    dilutionController.val = settings.dilution == 10 ? 0 : 1;
    pumpController.text = settings.max_pump_rate.toString();
    themeController.val = settings.themeModeSelection == ThemeMode.light
        ? 0
        : settings.themeModeSelection == ThemeMode.dark
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

    if (pref.containsKey('dilution')) {
      settings.dilution = pref.getInt('dilution')!;
    } else {
      settings.dilution = 10;
    }
    dilutionController.val = settings.dilution == 10 ? 0 : 1;

    if (pref.containsKey('max_pump_rate')) {
      settings.max_pump_rate = pref.getInt('max_pump_rate')!;
    } else {
      settings.max_pump_rate = 750;
    }
    pumpController.text = settings.max_pump_rate.toString();

    if (pref.containsKey('themeMode')) {
      String? themeMode = pref.getString('themeMode');
      switch (themeMode) {
        case 'ThemeMode.light':
          {
            settings.themeModeSelection = ThemeMode.light;
            // themeController.val = 0;
          }
          break;

        case 'ThemeMode.dark':
          {
            settings.themeModeSelection = ThemeMode.dark;
            // themeController.val = 1;
          }
          break;

        case 'ThemeMode.system':
          {
            settings.themeModeSelection = ThemeMode.system;
          }
          break;

        default:
          {
            settings.themeModeSelection = ThemeMode.system;

          }
          break;
      }
    } else {
      settings.themeModeSelection = ThemeMode.system;
    }

    themeController.val = settings.themeModeSelection == ThemeMode.light
        ? 0
        : settings.themeModeSelection == ThemeMode.dark
        ? 1
        : 2;
  }

  @override
  Widget build(BuildContext context) {
    // print('settings screen build');


    var mediaQuery = MediaQuery.of(context);
    // var screenWidth = mediaQuery.size.width;

    final double UIHeight =
    mediaQuery.size.aspectRatio >= 0.455 ?  mediaQuery.size.height>=768? 56: 48 : 48;

    final settings = context.watch<Settings>();

    return Column(children: [
      AppBar(
        title: Text(
          'Settings',
        ),
      ),
      SizedBox(
        height: 16,
      ),
      Container(
        height: MediaQuery.of(context).size.height - 90 - 96 - 16,
        padding: EdgeInsets.symmetric(horizontal: horizontalSidesPaddingPixel),
        // decoration: BoxDecoration(
        //   border: Border.all(color: Theme.of(context).colorScheme.primary),
        // ),
        child: ListView(
          padding: EdgeInsets.zero,
          physics: NeverScrollableScrollPhysics(),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Propofol Formulation',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(
                  height: 4,
                ),
                SizedBox(
                  height: 16,
                ),
                PDSegmentedControl(
                  height: UIHeight,
                  fontSize: 16,
                  labels: ['1 % = 10 mcg/mL', '2 % = 20 mcg/mL'],
                  segmentedController: dilutionController,
                  onPressed: [
                    () {
                      settings.dilution = 10;
                    },
                    () {
                      settings.dilution = 20;
                    }
                  ],
                ),
              ],
            ),
            SizedBox(
              height: 16,
            ),
            Divider(
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(
              height: 16,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Maximum Pump Rate',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(
                  height: 4,
                ),

                SizedBox(
                  height: 16,
                ),
                Container(
                  height: UIHeight + 24,
                  child: PDTextField(
                      height: UIHeight + 2,
                      prefixIcon: null,
                      labelText: 'Pump Rate (mL/hr)',
                      helperText: '',
                      interval: 50,
                      fractionDigits: 0,
                      controller: pumpController,
                      onPressed: () {
                        int? pumpRate = int.tryParse(pumpController.text);
                        if (pumpRate != null) {
                          settings.max_pump_rate = pumpRate;
                        }
                      },
                      range: [0, 1500]),
                )
              ],
            ),
            SizedBox(
              height: 4,
            ),
            Divider(
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(
              height: 16,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dark Mode',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(
                  height: 4,
                ),
                // Text(
                //   'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus finibus lorem vitae augue tincidunt, at aliquet mauris condimentum. Donec pellentesque tempus dapibus',
                //   style: TextStyle(fontSize: 14),
                // ),
                SizedBox(
                  height: 16,
                ),
                PDSegmentedControl(
                  height: UIHeight,
                  fontSize: 16,
                  labels: ['Light', 'Dark', 'Auto'],
                  segmentedController: themeController,
                  onPressed: [
                    () {
                      settings.themeModeSelection = ThemeMode.light;
                    },
                    () {
                      settings.themeModeSelection = ThemeMode.dark;
                    },
                    () {
                      settings.themeModeSelection = ThemeMode.system;
                    }
                  ],
                ),
                // ElevatedButton(
                //     onPressed: () async {
                //       var pref = await SharedPreferences.getInstance();
                //       pref.clear();
                //     },
                //     child: Text('Clear'))
              ],
            ),
          ],
        ),
      )
    ]);
  }
}
