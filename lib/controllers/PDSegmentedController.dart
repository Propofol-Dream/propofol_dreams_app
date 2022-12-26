import 'package:flutter/material.dart';

class PDSegmentedController extends ChangeNotifier {
  PDSegmentedController();

  int _val = 0;

  int get val {
    return _val;
  }

  void set val(int v) {
    _val = v;
    notifyListeners();
  }
}