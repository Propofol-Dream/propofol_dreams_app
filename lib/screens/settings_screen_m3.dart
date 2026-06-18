import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:propofol_dreams_app/config/design_tokens.dart';
import 'package:propofol_dreams_app/constants.dart';
import 'package:propofol_dreams_app/providers/settings.dart';
import 'package:propofol_dreams_app/l10n/generated/app_localizations.dart';
import 'package:propofol_dreams_app/models/drug.dart';
import 'package:propofol_dreams_app/models/volume_mode.dart';
import 'package:propofol_dreams_app/utils/responsive_helper.dart';
import 'package:propofol_dreams_app/components/material3/m3_text_field.dart';
import 'package:propofol_dreams_app/screens/m3_test_screen.dart';

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
    pumpController.text = settings.max_pump_rate.toString();
  }

  @override
  void dispose() {
    pumpController.dispose();
    super.dispose();
  }

  String _fmt(double c, String unit) {
    return '${c.toStringAsFixed(c == c.roundToDouble() ? 0 : 1)} $unit';
  }

  Widget _buildDrugConcentrationSection(Drug drug, Settings settings) {
    final availableVariants =
        settings.getAvailableDrugVariants(drug.displayName);
    final availableConcentrations =
        availableVariants.map((v) => v.concentration).toList();
    final currentConcentration = settings.getDrugConcentration(drug);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(drug.icon, size: 18, color: drug.getColor(context)),
            const SizedBox(width: kSp8),
            Text(
              drug.toLocalizedString(context),
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: kSp12),
        if (availableConcentrations.length > 1)
          SegmentedButton<String>(
            segments: availableVariants
                .map((v) => ButtonSegment(
                      value: v.concentration.toString(),
                      label: Text(
                          _fmt(v.concentration, drug.concentrationUnit.displayName)),
                    ))
                .toList(),
            selected: {currentConcentration.toString()},
            onSelectionChanged: (Set<String> selected) {
              if (selected.length == 1) {
                final conc = double.parse(selected.first);
                settings.setDrugConcentration(drug, conc);
                setState(() {});
              }
            },
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: kSp12, horizontal: kSp16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(kRadius),
            ),
            child: Text(
              _fmt(currentConcentration, drug.concentrationUnit.displayName),
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  /// Appearance section (theme).
  Widget _buildAppearanceSection(Settings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.appearance,
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(height: kSp16),
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(value: ThemeMode.light, label: Text('Light')),
            ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
            ButtonSegment(value: ThemeMode.system, label: Text('System')),
          ],
          selected: {settings.themeModeSelection},
          onSelectionChanged: (Set<ThemeMode> selected) {
            if (selected.length == 1) {
              settings.themeModeSelection = selected.first;
            }
          },
        ),
      ],
    );
  }

  /// Volume mode section.
  Widget _buildVolumeModeSection(Settings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Volume Mode', style: const TextStyle(fontSize: 18)),
        const SizedBox(height: kSp16),
        SegmentedButton<VolumeMode>(
          segments: const [
            ButtonSegment(value: VolumeMode.Volume, label: Text('Volume')),
            ButtonSegment(
                value: VolumeMode.VolumePlus, label: Text('Volume Plus')),
          ],
          selected: {settings.volumeMode},
          onSelectionChanged: (Set<VolumeMode> selected) {
            if (selected.length == 1) {
              settings.volumeMode = selected.first;
            }
          },
        ),
      ],
    );
  }

  /// Drug concentration section.
  Widget _buildDrugConcentrationsSection(Settings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.drugConcentration,
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(height: kSp8),
        _buildDrugConcentrationSection(Drug.propofol10mg, settings),
        const SizedBox(height: kSp8),
        _buildDrugConcentrationSection(Drug.remifentanil50mcg, settings),
        const SizedBox(height: kSp8),
        _buildDrugConcentrationSection(Drug.dexmedetomidine, settings),
        const SizedBox(height: kSp8),
        _buildDrugConcentrationSection(Drug.remimazolam1mg, settings),
      ],
    );
  }

  /// Maximum pump rate section.
  Widget _buildPumpRateSection(Settings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.maximumPumpRate,
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(height: kSp16),
        M3TextField(
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
          range: const [0, 1500],
        ),
      ],
    );
  }

  /// About section (M3 Lab link).
  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('About', style: const TextStyle(fontSize: 18)),
        const SizedBox(height: kSp8),
        ListTile(
          leading: const Icon(Icons.science),
          title: const Text('Material 3 Test Lab'),
          subtitle: const Text('Compare M3 and legacy components'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const M3TestScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  /// General settings column (left side on tablet/desktop).
  Widget _buildGeneralColumn(Settings settings) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildAppearanceSection(settings),
        const SizedBox(height: kSp24),
        _buildVolumeModeSection(settings),
      ],
    );
  }

  /// Detailed settings column (right side on tablet/desktop).
  Widget _buildDetailedColumn(Settings settings) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildDrugConcentrationsSection(settings),
        const SizedBox(height: kSp24),
        _buildPumpRateSection(settings),
        const SizedBox(height: kSp24),
        _buildAboutSection(),
      ],
    );
  }

  /// Tablet 2-column layout: general settings on left (320px), details on right.
  Widget _buildTabletLayout(Settings settings) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: horizontalSidesPaddingPixel,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 320,
            child: _buildGeneralColumn(settings),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildDetailedColumn(settings),
          ),
        ],
      ),
    );
  }

  /// Desktop 2-column layout: general settings on left, details on right.
  Widget _buildDesktopLayout(Settings settings) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: horizontalSidesPaddingPixel,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 360,
            child: _buildGeneralColumn(settings),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildDetailedColumn(settings),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<Settings>();
    final isDesktopLayout = ResponsiveHelper.isDesktop(context);
    final isTabletLayout = ResponsiveHelper.isTablet(context) && !isDesktopLayout;

    return Column(children: [
      const SizedBox(height: kSp16),
      Expanded(
        child: isDesktopLayout
            ? _buildDesktopLayout(settings)
            : isTabletLayout
                ? _buildTabletLayout(settings)
                : Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: horizontalSidesPaddingPixel),
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        _buildAppearanceSection(settings),
                        const SizedBox(height: kSp24),
                        _buildDrugConcentrationsSection(settings),
                        const SizedBox(height: kSp24),
                        _buildPumpRateSection(settings),
                        const SizedBox(height: kSp24),
                        _buildVolumeModeSection(settings),
                        const SizedBox(height: kSp24),
                        _buildAboutSection(),
                        const SizedBox(height: kSp16),
                      ],
                    ),
                  ),
      ),
    ]);
  }
}
