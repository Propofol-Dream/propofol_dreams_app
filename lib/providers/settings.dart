import 'package:flutter/foundation.dart';
import 'package:propofol_dreams_app/models/model.dart';
import 'package:propofol_dreams_app/models/patient.dart';
import 'package:propofol_dreams_app/models/operation.dart';
import 'package:propofol_dreams_app/models/pump.dart';
import 'package:propofol_dreams_app/models/gender.dart';

class Settings with ChangeNotifier {
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

  Gender? get adultGender{
    return _adultGender;
  }

  void set adultGender (Gender? g){
    _adultGender = g;
    notifyListeners();
  }

  int? get adultAge{
    return _adultAge;
  }

  void set adultAge(int? i){
    _adultAge = i;
    notifyListeners();
  }

  int? get adultHeight{
    return _adultHeight;
  }

  void set adultHeight(int? i){
    _adultHeight = i;
    notifyListeners();
  }

  int? get adultWeight{
    return _adultWeight;
  }

  void set adultWeight(int? i){
    _adultWeight = i;
    notifyListeners();
  }

  double? get adultDepth{
    return _adultDepth;
  }

  void set adultDepth(double? d){
    _adultDepth = d;
    notifyListeners();
  }

  int? get adultDuration{
    return _adultDuration;
  }

  void set adultDuration(int? i){
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

  Gender? get pediatricGender{
    return _pediatricGender;
  }

  void set pediatricGender (Gender? g){
    _pediatricGender = g;
    notifyListeners();
  }

  int? get pediatricAge{
    return _pediatricAge;
  }

  void set pediatricAge(int? i){
    _pediatricAge = i;
    notifyListeners();
  }

  int? get pediatricHeight{
    return _pediatricHeight;
  }

  void set pediatricHeight(int? i){
    _pediatricHeight = i;
    notifyListeners();
  }

  int? get pediatricWeight{
    return _pediatricWeight;
  }

  void set pediatricWeight(int? i){
    _pediatricWeight = i;
    notifyListeners();
  }

  double? get pediatricDepth{
    return _pediatricDepth;
  }

  void set pediatricDepth(double? d){
    _pediatricDepth = d;
    notifyListeners();
  }

  int? get pediatricDuration{
    return _pediatricDuration;
  }

  void set pediatricDuration(int? i){
    _pediatricDuration = i;
    notifyListeners();
  }

  bool _inAdultView = true;

  bool get inAdultView{
    return _inAdultView;
  }

  void set inAdultView(bool b){
    _inAdultView = b;
    notifyListeners();
  }



  // Patient _adult =
  //     Patient(weight: 70, height: 170, age: 40, gender: Gender.Female);
  // Patient _child =
  //     Patient(weight: 26, height: 130, age: 8, gender: Gender.Female);
  // Operation _adultOperation = Operation(depth: 3.0, duration: 60);
  // Operation _childOperation = Operation(depth: 3.0, duration: 60);

  // Pump _pump = Pump(time_step: 1, dilution: 10, max_pump_rate: 750);
  //
  // Pump get pump {
  //   return _pump;
  // }
  //
  // void set pump(Pump p) {
  //   _pump = p;
  //   notifyListeners();
  // }

// Patient get adult {
//   return _adult;
// }
//
// void set adult(Patient p) {
//   _adult = p;
//   notifyListeners();
// }
//
// Patient get child {
//   return _child;
// }
//
// void set child(Patient p) {
//   _child = p;
//   notifyListeners();
// }
//
// Operation get adultOperation {
//   return _adultOperation;
// }
//
// void set adultOperation(Operation p) {
//   _adultOperation = p;
//   notifyListeners();
// }
//
// Operation get childOperation {
//   return _childOperation;
// }
//
// void set childOperation(Operation p) {
//   _childOperation = p;
//   notifyListeners();
// }

}
