import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:propofol_dreams_app/models/InfusionUnit.dart';
import 'package:propofol_dreams_app/models/model.dart';
import 'package:propofol_dreams_app/models/sex.dart';
import 'package:propofol_dreams_app/models/drug.dart';
import 'package:propofol_dreams_app/models/target_unit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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

  // REMOVED: _density (legacy)
  
  // Individual drug concentrations with direct SharedPreferences storage
  double _propofolConcentration = 10.0;
  double _remifentanilConcentration = 50.0;
  double _dexmedetomidineConcentration = 4.0;
  double _remimazolamConcentration = 1.0;

  // Individual drug concentration getters
  double get propofol_concentration => _propofolConcentration;
  double get remifentanil_concentration => _remifentanilConcentration;
  double get dexmedetomidine_concentration => _dexmedetomidineConcentration;
  double get remimazolam_concentration => _remimazolamConcentration;

  // Individual drug concentration setters
  set propofol_concentration(double value) {
    _propofolConcentration = value;
    setDouble('propofol_concentration', value);
    notifyListeners();
  }

  set remifentanil_concentration(double value) {
    _remifentanilConcentration = value;
    setDouble('remifentanil_concentration', value);
    notifyListeners();
  }

  set dexmedetomidine_concentration(double value) {
    _dexmedetomidineConcentration = value;
    setDouble('dexmedetomidine_concentration', value);
    notifyListeners();
  }

  set remimazolam_concentration(double value) {
    _remimazolamConcentration = value;
    setDouble('remimazolam_concentration', value);
    notifyListeners();
  }

  // LEGACY BRIDGE: Keep 'density' name for backward compatibility
  int get density {
    return _propofolConcentration.round();
  }

  set density(int value) {
    propofol_concentration = value.toDouble();
  }

  // Drug concentration methods using individual storage
  double getDrugConcentration(Drug drug) {
    switch (drug.displayName) {
      case 'Propofol':
        return propofol_concentration;
      case 'Remifentanil':
        return remifentanil_concentration;
      case 'Dexmedetomidine':
        return dexmedetomidine_concentration;
      case 'Remimazolam':
        return remimazolam_concentration;
      default:
        return drug.concentration; // Fallback to enum default
    }
  }

  void setDrugConcentration(Drug drug, double concentration) {
    // Set the appropriate individual concentration
    switch (drug.displayName) {
      case 'Propofol':
        propofol_concentration = concentration;
        break;
      case 'Remifentanil':
        remifentanil_concentration = concentration;
        break;
      case 'Dexmedetomidine':
        dexmedetomidine_concentration = concentration;
        break;
      case 'Remimazolam':
        remimazolam_concentration = concentration;
        break;
    }
    
    // Check if this drug change affects the current TCI drug
    if (_tciDrug.displayName == drug.displayName) {
      _tciDrug = drug;
      setString('tciDrug', drug.name);
    }
  }

  // Get available concentration options for a drug type
  List<Drug> getAvailableDrugVariants(String drugType) {
    switch (drugType) {
      case 'Propofol':
        return [Drug.propofol10mg, Drug.propofol20mg];
      case 'Remifentanil':
        return [Drug.remifentanil20mcg, Drug.remifentanil40mcg, Drug.remifentanil50mcg];
      case 'Dexmedetomidine':
        return [Drug.dexmedetomidine];
      case 'Remimazolam':
        return [Drug.remimazolam1mg, Drug.remimazolam2mg];
      default:
        return [];
    }
  }
  
  // Get the currently active drug variant for a drug type
  Drug getCurrentDrugVariant(String drugType) {
    final variants = getAvailableDrugVariants(drugType);
    
    // Find which variant matches the current concentration
    double currentConcentration;
    switch (drugType) {
      case 'Propofol':
        currentConcentration = propofol_concentration;
        break;
      case 'Remifentanil':
        currentConcentration = remifentanil_concentration;
        break;
      case 'Dexmedetomidine':
        currentConcentration = dexmedetomidine_concentration;
        break;
      case 'Remimazolam':
        currentConcentration = remimazolam_concentration;
        break;
      default:
        return variants.isNotEmpty ? variants.first : Drug.propofol10mg;
    }
    
    // Find variant that matches the current concentration
    for (final variant in variants) {
      if (variant.concentration == currentConcentration) {
        return variant;
      }
    }
    
    // Return the first variant as default
    return variants.isNotEmpty ? variants.first : Drug.propofol10mg;
  }

  // REMOVED: selectedDrug system for now - will add back when implementing drug selection

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


  Model _adultModel = Model.Eleveld;
  Sex? _adultSex;
  int? _adultAge;
  int? _adultHeight;
  int? _adultWeight;
  double? _adultTarget;
  int? _adultDuration;

  // Drug-specific target values
  double? _propofolTarget;
  double? _remifentanilTarget;
  double? _dexmedetomidineTarget; 
  double? _remimazolamTarget;

  // TCI screen model (separate from volume screen)
  Model _tciModel = Model.Eleveld;
  Drug _tciDrug = Drug.propofol10mg; // Direct TCI drug storage
  
  // TCI screen specific parameters (separate from volume screen)
  Sex? _tciSex;
  int? _tciAge;
  int? _tciHeight;
  int? _tciWeight;
  
  // TCI screen specific drug targets (separate from volume screen)
  double? _tciPropofolTarget;
  double? _tciRemifentanilTarget;
  double? _tciDexmedetomidineTarget;
  double? _tciRemimazolamTarget;

  Model get adultModel {
    return _adultModel;
  }

  set adultModel(Model m) {
    _adultModel = m;
    setString('adultModel', m.name);
    notifyListeners();
  }

  Model get tciModel {
    return _tciModel;
  }

  set tciModel(Model m) {
    _tciModel = m;
    setString('tciModel', m.name);
    notifyListeners();
  }

  Drug get tciDrug {
    return _tciDrug;
  }

  set tciDrug(Drug d) {
    _tciDrug = d;
    
    // Save directly to SharedPreferences
    setString('tciDrug', d.name);
    
    // Also ensure the drug concentration is set in the map
    setDrugConcentration(d, d.concentration);
    notifyListeners();
  }

  // TCI screen specific parameter getters/setters
  Sex? get tciSex {
    return _tciSex;
  }

  set tciSex(Sex? s) {
    _tciSex = s;
    setString('tciSex', s.toString());
    notifyListeners();
  }

  int? get tciAge {
    return _tciAge;
  }

  set tciAge(int? i) {
    _tciAge = i;
    setInt('tciAge', i);
    notifyListeners();
  }

  int? get tciHeight {
    return _tciHeight;
  }

  set tciHeight(int? i) {
    _tciHeight = i;
    setInt('tciHeight', i);
    notifyListeners();
  }

  int? get tciWeight {
    return _tciWeight;
  }

  set tciWeight(int? i) {
    _tciWeight = i;
    setInt('tciWeight', i);
    // Also update duration screen weight when TCI weight changes
    _weight = i;
    setInt('weight', i);
    notifyListeners();
  }

  // TCI screen specific target getters/setters
  double? get tciPropofolTarget => _tciPropofolTarget;
  set tciPropofolTarget(double? d) {
    _tciPropofolTarget = d;
    setDouble('tciPropofolTarget', d);
    notifyListeners();
  }

  double? get tciRemifentanilTarget => _tciRemifentanilTarget;
  set tciRemifentanilTarget(double? d) {
    _tciRemifentanilTarget = d;
    setDouble('tciRemifentanilTarget', d);
    notifyListeners();
  }

  double? get tciDexmedetomidineTarget => _tciDexmedetomidineTarget;
  set tciDexmedetomidineTarget(double? d) {
    _tciDexmedetomidineTarget = d;
    setDouble('tciDexmedetomidineTarget', d);
    notifyListeners();
  }

  double? get tciRemimazolamTarget => _tciRemimazolamTarget;
  set tciRemimazolamTarget(double? d) {
    _tciRemimazolamTarget = d;
    setDouble('tciRemimazolamTarget', d);
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
    _adultWeight = i;
    setInt('adultWeight', i);
    notifyListeners();
  }

  double? get adultTarget {
    return _adultTarget;
  }

  set adultTarget(double? d) {
    _adultTarget = d;
    setDouble('adultTarget', d);
    notifyListeners();
  }

  double? get propofolTarget => _propofolTarget;
  set propofolTarget(double? d) {
    _propofolTarget = d;
    setDouble('propofolTarget', d);
    notifyListeners();
  }

  double? get remifentanilTarget => _remifentanilTarget;
  set remifentanilTarget(double? d) {
    _remifentanilTarget = d;
    setDouble('remifentanilTarget', d);
    notifyListeners();
  }

  double? get dexmedetomidineTarget => _dexmedetomidineTarget;
  set dexmedetomidineTarget(double? d) {
    _dexmedetomidineTarget = d;
    setDouble('dexmedetomidineTarget', d);
    notifyListeners();
  }

  double? get remimazolamTarget => _remimazolamTarget;
  set remimazolamTarget(double? d) {
    _remimazolamTarget = d;
    setDouble('remimazolamTarget', d);
    notifyListeners();
  }

  // Helper method to get drug-specific target value
  double? getDrugTarget(Drug? drug) {
    if (drug == null) return null;
    
    if (drug.isPropofol) {
      return _propofolTarget;
    } else if (drug.isRemifentanil) {
      return _remifentanilTarget;
    } else if (drug.isDexmedetomidine) {
      return _dexmedetomidineTarget;
    } else if (drug.isRemimazolam) {
      return _remimazolamTarget;
    }
    
    return null;
  }

  // Helper method to set drug-specific target value
  void setDrugTarget(Drug? drug, double? value) {
    if (drug == null) return;
    
    if (drug.isPropofol) {
      propofolTarget = value;
    } else if (drug.isRemifentanil) {
      remifentanilTarget = value;
    } else if (drug.isDexmedetomidine) {
      dexmedetomidineTarget = value;
    } else if (drug.isRemimazolam) {
      remimazolamTarget = value;
    }
  }

  // TCI screen specific drug target methods (separate from volume screen)
  double? getTciDrugTarget(Drug? drug) {
    if (drug == null) return null;
    
    if (drug.isPropofol) {
      return _tciPropofolTarget;
    } else if (drug.isRemifentanil) {
      return _tciRemifentanilTarget;
    } else if (drug.isDexmedetomidine) {
      return _tciDexmedetomidineTarget;
    } else if (drug.isRemimazolam) {
      return _tciRemimazolamTarget;
    }
    
    return null;
  }

  void setTciDrugTarget(Drug? drug, double? value) {
    if (drug == null) return;
    
    if (drug.isPropofol) {
      tciPropofolTarget = value;
    } else if (drug.isRemifentanil) {
      tciRemifentanilTarget = value;
    } else if (drug.isDexmedetomidine) {
      tciDexmedetomidineTarget = value;
    } else if (drug.isRemimazolam) {
      tciRemimazolamTarget = value;
    }
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
    setString('pediatricModel', m.name);
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
    // Also update duration screen weight when pediatric weight changes
    _weight = i;
    setInt('weight', i);
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
    setString('EMWakeUpModel', m.name);
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
      // Individual drug concentrations are saved by their respective setters
      _prefs!.setBool('isVolumeTableExpanded', _isVolumeTableExpanded),
      _prefs!.setString('adultModel', _adultModel.name),
      _prefs!.setString('tciModel', _tciModel.name),
      _prefs!.setString('tciDrug', _tciDrug.name),
      if (_tciSex != null) _prefs!.setString('tciSex', _tciSex.toString()),
      if (_tciAge != null) _prefs!.setInt('tciAge', _tciAge!),
      if (_tciHeight != null) _prefs!.setInt('tciHeight', _tciHeight!),
      if (_tciWeight != null) _prefs!.setInt('tciWeight', _tciWeight!),
      if (_tciPropofolTarget != null) _prefs!.setDouble('tciPropofolTarget', _tciPropofolTarget!),
      if (_tciRemifentanilTarget != null) _prefs!.setDouble('tciRemifentanilTarget', _tciRemifentanilTarget!),
      if (_tciDexmedetomidineTarget != null) _prefs!.setDouble('tciDexmedetomidineTarget', _tciDexmedetomidineTarget!),
      if (_tciRemimazolamTarget != null) _prefs!.setDouble('tciRemimazolamTarget', _tciRemimazolamTarget!),
      _prefs!.setString('adultSex', _adultSex.toString()),
      if (_adultAge != null) _prefs!.setInt('adultAge', _adultAge!),
      if (_adultHeight != null) _prefs!.setInt('adultHeight', _adultHeight!),
      if (_adultWeight != null) _prefs!.setInt('adultWeight', _adultWeight!),
      if (_adultTarget != null) _prefs!.setDouble('adultTarget', _adultTarget!),
      if (_adultDuration != null) _prefs!.setInt('adultDuration', _adultDuration!),
      if (_propofolTarget != null) _prefs!.setDouble('propofolTarget', _propofolTarget!),
      if (_remifentanilTarget != null) _prefs!.setDouble('remifentanilTarget', _remifentanilTarget!),
      if (_dexmedetomidineTarget != null) _prefs!.setDouble('dexmedetomidineTarget', _dexmedetomidineTarget!),
      if (_remimazolamTarget != null) _prefs!.setDouble('remimazolamTarget', _remimazolamTarget!),
      _prefs!.setString('pediatricModel', _pediatricModel.name),
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
      _prefs!.setString('EMWakeUpModel', _EMWakeUpModel.name),
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
    _isVolumeTableExpanded = pref.getBool('isVolumeTableExpanded') ?? false;

    // Load individual drug concentrations with migration support
    
    // Propofol concentration
    _propofolConcentration = pref.getDouble('propofol_concentration') ??
      // Migration from legacy density or old JSON format
      (pref.getInt('density')?.toDouble() ?? 10.0);
    
    // Remifentanil concentration  
    _remifentanilConcentration = pref.getDouble('remifentanil_concentration') ?? 50.0;
    
    // Dexmedetomidine concentration
    _dexmedetomidineConcentration = pref.getDouble('dexmedetomidine_concentration') ?? 4.0;
    
    // Remimazolam concentration
    _remimazolamConcentration = pref.getDouble('remimazolam_concentration') ?? 1.0;
    
    // Migration: If we loaded from legacy, save to new individual keys
    if (pref.getDouble('propofol_concentration') == null && pref.getInt('density') != null) {
      propofol_concentration = _propofolConcentration; // This will save to new key
    }
    
    // Model-specific targets removed for now

    // Adult model settings
    final adultModelString = pref.getString('adultModel');
    _adultModel = _parseModelFromString(adultModelString) ?? Model.Eleveld;
    
    // TCI model settings
    final tciModelString = pref.getString('tciModel');
    _tciModel = _parseModelFromString(tciModelString) ?? Model.Eleveld;
    
    // Load TCI drug from SharedPreferences
    final tciDrugString = pref.getString('tciDrug');
    _tciDrug = _parseDrugFromString(tciDrugString) ?? Drug.propofol10mg;
    
    // Ensure individual concentrations are synchronized with loaded TCI drug
    if (_tciDrug != Drug.propofol10mg) {
      // Update the appropriate concentration to match the TCI drug
      setDrugConcentration(_tciDrug, _tciDrug.concentration);
    }
    
    // Load TCI specific parameters
    final tciSexString = pref.getString('tciSex');
    _tciSex = _parseSexFromString(tciSexString) ?? Sex.Female;
    _tciAge = pref.getInt('tciAge') ?? 40;
    _tciHeight = pref.getInt('tciHeight') ?? 170;
    _tciWeight = pref.getInt('tciWeight') ?? 70;
    
    // Load TCI specific drug targets
    _tciPropofolTarget = pref.getDouble('tciPropofolTarget') ?? 3.0;
    _tciRemifentanilTarget = pref.getDouble('tciRemifentanilTarget') ?? 3.0;
    _tciDexmedetomidineTarget = pref.getDouble('tciDexmedetomidineTarget') ?? 1.0;
    _tciRemimazolamTarget = pref.getDouble('tciRemimazolamTarget') ?? 1.0;
    
    final adultSexString = pref.getString('adultSex');
    _adultSex = _parseSexFromString(adultSexString) ?? Sex.Female;
    
    _adultAge = pref.getInt('adultAge') ?? 40;
    _adultHeight = pref.getInt('adultHeight') ?? 170;
    _adultWeight = pref.getInt('adultWeight') ?? 70;
    _adultTarget = pref.getDouble('adultTarget') ?? 3.0;
    _adultDuration = pref.getInt('adultDuration') ?? 60;

    // Load drug-specific targets
    _propofolTarget = pref.getDouble('propofolTarget') ?? 3.0;
    _remifentanilTarget = pref.getDouble('remifentanilTarget') ?? 3.0;
    _dexmedetomidineTarget = pref.getDouble('dexmedetomidineTarget') ?? 1.0;
    _remimazolamTarget = pref.getDouble('remimazolamTarget') ?? 1.0;

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
    _weight = pref.getInt('weight') ?? 70;
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
      case 'Model.MarshPropofol':
        return Model.Marsh;
      case 'Model.SchniderPropofol':
        return Model.Schnider;
      case 'Model.EleveldPropofol':
        return Model.Eleveld;
      case 'Model.PaedfusorPropofol':
        return Model.Paedfusor;
      case 'Model.KatariaPropofol':
        return Model.Kataria;
      // case 'Model.MintoRemifentanil':
      //   return Model.Minto;
      case 'Model.EleveldRemifentanil':
        return Model.Eleveld;
      case 'Model.HannivoortDexmedetomidine':
        return Model.Hannivoort;
      case 'Model.EleveldRemimazolam':
        return Model.Eleveld;
      case 'Model.EleMarsh':
        return Model.EleMarsh;
      case 'Model.EleMarshPropofol':
        return Model.EleMarsh;
      case 'Model.None':
        return Model.None;
      // Direct enum name format (from .name property)
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
      // case 'Minto':
      //   return Model.Minto;
      case 'Hannivoort':
        return Model.Hannivoort;
      case 'EleMarsh':
        return Model.EleMarsh;
      case 'None':
        return Model.None;
      // Legacy format (from old load() functions)
      case 'MarshPropofol':
        return Model.Marsh;
      case 'SchniderPropofol':
        return Model.Schnider;
      case 'EleveldPropofol':
        return Model.Eleveld;
      case 'PaedfusorPropofol':
        return Model.Paedfusor;
      case 'KatariaPropofol':
        return Model.Kataria;
      // case 'MintoRemifentanil':
      //   return Model.Minto;
      case 'EleveldRemifentanil':
        return Model.Eleveld;
      case 'HannivoortDexmedetomidine':
        return Model.Hannivoort;
      case 'EleveldRemimazolam':
        return Model.Eleveld;
      case 'EleMarsh':
        return Model.EleMarsh;
      case 'EleMarshPropofol':
        return Model.EleMarsh;
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

  /// Parse Drug enum from string - updated for new drug constants
  Drug? _parseDrugFromString(String? drugString) {
    if (drugString == null) return null;
    switch (drugString) {
      // New drug constants - full format
      case 'Drug.propofol10mg':
      case 'propofol10mg': // Enum name format
        return Drug.propofol10mg;
      case 'Drug.propofol20mg':
      case 'propofol20mg': // Enum name format
        return Drug.propofol20mg;
      case 'Drug.remifentanil20mcg':
      case 'remifentanil20mcg': // Enum name format
        return Drug.remifentanil20mcg;
      case 'Drug.remifentanil40mcg':
      case 'remifentanil40mcg': // Enum name format
        return Drug.remifentanil40mcg;
      case 'Drug.remifentanil50mcg':
      case 'remifentanil50mcg': // Enum name format
        return Drug.remifentanil50mcg;
      case 'Drug.dexmedetomidine':
      case 'dexmedetomidine': // Enum name format
        return Drug.dexmedetomidine;
      case 'Drug.remimazolam':
      case 'remimazolam': // Enum name format
        return Drug.remimazolam1mg;
      // Legacy compatibility
      case 'Drug.propofol':
      case 'Propofol':
        return Drug.propofol10mg; // Default to 10mg
      case 'Drug.remifentanilMinto':
      case 'Drug.remifentanilEleveld':
      case 'Remifentanil (Minto)':
      case 'Remifentanil (Eleveld)':
        return Drug.remifentanil50mcg; // Default to 50mcg
      case 'Dexmedetomidine':
        return Drug.dexmedetomidine;
      case 'Remimazolam':
        return Drug.remimazolam1mg;
      default:
        return Drug.propofol10mg; // Default to propofol 10mg for backward compatibility
    }
  }
}
