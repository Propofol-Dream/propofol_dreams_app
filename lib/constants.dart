import 'package:flutter/material.dart';
import 'dart:math';

const numOfDigits = 1;

const horizontalSidesPaddingPixel = 16.0;

const PDTableRowHeight = 36.0;

const Map<int, Color> colorPDGreen = {
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

const Map<int, Color> colorPDNavy = {
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

enum Model {
  Marsh(
      minAge: 17,
      maxAge: 105,
      minHeight: 0,
      maxHeight: 999,
      minWeight: 0,
      maxWeight: 150,
      target: Target.Plasma),
  Schnider(
      minAge: 17,
      maxAge: 100,
      minHeight: 140,
      maxHeight: 210,
      minWeight: 0,
      maxWeight: 165,
      target: Target.EffectSite),
  Eleveld(
      minAge: 1,
      maxAge: 105,
      minHeight: 50,
      maxHeight: 210,
      minWeight: 1,
      maxWeight: 250,
      target: Target.EffectSite),
  Paedfusor(
      minAge: 1,
      maxAge: 16,
      minHeight: 0,
      maxHeight: 999,
      minWeight: 5,
      maxWeight: 61,
      target: Target.Plasma),
  Kataria(
      minAge: 3,
      maxAge: 16,
      minHeight: 0,
      maxHeight: 999,
      minWeight: 15,
      maxWeight: 61,
      target: Target.Plasma),
  Zhong(
      minAge: 0,
      maxAge: 999,
      minHeight: 0,
      maxHeight: 999,
      minWeight: 0,
      maxWeight: 999,
      target: Target.EffectSite),
  Xu(
      minAge: 0,
      maxAge: 999,
      minHeight: 0,
      maxHeight: 999,
      minWeight: 0,
      maxWeight: 999,
      target: Target.Plasma);

  @override
  String toString() {
    return name;
  }

  bool withinAge(int age) {
    if (age > maxAge || age < minAge) {
      return false;
    } else {
      return true;
    }
  }

  bool withinHeight(int height) {
    if (height > maxHeight || height < minHeight) {
      return false;
    } else {
      return true;
    }
  }

  bool withinWeight(int weight) {
    if (weight > maxWeight || weight < minWeight) {
      return false;
    } else {
      return true;
    }
  }

  bool shouldBeEnabled(
      {required int age, required int height, required int weight}) {
    return (withinAge(age) && withinHeight(height) && withinWeight(weight));
  }

  double bmi(int weight, int height) {
    return (weight / pow((height / 100), 2));
  }

  Map<String, Object> checkConstraints({
    required int weight,
    required int height,
    required int age,
    required Gender gender,
  }) {
    bool isAssertive = true;
    String text = '';
    if (this == Model.Marsh || this == Model.Paedfusor || this == Model.Kataria){
      text = 'Plasma';
      return {'assertion': isAssertive, 'text': text};
    }else if (this == Model.Schnider) {
      double tmpBMI = bmi(weight, height);
      double minBMI = 14;
      double maxBMI = gender == Gender.Male?42:39;
      isAssertive = tmpBMI >= minBMI && tmpBMI <= maxBMI;
      text = isAssertive? 'Effect Site': '[BMI] min: ${minBMI} and max: ${maxBMI}';
      return {'assertion': isAssertive, 'text': text};
    }else if (this == Model.Eleveld) {
      text = 'Effect Site';
      return {'assertion': isAssertive, 'text': text};
    }
    return {'assertion': isAssertive, 'text': text};
  }

  final bool enabled;
  final int minAge;
  final int maxAge;
  final int minHeight;
  final int maxHeight;
  final int minWeight;
  final int maxWeight;
  final Target target;

  const Model(
      {required this.minAge,
      required this.maxAge,
      required this.minHeight,
      required this.maxHeight,
      required this.minWeight,
      required this.maxWeight,
      required this.target,
      this.enabled = true});
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

enum Target {
  Plasma(),
  EffectSite();

  @override
  String toString() {
    return name;
  }

  const Target();
}

int dilution = 10; // mg/ml
int max_pump_rate = 750; // ml/hr, as requested on 13 Dec 2022
// int max_pump_rate = 1200; // ml/hr, this is from Engbert's
int max_infusion = dilution * max_pump_rate;
