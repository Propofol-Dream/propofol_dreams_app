import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import the generated localization file

enum Gender {
  Female,
  Male;

  // Updated toString method to call localizedString
  String toLocalizedString(BuildContext context) {
    switch (this) {
      case Gender.Female:
        return AppLocalizations.of(context)!.female;
      case Gender.Male:
        return AppLocalizations.of(context)!.male;
    }
  }

  @override
  String toString(){
    return name;
  }


}