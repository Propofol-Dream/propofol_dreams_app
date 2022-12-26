import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const numOfDigits = 0;

const horizontalSidesPaddingPixel = 16.0;

const PDTableRowHeight = 36.0;

const Map<int, Color> colorPDLightGreen = {
  50: Color.fromRGBO(8, 108, 80, .1),
  100: Color.fromRGBO(8, 108, 80, .2),
  200: Color.fromRGBO(8, 108, 80, .3),
  300: Color.fromRGBO(8, 108, 80, .4),
  400: Color.fromRGBO(8, 108, 80, .5),
  500: Color.fromRGBO(8, 108, 80, .6),
  600: Color.fromRGBO(8, 108, 80, .7),
  700: Color.fromRGBO(8, 108, 80, .8),
  800: Color.fromRGBO(8, 108, 80, .9),
  900: Color.fromRGBO(8, 108, 80, 1),
};

const MaterialColor PDLightGreen = MaterialColor(0xFF006C50, colorPDLightGreen);

const MaterialColor PDDarkGreen = MaterialColor(0xFF66DBB2, colorPDLightGreen);


const Map<int, Color> colorPDLightNavy = {
  50: Color.fromRGBO(63, 99, 117, .1),
  100: Color.fromRGBO(63, 99, 117, .2),
  200: Color.fromRGBO(63, 99, 117, .3),
  300: Color.fromRGBO(63, 99, 117, .4),
  400: Color.fromRGBO(63, 99, 117, .5),
  500: Color.fromRGBO(63, 99, 117, .6),
  600: Color.fromRGBO(63, 99, 117, .7),
  700: Color.fromRGBO(63, 99, 117, .8),
  800: Color.fromRGBO(63, 99, 117, .9),
  900: Color.fromRGBO(63, 99, 117, 1),
};


const MaterialColor PDLightNavy = MaterialColor(0xFF3F6375, colorPDLightNavy);

const Map<int, Color> colorPDRed = {
  50: Color.fromRGBO(186, 27, 27, .1),
  100: Color.fromRGBO(186, 27, 27, .2),
  200: Color.fromRGBO(186, 27, 27, .3),
  300: Color.fromRGBO(186, 27, 27, .4),
  400: Color.fromRGBO(186, 27, 27, .5),
  500: Color.fromRGBO(186, 27, 27, .6),
  600: Color.fromRGBO(186, 27, 27, .7),
  700: Color.fromRGBO(186, 27, 27, .8),
  800: Color.fromRGBO(186, 27, 27, .9),
  900: Color.fromRGBO(186, 27, 27, 1),
};

const MaterialColor PDRed = MaterialColor(0xFFBA1B1B, colorPDRed);


// var buttonHapticFeedback =  HapticFeedback.mediumImpact();

// const int kDilution = 10; // mg/ml
// const int kMaxPumpRate = 750; // ml/hr, as requested on 13 Dec 2022
// // const int kMaxPumpRate = 1200; // ml/hr, this is from Engbert's
// int kMaxInfusion = kDilution * kMaxPumpRate;

const double kMinDepth = 0.5;
const double kMaxDepth = 10;

const int kMinDuration = 5; //5 mins
const int kMaxDuration = 600; //600mins


