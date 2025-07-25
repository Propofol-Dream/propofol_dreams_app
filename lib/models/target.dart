import 'package:flutter/material.dart';
import 'package:propofol_dreams_app/l10n/generated/app_localizations.dart';

enum Target {
  Plasma(),
  EffectSite();

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