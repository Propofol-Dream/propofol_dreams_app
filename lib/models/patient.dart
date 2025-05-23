import 'package:flutter/material.dart';
import 'dart:math';
import 'sex.dart';

class Patient with ChangeNotifier{
  int weight;
  int height;
  int age;
  Sex sex;

  Patient(
      {required this.weight, required this.height, required this.age, required this.sex});

  Patient copy() {
    return Patient(weight: weight, height: height, age: age, sex: sex);
  }

  @override
  String toString(){
    return '{gender: $sex, age: $age, height: $height, weight: $weight, bmi: $bmi}';
  }

  double get lbm {
    if (sex == Sex.Female) {
      return 1.07 * weight - 148 * pow((weight / height), 2);
    } else if (sex == Sex.Male) {
      return 1.1 * weight - 128 * pow((weight / height), 2);
    }
    return 0.0;
  }

  double get bmi {
    return (weight / pow((height / 100), 2));
  }

  //fat-free mass
  double get ffm {
    double b = bmi;
    if (sex == Sex.Male) {
      return (0.88 + (1 - 0.88) / (1 + pow((age / 13.4), -12.7))) *
          ((9270 * weight) / (6680 + 216 * b));
    } else {
      return (1.11 + (1 - 1.11) / (1 + pow((age / 7.1), -1.1))) *
          ((9270 * weight) / (8780 + 244 * b));
    }
  }

  //arbitrarily set pma 40 weeks +age
  double get pma {
    return age * 52.143 + 40;
  }

}