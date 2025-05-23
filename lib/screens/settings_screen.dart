import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:propofol_dreams_app/constants.dart';
import 'package:propofol_dreams_app/providers/settings.dart';
import 'package:propofol_dreams_app/l10n/generated/app_localizations.dart';

import 'package:propofol_dreams_app/controllers/PDTextField.dart';
import 'package:propofol_dreams_app/controllers/PDSegmentedController.dart';
import 'package:propofol_dreams_app/controllers/PDSegmentedControl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final PDSegmentedController densityController = PDSegmentedController();
  final PDSegmentedController themeController = PDSegmentedController();
  final TextEditingController pumpController = TextEditingController();

  @override
  void initState() {
    final settings = context.read<Settings>();
    densityController.val = settings.density == 10 ? 0 : 1;
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

    if (pref.containsKey('density')) {
      settings.density = pref.getInt('density')!;
    } else {
      settings.density = 10;
    }
    densityController.val = settings.density == 10 ? 0 : 1;

    if (pref.containsKey('max_pump_rate_20230820')) {
      settings.max_pump_rate = pref.getInt('max_pump_rate_20230820')!;
    } else {
      settings.max_pump_rate = 1200;
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

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(children: [
        AppBar(
          title:  Text(
            AppLocalizations.of(context)!.settings,
          ),
        ),
        const SizedBox(
          height: 16,
        ),
        Container(
          height: MediaQuery.of(context).size.height - 90 - 96 - 16,
          padding: const EdgeInsets.symmetric(horizontal: horizontalSidesPaddingPixel),
          // decoration: BoxDecoration(
          //   border: Border.all(color: Theme.of(context).colorScheme.primary),
          // ),
          child: ListView(
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.propofolFormulation,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  SizedBox(
                    height: UIHeight,
                    width: mediaQuery.size.width - 2 * horizontalSidesPaddingPixel,
                    child: PDSegmentedControl(
                      fitWidth: true,
                      fitHeight: true,
                      fontSize: 16,
                      defaultColor: Theme.of(context).colorScheme.primary,
                      defaultOnColor: Theme.of(context).colorScheme.onPrimary,
                      labels: const ['10 mg/mL', '20 mg/mL'],
                      segmentedController: densityController,
                      onPressed: [
                        () {
                          settings.density = 10;
                        },
                        () {
                          settings.density = 20;
                        }
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 24,
              ),
              Divider(
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(
                height: 16,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    AppLocalizations.of(context)!.maximumPumpRate,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  SizedBox(
                    height: UIHeight + 24,
                    child: PDTextField(
                        prefixIcon: Icons.settings_input_component_outlined,
                        labelText: '${AppLocalizations.of(context)!.pumpRate} (mL/hr)',
                        interval: 50,
                        fractionDigits: 0,
                        controller: pumpController,
                        onPressed: () {
                          int? pumpRate = int.tryParse(pumpController.text);
                          if (pumpRate != null) {
                            settings.max_pump_rate = pumpRate;
                          }
                        },
                        range: const [0, 1500]),
                  )
                ],
              ),

              Divider(
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(
                height: 16,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    AppLocalizations.of(context)!.appearance,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  // Text(
                  //   'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus finibus lorem vitae augue tincidunt, at aliquet mauris condimentum. Donec pellentesque tempus dapibus',
                  //   style: TextStyle(fontSize: 14),
                  // ),
                  const SizedBox(
                    height: 16,
                  ),
                  SizedBox(
                    height: UIHeight,
                    width: mediaQuery.size.width - 2 * horizontalSidesPaddingPixel,
                    child: PDSegmentedControl(
                      fitWidth: true,
                      fitHeight: true,
                      fontSize: 16,
                      defaultColor: Theme.of(context).colorScheme.primary,
                      defaultOnColor: Theme.of(context).colorScheme.onPrimary,
                      labels:  [AppLocalizations.of(context)!.light,AppLocalizations.of(context)!.dark,AppLocalizations.of(context)!.auto],
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
      ]),
    );
  }
}
