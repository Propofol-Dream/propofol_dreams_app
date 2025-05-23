import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:propofol_dreams_app/models/InfusionUnit.dart';
import 'package:propofol_dreams_app/models/model.dart';
import 'package:propofol_dreams_app/models/sex.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings with ChangeNotifier {
  ThemeMode _themeModeSelection = ThemeMode.system;

  ThemeMode get themeModeSelection {
    return _themeModeSelection;
  }

  set themeModeSelection(ThemeMode tm) {
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

  set isDarkTheme(bool b) {
    _isDarkTheme = b;
    setBool('isDarkTheme', b);
    notifyListeners();
  }

  int _density = 10;

  int get density {
    return _density;
  }

  set density(int i) {
    _density = i;
    setInt('density', i);
    notifyListeners();
  }

  int _time_step = 1;

  int get time_step {
    return _time_step;
  }

  set time_step(int i) {
    _time_step = i;
    setInt('time_step', i);
    notifyListeners();
  }

  int _max_pump_rate = 1200;

  int get max_pump_rate {
    return _max_pump_rate;
  }

  set max_pump_rate(int i) {
    _max_pump_rate = i;
    setInt('max_pump_rate_20230820', i);
    notifyListeners();
  }

  bool _showMaxPumpRate = false;

  bool get showMaxPumpRate {
    return _showMaxPumpRate;
  }

  set showMaxPumpRate(bool b) {
    _showMaxPumpRate = b;
    setBool('_showMaxPumpRate', b);
    notifyListeners();
  }


  Model _adultModel = Model.None;
  Sex? _adultSex;
  int? _adultAge;
  int? _adultHeight;
  int? _adultWeight;
  double? _adultTarget;
  int? _adultDuration;

  Model get adultModel {
    return _adultModel;
  }

  set adultModel(Model m) {
    _adultModel = m;
    setString('adultModel', m.toString());
    notifyListeners();
  }

  Sex? get adultSex {
    return _adultSex;
  }

  set adultSex(Sex? s) {
    _adultSex = s;
    setString('adultSex', s.toString());
    notifyListeners();
  }

  int? get adultAge {
    return _adultAge;
  }

  set adultAge(int? i) {
    _adultAge = i;
    setInt('adultAge', i);
    notifyListeners();
  }

  int? get adultHeight {
    return _adultHeight;
  }

  set adultHeight(int? i) {
    _adultHeight = i;
    setInt('adultHeight', i);
    notifyListeners();
  }

  int? get adultWeight {
    return _adultWeight;
  }

  set adultWeight(int? i) {
    // print(i);
    // if (_adultWeight != i) {
    _adultWeight = i;
    setInt('adultWeight', i);
    // print('weight setInt');
    notifyListeners();
    // }
  }

  double? get adultTarget {
    return _adultTarget;
  }

  set adultTarget(double? d) {
    _adultTarget = d;
    setDouble('adultTarget', d);
    notifyListeners();
  }

  int? get adultDuration {
    return _adultDuration;
  }

  set adultDuration(int? i) {
    _adultDuration = i;
    setInt('adultDuration', i);
    notifyListeners();
  }

  Model _pediatricModel = Model.None;
  Sex? _pediatricSex;
  int? _pediatricAge;
  int? _pediatricHeight;
  int? _pediatricWeight;
  double? _pediatricTarget;
  int? _pediatricDuration;

  Model get pediatricModel {
    return _pediatricModel;
  }

  set pediatricModel(Model m) {
    _pediatricModel = m;
    setString('pediatricModel', m.toString());
    notifyListeners();
  }

  Sex? get pediatricSex {
    return _pediatricSex;
  }

  set pediatricSex(Sex? s) {
    _pediatricSex = s;
    setString('pediatricSex', s.toString());
    notifyListeners();
  }

  int? get pediatricAge {
    return _pediatricAge;
  }

  set pediatricAge(int? i) {
    _pediatricAge = i;
    setInt('pediatricAge', i);
    notifyListeners();
  }

  int? get pediatricHeight {
    return _pediatricHeight;
  }

  set pediatricHeight(int? i) {
    _pediatricHeight = i;
    setInt('pediatricHeight', i);
    notifyListeners();
  }

  int? get pediatricWeight {
    return _pediatricWeight;
  }

  set pediatricWeight(int? i) {
    _pediatricWeight = i;
    setInt('pediatricWeight', i);
    notifyListeners();
  }

  double? get pediatricTarget {
    return _pediatricTarget;
  }

  set pediatricTarget(double? d) {
    _pediatricTarget = d;
    setDouble('pediatricTarget', d);
    notifyListeners();
  }

  int? get pediatricDuration {
    return _pediatricDuration;
  }

  set pediatricDuration(int? i) {
    _pediatricDuration = i;
    setInt('pediatricDuration', i);
    notifyListeners();
  }

  bool _inAdultView = true;

  bool get inAdultView {
    return _inAdultView;
  }

  set inAdultView(bool b) {
    _inAdultView = b;
    setBool('inAdultView', b);
    notifyListeners();
  }

  bool _isVolumeTableExpanded = false;

  bool get isVolumeTableExpanded {
    return _isVolumeTableExpanded;
  }

  set isVolumeTableExpanded(bool b) {
    _isVolumeTableExpanded = b;
    setBool('isVolumeTableExpanded', b);
    notifyListeners();
  }

  int? _weight;

  int? get weight {
    return _weight;
  }

  set weight(int? i) {
    _weight = i;
    setInt('weight', i);
    notifyListeners();
  }

  double? _infusionRate = 10;

  double? get infusionRate {
    return _infusionRate;
  }

  set infusionRate(double? d) {
    _infusionRate = d;
    setDouble('infusionRate', d);
    notifyListeners();
  }

  InfusionUnit _infusinUnit = InfusionUnit.mg_kg_hr;

  InfusionUnit get infusionUnit {
    return _infusinUnit;
  }

  set infusionUnit(InfusionUnit iu) {
    _infusinUnit = iu;
    setString('infusionUnit', iu.toString());
    notifyListeners();
  }

  Sex? _EMSex;
  int? _EMAge;
  int? _EMHeight;
  int? _EMWeight;
  double? _EMTarget;
  int? _EMDuration;

  String? _EMFlow;

  Model _EMWakeUpModel = Model.None;
  double? _EMMaintenanceCe;
  int? _EMMaintenanceSE;
  double? _EMInfusionRate;

  Sex? get EMSex {
    return _EMSex;
  }

  set EMSex(Sex? s) {
    _EMSex = s;
    setString('EMSex', s.toString());
    notifyListeners();
  }

  int? get EMAge {
    return _EMAge;
  }

  set EMAge(int? i) {
    _EMAge = i;
    setInt('EMAge', i);
    notifyListeners();
  }

  int? get EMHeight {
    return _EMHeight;
  }

  set EMHeight(int? i) {
    _EMHeight = i;
    setInt('EMHeight', i);
    notifyListeners();
  }

  int? get EMWeight {
    return _EMWeight;
  }

  set EMWeight(int? i) {
    _EMWeight = i;
    setInt('EMWeight', i);
    notifyListeners();
    // }
  }

  double? get EMTarget {
    return _EMTarget;
  }

  set EMTarget(double? d) {
    _EMTarget = d;
    setDouble('EMTarget', d);
    notifyListeners();
  }

  int? get EMDuration {
    return _EMDuration;
  }

  set EMDuration(int? i) {
    _EMDuration = i;
    setInt('EMDuration', i);
    notifyListeners();
  }

  String? get EMFlow {
    return _EMFlow;
  }

  set EMFlow(String? s) {
    _EMFlow = s;
    setString('EMFlow', s.toString());
    notifyListeners();
  }

  Model get EMWakeUpModel {
    return _EMWakeUpModel;
  }

  set EMWakeUpModel(Model m) {
    _EMWakeUpModel = m;
    setString('EMWakeUpModel', m.toString());
    notifyListeners();
  }

  double? get EMMaintenanceCe {
    return _EMMaintenanceCe;
  }

  set EMMaintenanceCe(double? d) {
    _EMMaintenanceCe = d;
    setDouble('EMMaintenanceCe', d);
    notifyListeners();
  }

  int? get EMMaintenanceSE {
    return _EMMaintenanceSE;
  }

  set EMMaintenanceSE(int? i) {
    _EMMaintenanceSE = i;
    setInt('EMMaintenanceSE', i);
    notifyListeners();
  }

  double? get EMInfusionRate {
    return _EMInfusionRate;
  }

  set EMInfusionRate(double? d) {
    _EMInfusionRate = d;
    setDouble('_EMInfusionRate', d);
    notifyListeners();
  }

  bool _EMRSI = false;
  bool get EMRSI {
    return _EMRSI;
  }

  set EMRSI(bool b) {
    _EMRSI = b;
    setBool('EMRSI', b);
    notifyListeners();
  }


  double? _calculatorWakeUpCE;
  int? _calculatorWakeUpSE;

  double? get calculatorWakeUpCE {
    return _calculatorWakeUpCE;
  }

  set calculatorWakeUpCE(double? d){
    _calculatorWakeUpCE = d;
    setDouble('calculatorWakeUpCE', d);
    notifyListeners();
  }


  int? get calculatorWakeUpSE {
    return _calculatorWakeUpSE;
  }

  set calculatorWakeUpSE(int? i) {
    _calculatorWakeUpSE = i;
    setInt('EMObservedSE', i);
    notifyListeners();
  }





  int _currentScreenIndex = 0;

  int get currentScreenIndex {
    return _currentScreenIndex;
  }

  set currentScreenIndex(int i) {
    _currentScreenIndex = i;
    setInt('currentScreenIndex', i);
    notifyListeners();
  }

  Future<void> setInt(String key, int? i) async {
    var pref = await SharedPreferences.getInstance();
    if (i != null) {
      pref.setInt(key, i);
    }

  }

  Future<void> setDouble(String key, double? d) async {
    var pref = await SharedPreferences.getInstance();
    if (d != null) {
      pref.setDouble(key, d);
    }

  }

  Future<void> setBool(String key, bool? b) async {
    var pref = await SharedPreferences.getInstance();
    if (b != null) {
      pref.setBool(key, b);
    }

  }

  Future<void> setString(String key, String? s) async {
    var pref = await SharedPreferences.getInstance();
    if (s != null) {
      pref.setString(key, s);
    }
  }
}
