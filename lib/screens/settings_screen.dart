import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:propofol_dreams_app/constants.dart';
import 'package:propofol_dreams_app/providers/settings.dart';
import 'package:propofol_dreams_app/l10n/generated/app_localizations.dart';
import 'package:propofol_dreams_app/models/drug.dart';

import 'package:propofol_dreams_app/controllers/PDTextField.dart';
import 'package:propofol_dreams_app/controllers/PDSegmentedController.dart';
import 'package:propofol_dreams_app/controllers/PDSegmentedControl.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final PDSegmentedController propofolController = PDSegmentedController();
  final PDSegmentedController remifentanilController = PDSegmentedController();
  final PDSegmentedController remimazolamController = PDSegmentedController();
  final PDSegmentedController themeController = PDSegmentedController();
  final TextEditingController pumpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    // Settings are already loaded - initialize controllers with final values
    final settings = context.read<Settings>();
    _setControllersFromSettings(settings);
  }

  void _setControllersFromSettings(Settings settings) {
    // Check which propofol variant is currently set by checking legacy concentration
    final currentPropofolConcentration = settings.density; // Use legacy density getter for backward compatibility
    propofolController.val = currentPropofolConcentration == 10 ? 0 : 1;
    
    // Check which remifentanil variant is currently set
    final currentRemifentanilDrug = settings.getCurrentDrugVariant('Remifentanil');
    if (currentRemifentanilDrug == Drug.remifentanil20mcg) {
      remifentanilController.val = 0;
    } else if (currentRemifentanilDrug == Drug.remifentanil40mcg) {
      remifentanilController.val = 1;
    } else {
      remifentanilController.val = 2; // 50mcg default
    }
    
    // Check which remimazolam variant is currently set
    final currentRemimazolamDrug = settings.getCurrentDrugVariant('Remimazolam');
    if (currentRemimazolamDrug == Drug.remimazolam1mg) {
      remimazolamController.val = 0;
    } else {
      remimazolamController.val = 1; // 2mg
    }
    
    pumpController.text = settings.max_pump_rate.toString();
    themeController.val = settings.themeModeSelection == ThemeMode.light
        ? 0
        : settings.themeModeSelection == ThemeMode.dark
            ? 1
            : 2;
  }

  Widget _buildDrugConcentrationSection(Drug drug, Settings settings, double UIHeight, double screenWidth) {
    // Get available variants for this drug type
    final availableVariants = settings.getAvailableDrugVariants(drug.displayName);
    final availableConcentrations = availableVariants.map((variant) => variant.concentration).toList();
    final currentConcentration = settings.getDrugConcentration(drug);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Drug name with icon indicator
        Row(
          children: [
            Icon(
              drug.icon,
              size: 18,
              color: drug.getColor(context),
            ),
            const SizedBox(width: 8),
            Text(
              drug.displayName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Concentration selector or display
        if (availableConcentrations.length > 1)
          // Multiple options - show segmented control
          SizedBox(
            height: UIHeight,
            width: screenWidth,
            child: PDSegmentedControl(
              fitWidth: true,
              fitHeight: true,
              fontSize: 16,
              defaultColor: Theme.of(context).colorScheme.primary,
              defaultOnColor: Theme.of(context).colorScheme.onPrimary,
              labels: availableConcentrations.map((conc) => 
                '${conc.toStringAsFixed(conc == conc.roundToDouble() ? 0 : 1)} ${drug.concentrationUnit.displayName}'
              ).toList(),
              segmentedController: drug.displayName == 'Propofol' 
                  ? propofolController 
                  : drug.displayName == 'Remifentanil'
                      ? remifentanilController
                      : drug.displayName == 'Remimazolam'
                          ? remimazolamController
                          : PDSegmentedController(),
              onPressed: availableVariants.map((variant) => () {
                // Set the concentration for the appropriate variant
                settings.setDrugConcentration(variant, variant.concentration);
                if (drug.displayName == 'Propofol' || drug.displayName == 'Remifentanil' || drug.displayName == 'Remimazolam') {
                  setState(() {
                    _setControllersFromSettings(settings);
                  });
                }
              }).toList(),
            ),
          )
        else
          // Single option - show as display only
          Container(
            height: UIHeight,
            width: screenWidth,
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.primary),
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Center(
              child: Text(
                '${currentConcentration.toStringAsFixed(currentConcentration == currentConcentration.roundToDouble() ? 0 : 1)} ${drug.concentrationUnit.displayName}',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
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
        title:  Text(
          AppLocalizations.of(context)!.settings,
        ),
      ),
      const SizedBox(
        height: 16,
      ),
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: horizontalSidesPaddingPixel),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Drug Concentrations',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  // Propofol - with selection
                  _buildDrugConcentrationSection(
                    Drug.propofol10mg, 
                    settings, 
                    UIHeight, 
                    mediaQuery.size.width - 2 * horizontalSidesPaddingPixel
                  ),
                  const SizedBox(height: 16),
                  
                  // Remifentanil - with selection
                  _buildDrugConcentrationSection(
                    Drug.remifentanil50mcg,
                    settings, 
                    UIHeight, 
                    mediaQuery.size.width - 2 * horizontalSidesPaddingPixel
                  ),
                  const SizedBox(height: 16),
                  
                  // Dexmedetomidine - display only
                  _buildDrugConcentrationSection(
                    Drug.dexmedetomidine, 
                    settings, 
                    UIHeight, 
                    mediaQuery.size.width - 2 * horizontalSidesPaddingPixel
                  ),
                  const SizedBox(height: 16),
                  
                  // Remimazolam - with selection
                  _buildDrugConcentrationSection(
                    Drug.remimazolam1mg, 
                    settings, 
                    UIHeight, 
                    mediaQuery.size.width - 2 * horizontalSidesPaddingPixel
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
        ),
      ),
    ]);
  }
}
