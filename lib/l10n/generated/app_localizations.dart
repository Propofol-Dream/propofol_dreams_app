import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')
  ];

  ///
  ///
  /// In en, this message translates to:
  /// **'ABW'**
  String get abw;

  ///
  ///
  /// In en, this message translates to:
  /// **'Adult'**
  String get adult;

  ///
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  ///
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  ///
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get auto;

  ///
  ///
  /// In en, this message translates to:
  /// **'Bolus'**
  String get bolus;

  ///
  ///
  /// In en, this message translates to:
  /// **'Boy'**
  String get boy;

  ///
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  ///
  ///
  /// In en, this message translates to:
  /// **'Confidence\nInterval'**
  String get confidenceInterval;

  ///
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  ///
  ///
  /// In en, this message translates to:
  /// **'Drug'**
  String get drug;

  ///
  ///
  /// In en, this message translates to:
  /// **'Drug Concentration'**
  String get drugConcentration;

  ///
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  ///
  ///
  /// In en, this message translates to:
  /// **'Effect Site'**
  String get effectSite;

  ///
  ///
  /// In en, this message translates to:
  /// **'Effect Site Target'**
  String get effectSiteTarget;

  ///
  ///
  /// In en, this message translates to:
  /// **'Wake'**
  String get emerge;

  ///
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  ///
  ///
  /// In en, this message translates to:
  /// **'Girl'**
  String get girl;

  ///
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get height;

  ///
  ///
  /// In en, this message translates to:
  /// **'Induce'**
  String get induce;

  ///
  ///
  /// In en, this message translates to:
  /// **'Induction'**
  String get induction;

  ///
  ///
  /// In en, this message translates to:
  /// **'Infusion Rate'**
  String get infusionRate;

  ///
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  ///
  ///
  /// In en, this message translates to:
  /// **'Maintenance Ce'**
  String get maintenanceCe;

  ///
  ///
  /// In en, this message translates to:
  /// **'Maintenance Cp'**
  String get maintenanceCp;

  ///
  ///
  /// In en, this message translates to:
  /// **'Maintenance State Entropy'**
  String get maintenanceStateEntropy;

  ///
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  ///
  ///
  /// In en, this message translates to:
  /// **'Manual Bolus'**
  String get manualBolus;

  ///
  ///
  /// In en, this message translates to:
  /// **'Maximum Pump Rate'**
  String get maximumPumpRate;

  ///
  ///
  /// In en, this message translates to:
  /// **'mins'**
  String get mins;

  ///
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get min;

  ///
  ///
  /// In en, this message translates to:
  /// **'mL'**
  String get ml;

  ///
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get model;

  ///
  ///
  /// In en, this message translates to:
  /// **'Paed'**
  String get paed;

  ///
  ///
  /// In en, this message translates to:
  /// **'Plasma'**
  String get plasma;

  ///
  ///
  /// In en, this message translates to:
  /// **'Plasma Target'**
  String get plasmaTarget;

  ///
  ///
  /// In en, this message translates to:
  /// **'Predicted'**
  String get predicted;

  ///
  ///
  /// In en, this message translates to:
  /// **'Propofol'**
  String get propofol;

  ///
  ///
  /// In en, this message translates to:
  /// **'Remifentanil'**
  String get remifentanil;

  ///
  ///
  /// In en, this message translates to:
  /// **'Dexmedetomidine'**
  String get dexmedetomidine;

  ///
  ///
  /// In en, this message translates to:
  /// **'Remimazolam'**
  String get remimazolam;

  ///
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get rate;

  ///
  ///
  /// In en, this message translates to:
  /// **'Select Drug'**
  String get selectDrug;

  ///
  ///
  /// In en, this message translates to:
  /// **'Propofol Formulation'**
  String get propofolFormulation;

  ///
  ///
  /// In en, this message translates to:
  /// **'Pump Rate'**
  String get pumpRate;

  ///
  ///
  /// In en, this message translates to:
  /// **'Sex'**
  String get sex;

  ///
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  ///
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get target;

  ///
  ///
  /// In en, this message translates to:
  /// **'TCI'**
  String get tci;

  ///
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  ///
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get volume;

  ///
  ///
  /// In en, this message translates to:
  /// **'Wake'**
  String get wake;

  ///
  ///
  /// In en, this message translates to:
  /// **'Wake Up Range'**
  String get wakeUpRange;

  ///
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hans':
            return AppLocalizationsZhHans();
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
