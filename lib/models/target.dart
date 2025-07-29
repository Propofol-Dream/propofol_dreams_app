import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:propofol_dreams_app/l10n/generated/app_localizations.dart';

enum Target {
  Plasma(icon: Symbols.psychology_alt),
  EffectSite(icon: Symbols.psychology_alt);

  const Target({required this.icon});
  final IconData icon;

  // Updated toString method to call localizedString
  String toLocalizedString(BuildContext context) {
    switch (this) {
      case Target.Plasma:
        return AppLocalizations.of(context)!.plasmaTarget;
      case Target.EffectSite:
        return AppLocalizations.of(context)!.effectSiteTarget;
    }
  }

  @override
  String toString() {
    return name;
  }

  // const Target();
}