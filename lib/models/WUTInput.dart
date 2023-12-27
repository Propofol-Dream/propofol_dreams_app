import 'dart:collection';

class WUTInput implements Comparable<WUTInput> {
  Duration durationInput;
  double dosageInput;
  double eBISInput;
  double? concentrationEffect;

  WUTInput(
      {required this.durationInput,
      required this.dosageInput,
      required this.eBISInput,
      this.concentrationEffect});

  @override
  int compareTo(WUTInput other) {
    // Sorting by duration
    return durationInput.compareTo(other.durationInput);
  }

  @override
  String toString() =>
      'Input(duration: $durationInput, dosage: $dosageInput, eBIS: $eBISInput${concentrationEffect != null ? ', concentrationEffect: $concentrationEffect' : ''})';

  String toCsv() {
    return '$durationInput,$dosageInput,$eBISInput${concentrationEffect != null ? ',$concentrationEffect' : ''}';
  }
}
