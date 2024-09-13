import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import the generated localization file

enum Target {
  Plasma(),
  EffectSite();

  // Updated toString method to call localizedString
  String toLocalizedString(BuildContext context) {
    switch (this) {
      case Target.Plasma:
        return AppLocalizations.of(context)!.plasma;
      case Target.EffectSite:
        return AppLocalizations.of(context)!.effectSite;
    }
  }

  @override
  String toString() {
    return name;
  }

  // const Target();
}