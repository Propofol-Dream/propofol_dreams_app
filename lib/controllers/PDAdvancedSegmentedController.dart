import 'package:flutter/material.dart';

class PDAdvancedSegmentedController extends ChangeNotifier {
  PDAdvancedSegmentedController();

  dynamic _selection;

  dynamic get selection {
    return _selection == null
        ? {'error': '_selectedOption == null'}
        : _selection!;
  }

  set selection(s) {
    _selection = s;
    notifyListeners();
  }
}