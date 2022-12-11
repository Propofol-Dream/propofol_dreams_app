import 'package:flutter/material.dart';

const horizontalSidesPaddingPixel = 16.0;

const PDTableRowHeight = 36.0;

const Map<int, Color> colorPDGreen =
{
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

const MaterialColor PDGreen = MaterialColor(0xFF006C50, colorPDGreen);



const Map<int, Color> colorPDNavy =
{
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

const MaterialColor PDNavy = MaterialColor(0xFF3F6375, colorPDNavy);

const Map<int, Color> colorPDRed =
{
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

enum Model {
  Marsh(minAge: 17, maxAge: 100),
  Schnider(minAge: 17, maxAge: 100),
  Eleveld(minAge:1, maxAge: 100, enabled: false),
  Paedfusor(minAge: 1, maxAge: 16),
  Kataria(minAge: 3, maxAge: 11),
  Zhong(minAge: 0,maxAge: 999),
  Xu(minAge: 0,maxAge: 999);

  @override
  String toString() {
    return name;
  }

  bool withinAge(int age){
    if (age > maxAge || age < minAge){
      return false;
    }
    else{
      return true;
    }
  }

  final bool enabled;
  final int minAge;
  final int maxAge;
  const Model({required this.minAge, required this.maxAge, this.enabled = true});
}

enum Gender {
  Female(),
  Male();

  @override
  String toString() {
    return name;
  }

  final bool enabled;
  const Gender({this.enabled = true});
}