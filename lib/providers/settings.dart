import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:propofol_dreams_app/models/InfusionUnit.dart';
import 'package:propofol_dreams_app/models/model.dart';
import 'package:propofol_dreams_app/models/sex.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings with ChangeNotifier {
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
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
    setBool('showMaxPumpRate', b);
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
    setDouble('EMInfusionRate', d);
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
    setInt('calculatorWakeUpSE', i);
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

  int? _selectedDosageTableRow;
  int? _selectedVolumeTableRow;
  int? _selectedDurationTableRow;
  double? _dosageTableScrollPosition;
  double? _volumeTableScrollPosition;

  int? get selectedDosageTableRow {
    return _selectedDosageTableRow;
  }

  set selectedDosageTableRow(int? i) {
    _selectedDosageTableRow = i;
    setInt('selectedDosageTableRow', i);
    notifyListeners();
  }

  int? get selectedVolumeTableRow {
    return _selectedVolumeTableRow;
  }

  set selectedVolumeTableRow(int? i) {
    _selectedVolumeTableRow = i;
    setInt('selectedVolumeTableRow', i);
    notifyListeners();
  }

  int? get selectedDurationTableRow {
    return _selectedDurationTableRow;
  }

  set selectedDurationTableRow(int? i) {
    _selectedDurationTableRow = i;
    setInt('selectedDurationTableRow', i);
    notifyListeners();
  }

  double? get dosageTableScrollPosition {
    return _dosageTableScrollPosition;
  }

  set dosageTableScrollPosition(double? position) {
    _dosageTableScrollPosition = position;
    setDouble('dosageTableScrollPosition', position);
    notifyListeners();
  }

  double? get volumeTableScrollPosition {
    return _volumeTableScrollPosition;
  }

  set volumeTableScrollPosition(double? position) {
    _volumeTableScrollPosition = position;
    setDouble('volumeTableScrollPosition', position);
    notifyListeners();
  }

  // Cache SharedPreferences instance for better performance
  SharedPreferences? _prefs;

  Future<void> setInt(String key, int? i) async {
    _prefs ??= await SharedPreferences.getInstance();
    if (i != null) {
      await _prefs!.setInt(key, i);
    }
  }

  Future<void> setDouble(String key, double? d) async {
    _prefs ??= await SharedPreferences.getInstance();
    if (d != null) {
      await _prefs!.setDouble(key, d);
    }
  }

  Future<void> setBool(String key, bool? b) async {
    _prefs ??= await SharedPreferences.getInstance();
    if (b != null) {
      await _prefs!.setBool(key, b);
    }
  }

  Future<void> setString(String key, String? s) async {
    _prefs ??= await SharedPreferences.getInstance();
    if (s != null) {
      await _prefs!.setString(key, s);
    }
  }

  /// Save all current settings to disk immediately
  /// Call this when app is pausing to ensure data is saved
  Future<void> saveAllSettings() async {
    _prefs ??= await SharedPreferences.getInstance();
    
    // Save all current values to ensure they're persisted
    await Future.wait([
      _prefs!.setBool('inAdultView', _inAdultView),
      _prefs!.setInt('density', _density),
      _prefs!.setBool('isVolumeTableExpanded', _isVolumeTableExpanded),
      _prefs!.setString('adultModel', _adultModel.toString()),
      _prefs!.setString('adultSex', _adultSex.toString()),
      if (_adultAge != null) _prefs!.setInt('adultAge', _adultAge!),
      if (_adultHeight != null) _prefs!.setInt('adultHeight', _adultHeight!),
      if (_adultWeight != null) _prefs!.setInt('adultWeight', _adultWeight!),
      if (_adultTarget != null) _prefs!.setDouble('adultTarget', _adultTarget!),
      if (_adultDuration != null) _prefs!.setInt('adultDuration', _adultDuration!),
      _prefs!.setString('pediatricModel', _pediatricModel.toString()),
      _prefs!.setString('pediatricSex', _pediatricSex.toString()),
      if (_pediatricAge != null) _prefs!.setInt('pediatricAge', _pediatricAge!),
      if (_pediatricHeight != null) _prefs!.setInt('pediatricHeight', _pediatricHeight!),
      if (_pediatricWeight != null) _prefs!.setInt('pediatricWeight', _pediatricWeight!),
      if (_pediatricTarget != null) _prefs!.setDouble('pediatricTarget', _pediatricTarget!),
      if (_pediatricDuration != null) _prefs!.setInt('pediatricDuration', _pediatricDuration!),
      if (_weight != null) _prefs!.setInt('weight', _weight!),
      if (_infusionRate != null) _prefs!.setDouble('infusionRate', _infusionRate!),
      _prefs!.setString('infusionUnit', _infusinUnit.toString()),
      _prefs!.setInt('currentScreenIndex', _currentScreenIndex),
      
      // Table row selection and scroll position settings
      if (_selectedDosageTableRow != null) _prefs!.setInt('selectedDosageTableRow', _selectedDosageTableRow!),
      if (_selectedVolumeTableRow != null) _prefs!.setInt('selectedVolumeTableRow', _selectedVolumeTableRow!),
      if (_selectedDurationTableRow != null) _prefs!.setInt('selectedDurationTableRow', _selectedDurationTableRow!),
      if (_dosageTableScrollPosition != null) _prefs!.setDouble('dosageTableScrollPosition', _dosageTableScrollPosition!),
      if (_volumeTableScrollPosition != null) _prefs!.setDouble('volumeTableScrollPosition', _volumeTableScrollPosition!),
      
      // EleMarsh screen settings
      if (_EMSex != null) _prefs!.setString('EMSex', _EMSex.toString()),
      if (_EMAge != null) _prefs!.setInt('EMAge', _EMAge!),
      if (_EMHeight != null) _prefs!.setInt('EMHeight', _EMHeight!),
      if (_EMWeight != null) _prefs!.setInt('EMWeight', _EMWeight!),
      if (_EMTarget != null) _prefs!.setDouble('EMTarget', _EMTarget!),
      if (_EMDuration != null) _prefs!.setInt('EMDuration', _EMDuration!),
      if (_EMFlow != null) _prefs!.setString('EMFlow', _EMFlow!),
      _prefs!.setString('EMWakeUpModel', _EMWakeUpModel.toString()),
      if (_EMMaintenanceCe != null) _prefs!.setDouble('EMMaintenanceCe', _EMMaintenanceCe!),
      if (_EMMaintenanceSE != null) _prefs!.setInt('EMMaintenanceSE', _EMMaintenanceSE!),
      if (_EMInfusionRate != null) _prefs!.setDouble('EMInfusionRate', _EMInfusionRate!),
      _prefs!.setBool('EMRSI', _EMRSI),
      
      // Test screen settings
      if (_calculatorWakeUpCE != null) _prefs!.setDouble('calculatorWakeUpCE', _calculatorWakeUpCE!),
      if (_calculatorWakeUpSE != null) _prefs!.setInt('calculatorWakeUpSE', _calculatorWakeUpSE!),
      
      // System settings
      _prefs!.setString('themeMode', _themeModeSelection.toString()),
      _prefs!.setBool('isDarkTheme', _isDarkTheme),
      _prefs!.setInt('time_step', _time_step),
      _prefs!.setInt('max_pump_rate_20230820', _max_pump_rate),
      _prefs!.setBool('showMaxPumpRate', _showMaxPumpRate),
    ]);
  }

  /// Initialize all settings from SharedPreferences during app startup
  /// This eliminates the need for individual load() functions in screens
  Future<void> initializeFromDisk() async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();
    final pref = _prefs!;

    // Load all preferences once at startup
    _inAdultView = pref.getBool('inAdultView') ?? true;
    _density = pref.getInt('density') ?? 10;
    _isVolumeTableExpanded = pref.getBool('isVolumeTableExpanded') ?? false;

    // Adult model settings
    final adultModelString = pref.getString('adultModel');
    _adultModel = _parseModelFromString(adultModelString) ?? Model.None;
    
    final adultSexString = pref.getString('adultSex');
    _adultSex = _parseSexFromString(adultSexString) ?? Sex.Female;
    
    _adultAge = pref.getInt('adultAge') ?? 40;
    _adultHeight = pref.getInt('adultHeight') ?? 170;
    _adultWeight = pref.getInt('adultWeight') ?? 70;
    _adultTarget = pref.getDouble('adultTarget') ?? 3.0;
    _adultDuration = pref.getInt('adultDuration') ?? 60;

    // Pediatric model settings
    final pediatricModelString = pref.getString('pediatricModel');
    _pediatricModel = _parseModelFromString(pediatricModelString) ?? Model.None;
    
    final pediatricSexString = pref.getString('pediatricSex');
    _pediatricSex = _parseSexFromString(pediatricSexString) ?? Sex.Female;
    
    _pediatricAge = pref.getInt('pediatricAge') ?? 8;
    _pediatricHeight = pref.getInt('pediatricHeight') ?? 130;
    _pediatricWeight = pref.getInt('pediatricWeight') ?? 26;
    _pediatricTarget = pref.getDouble('pediatricTarget') ?? 3.0;
    _pediatricDuration = pref.getInt('pediatricDuration') ?? 60;

    // Duration screen settings
    _weight = pref.getInt('weight');
    _infusionRate = pref.getDouble('infusionRate') ?? 10;
    
    final infusionUnitString = pref.getString('infusionUnit');
    _infusinUnit = _parseInfusionUnitFromString(infusionUnitString) ?? InfusionUnit.mg_kg_hr;

    // EleMarsh screen settings
    final emSexString = pref.getString('EMSex');
    _EMSex = _parseSexFromString(emSexString) ?? Sex.Female;
    
    _EMAge = pref.getInt('EMAge');
    _EMHeight = pref.getInt('EMHeight');
    _EMWeight = pref.getInt('EMWeight');
    _EMTarget = pref.getDouble('EMTarget');
    _EMDuration = pref.getInt('EMDuration');
    _EMFlow = pref.getString('EMFlow');
    
    final emWakeUpModelString = pref.getString('EMWakeUpModel');
    _EMWakeUpModel = _parseModelFromString(emWakeUpModelString) ?? Model.None;
    
    _EMMaintenanceCe = pref.getDouble('EMMaintenanceCe');
    _EMMaintenanceSE = pref.getInt('EMMaintenanceSE');
    _EMInfusionRate = pref.getDouble('EMInfusionRate');
    _EMRSI = pref.getBool('EMRSI') ?? false;

    // Home screen settings
    _currentScreenIndex = pref.getInt('currentScreenIndex') ?? 0;

    // Table row selection and scroll position settings
    _selectedDosageTableRow = pref.getInt('selectedDosageTableRow');
    _selectedVolumeTableRow = pref.getInt('selectedVolumeTableRow');
    _selectedDurationTableRow = pref.getInt('selectedDurationTableRow');
    _dosageTableScrollPosition = pref.getDouble('dosageTableScrollPosition');
    _volumeTableScrollPosition = pref.getDouble('volumeTableScrollPosition');

    // Test screen settings
    _calculatorWakeUpCE = pref.getDouble('calculatorWakeUpCE');
    _calculatorWakeUpSE = pref.getInt('calculatorWakeUpSE');

    // System settings
    _time_step = pref.getInt('time_step') ?? 1;
    _max_pump_rate = pref.getInt('max_pump_rate_20230820') ?? 1200;
    _showMaxPumpRate = pref.getBool('showMaxPumpRate') ?? false;

    // Theme settings
    final themeModeString = pref.getString('themeMode');
    _themeModeSelection = _parseThemeModeFromString(themeModeString) ?? ThemeMode.system;
    _isDarkTheme = pref.getBool('isDarkTheme') ?? false;

    _isInitialized = true;
    // Don't call notifyListeners() here as UI hasn't been built yet
  }

  /// Parse Model enum from string
  /// Handles both new format ('Model.Marsh') and legacy format ('Marsh')
  Model? _parseModelFromString(String? modelString) {
    if (modelString == null) return null;
    switch (modelString) {
      // New format (from .toString())
      case 'Model.Marsh':
        return Model.Marsh;
      case 'Model.Schnider':
        return Model.Schnider;
      case 'Model.Eleveld':
        return Model.Eleveld;
      case 'Model.Paedfusor':
        return Model.Paedfusor;
      case 'Model.Kataria':
        return Model.Kataria;
      case 'Model.None':
        return Model.None;
      // Legacy format (from old load() functions)
      case 'Marsh':
        return Model.Marsh;
      case 'Schnider':
        return Model.Schnider;
      case 'Eleveld':
        return Model.Eleveld;
      case 'Paedfusor':
        return Model.Paedfusor;
      case 'Kataria':
        return Model.Kataria;
      default:
        return Model.None;
    }
  }

  /// Parse Sex enum from string
  /// Handles both new format ('Sex.Female') and legacy format ('Female')
  Sex? _parseSexFromString(String? sexString) {
    if (sexString == null) return null;
    switch (sexString) {
      // New format (from .toString())
      case 'Sex.Female':
        return Sex.Female;
      case 'Sex.Male':
        return Sex.Male;
      // Legacy format (from old load() functions)
      case 'Female':
        return Sex.Female;
      case 'Male':
        return Sex.Male;
      default:
        return Sex.Female; // Default to Female like original code
    }
  }

  /// Parse InfusionUnit enum from string
  /// Handles both new format ('InfusionUnit.mg_kg_hr') and legacy format ('mg/kg/h')
  InfusionUnit? _parseInfusionUnitFromString(String? unitString) {
    if (unitString == null) return null;
    switch (unitString) {
      // New format (from .toString())
      case 'InfusionUnit.mg_kg_hr':
        return InfusionUnit.mg_kg_hr;
      case 'InfusionUnit.mcg_kg_min':
        return InfusionUnit.mcg_kg_min;
      case 'InfusionUnit.mL_hr':
        return InfusionUnit.mL_hr;
      // Legacy format (from old load() functions)
      case 'mg/kg/h':
        return InfusionUnit.mg_kg_hr;
      case 'mcg/kg/min':
        return InfusionUnit.mcg_kg_min;
      case 'mL/hr':
        return InfusionUnit.mL_hr;
      default:
        return InfusionUnit.mg_kg_hr;
    }
  }

  /// Parse ThemeMode enum from string
  ThemeMode? _parseThemeModeFromString(String? themeModeString) {
    if (themeModeString == null) return null;
    switch (themeModeString) {
      case 'ThemeMode.light':
        return ThemeMode.light;
      case 'ThemeMode.dark':
        return ThemeMode.dark;
      case 'ThemeMode.system':
        return ThemeMode.system;
      default:
        return ThemeMode.system;
    }
  }
}
