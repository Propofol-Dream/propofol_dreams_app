import 'package:flutter/material.dart';
import 'package:propofol_dreams_app/l10n/generated/app_localizations.dart';

enum Sex {
  Female,
  Male,
  Girl,
  Boy;

  // Updated toString method to call localizedString
  String toLocalizedString(BuildContext context) {
    switch (this) {
      case Sex.Female:
        return AppLocalizations.of(context)!.female;
      case Sex.Male:
        return AppLocalizations.of(context)!.male;
      case Sex.Girl:
        return AppLocalizations.of(context)!.girl;
      case Sex.Boy:
        return AppLocalizations.of(context)!.boy;
    }
  }

  @override
  String toString(){
    return name;
  }

}
