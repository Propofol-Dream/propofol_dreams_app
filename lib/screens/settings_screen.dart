import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:propofol_dreams_app/config/design_tokens.dart';
import 'package:propofol_dreams_app/constants.dart';
import 'package:propofol_dreams_app/providers/settings.dart';
import 'package:propofol_dreams_app/l10n/generated/app_localizations.dart';
import 'package:propofol_dreams_app/models/drug.dart';

import 'package:propofol_dreams_app/components/pk_field.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController pumpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final settings = context.read<Settings>();
    _setControllersFromSettings(settings);
  }

  void _setControllersFromSettings(Settings settings) {
    pumpController.text = settings.max_pump_rate.toString();
  }

  Widget _buildButtonGroup({
    required List<String> labels,
    required int selectedIndex,
    required ValueChanged<int> onChanged,
  }) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 48,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(labels.length, (i) {
          final selected = selectedIndex == i;
          return Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 48),
                backgroundColor: selected ? theme.colorScheme.primary : theme.colorScheme.onPrimary,
                foregroundColor: selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(i == 0 ? kRadius : 0),
                    right: Radius.circular(i == labels.length - 1 ? kRadius : 0),
                  ),
                  side: BorderSide(color: theme.colorScheme.outline),
                ),
              ),
              onPressed: () => onChanged(i),
              child: Text(labels[i], style: const TextStyle(fontSize: 13)),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDrugConcentrationSection(Drug drug, Settings settings) {
    final availableVariants = settings.getAvailableDrugVariants(drug.displayName);
    final availableConcentrations = availableVariants.map((v) => v.concentration).toList();
    final currentConcentration = settings.getDrugConcentration(drug);
    final theme = Theme.of(context);

    int currentIndex = 0;
    if (availableConcentrations.length > 1) {
      currentIndex = availableConcentrations.indexOf(currentConcentration);
      if (currentIndex < 0) currentIndex = 0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(drug.icon, size: 18, color: drug.getColor(context)),
            const SizedBox(width: kSp8),
            Text(drug.toLocalizedString(context), style: const TextStyle(fontSize: 16)),
          ],
        ),
        const SizedBox(height: kSp12),
        if (availableConcentrations.length > 1)
          _buildButtonGroup(
            labels: availableConcentrations.map((conc) =>
              '${conc.toStringAsFixed(conc == conc.roundToDouble() ? 0 : 1)} ${drug.concentrationUnit.displayName}'
            ).toList(),
            selectedIndex: currentIndex,
            onChanged: (i) {
              settings.setDrugConcentration(availableVariants[i], availableVariants[i].concentration);
              setState(() {});
            },
          )
        else
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(kRadius),
            ),
            alignment: Alignment.center,
            child: Text(
              '${currentConcentration.toStringAsFixed(currentConcentration == currentConcentration.roundToDouble() ? 0 : 1)} ${drug.concentrationUnit.displayName}',
              style: TextStyle(fontSize: 16, color: theme.colorScheme.onPrimary, fontWeight: FontWeight.w500),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<Settings>();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: horizontalSidesPaddingPixel),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: kSp16),
              Text(AppLocalizations.of(context)!.appearance, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: kSp16),
              _buildButtonGroup(
                labels: [
                  AppLocalizations.of(context)!.light,
                  AppLocalizations.of(context)!.dark,
                  AppLocalizations.of(context)!.auto,
                ],
                selectedIndex: settings.themeModeSelection == ThemeMode.light
                    ? 0
                    : settings.themeModeSelection == ThemeMode.dark
                        ? 1
                        : 2,
                onChanged: (i) {
                  settings.themeModeSelection = i == 0 ? ThemeMode.light : i == 1 ? ThemeMode.dark : ThemeMode.system;
                },
              ),
              const SizedBox(height: kSp24),
              Text(AppLocalizations.of(context)!.drugConcentration, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: kSp16),
              _buildDrugConcentrationSection(Drug.propofol10mg, settings),
              const SizedBox(height: kSp16),
              _buildDrugConcentrationSection(Drug.remifentanil50mcg, settings),
              const SizedBox(height: kSp16),
              _buildDrugConcentrationSection(Drug.dexmedetomidine, settings),
              const SizedBox(height: kSp16),
              _buildDrugConcentrationSection(Drug.remimazolam1mg, settings),
              const SizedBox(height: kSp24),
              Text(AppLocalizations.of(context)!.maximumPumpRate, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: kSp16),
              PKField(
                prefixIcon: Icons.settings_input_component_outlined,
                labelText: '${AppLocalizations.of(context)!.pumpRate} (mL/hr)',
                interval: 50,
                fractionDigits: 0,
                controller: pumpController,
                range: const [0, 1500],
                onChanged: () {
                  int? pumpRate = int.tryParse(pumpController.text);
                  if (pumpRate != null) {
                    settings.max_pump_rate = pumpRate;
                  }
                },
              ),
              const SizedBox(height: kSp32),
            ],
          ),
        ),
      ),
    );
  }
}
