import 'gender.dart';
import 'target.dart';
import 'dart:math';

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
      target: Target.Effect_Site),
  Eleveld(
      minAge: 1,
      maxAge: 105,
      minHeight: 50,
      maxHeight: 210,
      minWeight: 1,
      maxWeight: 250,
      target: Target.Effect_Site),
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
      target: Target.Effect_Site),
  None(
      minAge: 0,
      maxAge: 999,
      minHeight: 0,
      maxHeight: 999,
      minWeight: 0,
      maxWeight: 999,
      target: Target.Effect_Site);

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

  bool isEnable({required int age, required int height, required int weight}) {
    return this.target == Target.Plasma
        ? (withinAge(age) && withinWeight(weight))
        : (withinAge(age) && withinHeight(height) && withinWeight(weight));
  }

  bool isRunnable(
      {required int? age,
        required int? height,
        required int? weight,
        required double? depth,
        required int? duration}) {
    return this.target == Target.Plasma
        ? (age != null) &&
        (weight != null) &&
        (depth != null) &&
        (duration != null)
        : (age != null) &&
        (weight != null) &&
        (depth != null) &&
        (duration != null) &&
        (height != null);
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
    if (this == Model.Marsh ||
        this == Model.Paedfusor ||
        this == Model.Kataria) {
      // text = 'Plasma';
      return {'assertion': isAssertive, 'text': text};
    } else if (this == Model.Schnider) {
      double tmpBMI = bmi(weight, height);
      double minBMI = 14;
      double maxBMI = gender == Gender.Male ? 42 : 39;
      isAssertive = tmpBMI >= minBMI && tmpBMI <= maxBMI;
      text = isAssertive ? '' : '[BMI] min: ${minBMI} and max: ${maxBMI}';
      return {'assertion': isAssertive, 'text': text};
    } else if (this == Model.Eleveld) {
      // text = 'Effect Site';
      return {'assertion': isAssertive, 'text': text};
    }
    return {'assertion': isAssertive, 'text': text};
  }

  final int minAge;
  final int maxAge;
  final int minHeight;
  final int maxHeight;
  final int minWeight;
  final int maxWeight;
  final Target target;

  const Model({
    required this.minAge,
    required this.maxAge,
    required this.minHeight,
    required this.maxHeight,
    required this.minWeight,
    required this.maxWeight,
    required this.target,
  });
}