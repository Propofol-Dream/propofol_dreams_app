import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:propofol_dreams_app/models/InfusionUnit.dart';
import 'package:propofol_dreams_app/models/model.dart';
import 'package:propofol_dreams_app/models/gender.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings with ChangeNotifier {
  ThemeMode _themeModeSelection = ThemeMode.system;

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

    setString('themeMode', _themeModeSelection.toString());
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
    setBool('isDarkTheme', b);
    notifyListeners();
    // }
  }

  // Future<void> load() async {
  //   print('Setting load');
  //   var pref = await SharedPreferences.getInstance();
  //   // print('pref: ${pref.getBool("isDarkTheme")}');
  //   // _isDarkTheme = pref.getBool("isDarkTheme") ?? false;
  //   // print('settings.isDarkTheme: ${pref.getBool("isDarkTheme")}');
  //   print('pref: ${pref.getInt('adultWeight')}');
  //   print('settings.adultWeight: ${adultWeight}');
  //   // adultWeight = pref.getInt('adultWeight') ?? 70;
  //   print('settings.adultWeight: ${adultWeight}');
  //   // notifyListeners();
  // }

  // Future<void> save() async {
  //   print('Setting save');
  //   var pref = await SharedPreferences.getInstance();
  //   // print('settings.isDarkTheme: ${pref.getBool("isDarkTheme")}');
  //   // pref.setBool('isDarkTheme', _isDarkTheme);
  //   // print('pref: ${pref.getBool("isDarkTheme")}');
  //   pref.setInt('adultWeight', _adultWeight!);
  //
  // }

  int _dilution = 10;

  int get dilution {
    return _dilution;
  }

  void set dilution(int i) {
    _dilution = i;
    setInt('dilution', i);
    notifyListeners();
  }

  int _time_step = 1;

  int get time_step {
    return _time_step;
  }

  void set time_step(int i) {
    _time_step = i;
    setInt('time_step', i);
    notifyListeners();
  }

  int _max_pump_rate = 750;

  int get max_pump_rate {
    return _max_pump_rate;
  }

  void set max_pump_rate(int i) {
    // print('set max_pump_rate to ${i}');
    // if(max_pump_rate != i) {
      _max_pump_rate = i;
      setInt('max_pump_rate', i);
      notifyListeners();
    // }
  }

  Model _adultModel = Model.None;
  Gender? _adultGender;
  int? _adultAge;
  int? _adultHeight;
  int? _adultWeight;
  double? _adultDepth;
  int? _adultDuration;

  Model get adultModel {
    return _adultModel;
  }

  void set adultModel(Model m) {
    _adultModel = m;
    setString('adultModel', m.toString());
    notifyListeners();
  }

  Gender? get adultGender {
    return _adultGender;
  }

  void set adultGender(Gender? g) {
    _adultGender = g;
    setString('adultGender', g.toString());
    notifyListeners();
  }

  int? get adultAge {
    return _adultAge;
  }

  void set adultAge(int? i) {
    _adultAge = i;
    setInt('adultAge', i);
    notifyListeners();
  }

  int? get adultHeight {
    return _adultHeight;
  }

  void set adultHeight(int? i) {
    _adultHeight = i;
    setInt('adultHeight', i);
    notifyListeners();
  }

  int? get adultWeight {
    return _adultWeight;
  }

  void set adultWeight(int? i) {
    // print(i);
    // if (_adultWeight != i) {
      _adultWeight = i;
      setInt('adultWeight', i);
      // print('weight setInt');
      notifyListeners();
    // }
  }

  double? get adultDepth {
    return _adultDepth;
  }

  void set adultDepth(double? d) {
    _adultDepth = d;
    setDouble('adultDepth', d);
    notifyListeners();
  }

  int? get adultDuration {
    return _adultDuration;
  }

  void set adultDuration(int? i) {
    _adultDuration = i;
    setInt('adultDuration', i);
    notifyListeners();
  }

  Model _pediatricModel = Model.None;
  Gender? _pediatricGender;
  int? _pediatricAge;
  int? _pediatricHeight;
  int? _pediatricWeight;
  double? _pediatricDepth;
  int? _pediatricDuration;

  Model get pediatricModel {
    return _pediatricModel;
  }

  void set pediatricModel(Model m) {
    _pediatricModel = m;
    setString('pediatricModel', m.toString());
    notifyListeners();
  }

  Gender? get pediatricGender {
    return _pediatricGender;
  }

  void set pediatricGender(Gender? g) {
    _pediatricGender = g;
    setString('pediatricGender', g.toString());
    notifyListeners();
  }

  int? get pediatricAge {
    return _pediatricAge;
  }

  void set pediatricAge(int? i) {
    _pediatricAge = i;
    setInt('pediatricAge', i);
    notifyListeners();
  }

  int? get pediatricHeight {
    return _pediatricHeight;
  }

  void set pediatricHeight(int? i) {
    _pediatricHeight = i;
    setInt('pediatricHeight', i);
    notifyListeners();
  }

  int? get pediatricWeight {
    return _pediatricWeight;
  }

  void set pediatricWeight(int? i) {
    _pediatricWeight = i;
    setInt('pediatricWeight', i);
    notifyListeners();
  }

  double? get pediatricDepth {
    return _pediatricDepth;
  }

  void set pediatricDepth(double? d) {
    _pediatricDepth = d;
    setDouble('pediatricDepth', d);
    notifyListeners();
  }

  int? get pediatricDuration {
    return _pediatricDuration;
  }

  void set pediatricDuration(int? i) {
    _pediatricDuration = i;
    setInt('pediatricDuration', i);
    notifyListeners();
  }

  bool _inAdultView = true;

  bool get inAdultView {
    return _inAdultView;
  }

  void set inAdultView(bool b) {
    _inAdultView = b;
    setBool('inAdultView', b);
    notifyListeners();
  }

  bool _isVolumeTableExpanded = false;

  bool get isVolumeTableExpanded {
    return _isVolumeTableExpanded;
  }

  void set isVolumeTableExpanded(bool b) {
    _isVolumeTableExpanded = b;
    setBool('isVolumeTableExpanded', b);
    notifyListeners();
  }

  int? _weight;

  int? get weight {
    return _weight;
  }

  void set weight(int? i) {
    _weight = i;
    setInt('weight', i);
    notifyListeners();
  }

  double? _infusionRate = 10;

  double? get infusionRate {
    return _infusionRate;
  }

  void set infusionRate(double? d) {
    _infusionRate = d;
    setDouble('infusionRate', d);
    notifyListeners();
  }

  InfusionUnit _infusinUnit = InfusionUnit.mg_kg_hr;

  InfusionUnit get infusionUnit {
    return _infusinUnit;
  }

  void set infusionUnit(InfusionUnit iu) {
    _infusinUnit = iu;
    setString('infusionUnit', iu.toString());
    notifyListeners();
  }

  int _currentScreenIndex = 0;

  int get currentScreenIndex {
    return _currentScreenIndex;
  }

  void set currentScreenIndex(int i) {
    _currentScreenIndex = i;
    setInt('currentScreenIndex', i);
    notifyListeners();
  }

  Future<void> setInt(String key, int? i) async {
    var pref = await SharedPreferences.getInstance();
    if (i != null) {
      pref.setInt(key, i);
    }
    // else {
    //   pref.remove(key);
    // }
  }

  Future<void> setDouble(String key, double? d) async {
    var pref = await SharedPreferences.getInstance();
    if (d != null) {
      pref.setDouble(key, d);
    }
    // else {
    //   pref.remove(key);
    // }
  }

  Future<void> setBool(String key, bool? b) async {
    var pref = await SharedPreferences.getInstance();
    if (b != null) {
      pref.setBool(key, b);
    }
    // else {
    //   pref.remove(key);
    // }
  }

  Future<void> setString(String key, String? s) async {
    var pref = await SharedPreferences.getInstance();
    if (s != null) {
      pref.setString(key, s);
    }
    // else {
    //   pref.remove(key);
    // }
  }
}
