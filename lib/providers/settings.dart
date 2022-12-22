import 'package:flutter/foundation.dart';
import 'package:propofol_dreams_app/constants.dart';


class Settings with ChangeNotifier {
  int _propofolFormulation = 10;

  int get propofolFormulation {
    return _propofolFormulation;
  }

  void set propofolFormulation(int i) {
    _propofolFormulation = i;
    notifyListeners();
  }

  Model _adultModel = Model.Marsh;

  Model get adultModel{
    return _adultModel;
  }

  void set adultModel (Model m){
    _adultModel = m;
    notifyListeners();
  }

  Model _pediatricModel= Model.Paedfusor;

  Model get pediatricModel{
    return _pediatricModel;
  }

  void set pediatricModel (Model m){
    _pediatricModel = m;
    notifyListeners();
  }







}
