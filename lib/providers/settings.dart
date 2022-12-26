import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:propofol_dreams_app/models/InfusionUnit.dart';
import 'package:propofol_dreams_app/models/model.dart';
import 'package:propofol_dreams_app/models/gender.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings with ChangeNotifier {
  ThemeMode _themeModeSelection = ThemeMode.light;

  ThemeMode get themeModeSelection {
    return _themeModeSelection;
  }

  void set themeModeSelection(ThemeMode tm) {
    _themeModeSelection = tm;

    switch (_themeModeSelection) {
      case ThemeMode.light:
        {
          isDarkTheme = false;
        }
        break;

      case ThemeMode.dark:
        {
          isDarkTheme = true;
        }
        break;

      case ThemeMode.system:
        {
          var brightness = SchedulerBinding.instance.window.platformBrightness;
          isDarkTheme = brightness == Brightness.dark ? true : false;
        }
        break;

      default:
        {
          isDarkTheme = false;
        }
        break;
    }
    notifyListeners();
  }

  bool _isDarkTheme = false;

  bool get isDarkTheme {
    return _isDarkTheme;
  }

  void set isDarkTheme(bool b) {
    //the if statement is to prevent rebuilt of any widget;
    // if (_isDarkTheme != b) {
    _isDarkTheme = b;
    notifyListeners();
    // }
  }

  Future<void> load() async {
    print('Setting load');
    var pref = await SharedPreferences.getInstance();
    // print('pref: ${pref.getBool("isDarkTheme")}');
    // _isDarkTheme = pref.getBool("isDarkTheme") ?? false;
    // print('settings.isDarkTheme: ${pref.getBool("isDarkTheme")}');
    print('pref: ${pref.getInt('adultWeight')}');
    print('settings.adultWeight: ${adultWeight}');
    _adultWeight = pref.getInt('adultWeight') ?? 70;
    print('settings.adultWeight: ${adultWeight}');
    notifyListeners();
  }

  Future<void> save() async {
    print('Setting save');
    var pref = await SharedPreferences.getInstance();
    // print('settings.isDarkTheme: ${pref.getBool("isDarkTheme")}');
    // pref.setBool('isDarkTheme', _isDarkTheme);
    // print('pref: ${pref.getBool("isDarkTheme")}');
    pref.setInt('adultWeight', _adultWeight!);

  }

  int? _dilution = 10;

  int? get dilution {
    return _dilution;
  }

  void set dilution(int? i) {
    _dilution = i;
    notifyListeners();
  }

  int? _time_step = 1;

  int? get time_step {
    return _time_step;
  }

  void set time_step(int? i) {
    _time_step = i;
    notifyListeners();
  }

  int? _max_pump_rate = 750;

  int? get max_pump_rate {
    return _max_pump_rate;
  }

  void set max_pump_rate(int? i) {
    _max_pump_rate = i;
    notifyListeners();
  }

  Model _adultModel = Model.Marsh;
  Gender? _adultGender = Gender.Female;
  int? _adultAge = 40;
  int? _adultHeight = 170;
  int? _adultWeight = 70;
  double? _adultDepth = 3.0;
  int? _adultDuration = 60;

  Model get adultModel {
    return _adultModel;
  }

  void set adultModel(Model m) {
    _adultModel = m;
    notifyListeners();
  }

  Gender? get adultGender {
    return _adultGender;
  }

  void set adultGender(Gender? g) {
    _adultGender = g;
    notifyListeners();
  }

  int? get adultAge {
    return _adultAge;
  }

  void set adultAge(int? i) {
    _adultAge = i;
    notifyListeners();
  }

  int? get adultHeight {
    return _adultHeight;
  }

  void set adultHeight(int? i) {
    _adultHeight = i;
    notifyListeners();
  }

  int? get adultWeight {
    return _adultWeight;
  }

  void set adultWeight(int? i) {
    _adultWeight = i;
    notifyListeners();
  }

  double? get adultDepth {
    return _adultDepth;
  }

  void set adultDepth(double? d) {
    _adultDepth = d;
    notifyListeners();
  }

  int? get adultDuration {
    return _adultDuration;
  }

  void set adultDuration(int? i) {
    _adultDuration = i;
    notifyListeners();
  }

  Model _pediatricModel = Model.Paedfusor;
  Gender? _pediatricGender = Gender.Female;
  int? _pediatricAge = 8;
  int? _pediatricHeight = 130;
  int? _pediatricWeight = 26;
  double? _pediatricDepth = 3.0;
  int? _pediatricDuration = 60;

  Model get pediatricModel {
    return _pediatricModel;
  }

  void set pediatricModel(Model m) {
    _pediatricModel = m;
    notifyListeners();
  }

  Gender? get pediatricGender {
    return _pediatricGender;
  }

  void set pediatricGender(Gender? g) {
    _pediatricGender = g;
    notifyListeners();
  }

  int? get pediatricAge {
    return _pediatricAge;
  }

  void set pediatricAge(int? i) {
    _pediatricAge = i;
    notifyListeners();
  }

  int? get pediatricHeight {
    return _pediatricHeight;
  }

  void set pediatricHeight(int? i) {
    _pediatricHeight = i;
    notifyListeners();
  }

  int? get pediatricWeight {
    return _pediatricWeight;
  }

  void set pediatricWeight(int? i) {
    _pediatricWeight = i;
    notifyListeners();
  }

  double? get pediatricDepth {
    return _pediatricDepth;
  }

  void set pediatricDepth(double? d) {
    _pediatricDepth = d;
    notifyListeners();
  }

  int? get pediatricDuration {
    return _pediatricDuration;
  }

  void set pediatricDuration(int? i) {
    _pediatricDuration = i;
    notifyListeners();
  }

  bool _inAdultView = true;

  bool get inAdultView {
    return _inAdultView;
  }

  void set inAdultView(bool b) {
    _inAdultView = b;
    notifyListeners();
  }

  bool _isVolumeTableExpanded = false;

  bool get isVolumeTableExpanded {
    return _isVolumeTableExpanded;
  }

  void set isVolumeTableExpanded(bool b) {
    _isVolumeTableExpanded = b;
    notifyListeners();
  }

  double? _infusionRate = 10;

  double? get infusionRate {
    return _infusionRate;
  }

  void set infusionRate(double? i) {
    _infusionRate = i;
    notifyListeners();
  }

  int? _weight = 70;

  int? get weight {
    return _weight;
  }

  void set weight(int? i) {
    _weight = i;
    notifyListeners();
  }

  InfusionUnit _infusinUnit = InfusionUnit.mg_kg_h;

  InfusionUnit get infusionUnit {
    return _infusinUnit;
  }

  void set infusionUnit(InfusionUnit iu) {
    _infusinUnit = iu;
    notifyListeners();
  }
}
