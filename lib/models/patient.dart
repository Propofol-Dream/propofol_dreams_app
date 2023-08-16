import 'package:flutter/material.dart';
import 'dart:math';
import 'gender.dart';

class Patient with ChangeNotifier{
  int weight;
  int height;
  int age;
  Gender gender;

  Patient(
      {required this.weight, required this.height, required this.age, required this.gender});

  Patient copy() {
    return Patient(weight: weight, height: height, age: age, gender: gender);
  }

  @override
  String toString(){
    return '{gender: $gender, age: $age, height: $height, weight: $weight}';
  }

  double get lbm {
    if (gender == Gender.Female) {
      return 1.07 * weight - 148 * pow((weight / height), 2);
    } else if (gender == Gender.Male) {
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
    if (gender == Gender.Male) {
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

  double get weightGuess {
    if (gender == Gender.Female) {
      return (15.24 + 1.033 * weight - 0.001552 * weight * weight + 2.119e-6 * weight * weight * weight +
          8.909e-5 * height * height - 4.423e-4 * weight * bmi - 0.1928 * age + 9.729e-4 * age * age -
          0.003927 * age * weight + 1.779e-6 * age * weight * weight + 0.001165 * age * bmi - 0.08306 * bmi);
    } else {
      return(15.03 + 0.9526 * weight - 0.001513 * weight * weight + 1.991e-6 * weight * weight * weight +
          1.144e-4 * height * height - 4.308e-4 * weight * bmi - 0.2029 * age + 1.047e-3 * age * age -
          0.003866 * age * weight + 3.305e-6 * age * weight * weight + 0.001263 * age * bmi - 0.09866 * bmi);
    }
  }

}