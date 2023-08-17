import 'package:flutter/material.dart';

class PDSwitchController extends ChangeNotifier {
  PDSwitchController();

  bool _val = true;

  bool get val {
    return _val;
  }

  void set val(bool v) {
    _val = v;
    notifyListeners();
  }
}