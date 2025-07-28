enum TargetUnit {
  mcgPerMl('μg/mL'),
  ngPerMl('ng/mL');
  
  const TargetUnit(this.displayName);
  final String displayName;
  
  /// Conversion factor to standardized mcg/mL for internal calculations
  double get toMcgPerMlFactor {
    switch (this) {
      case TargetUnit.mcgPerMl:
        return 1.0;
      case TargetUnit.ngPerMl:
        return 1.0;
    }
  }
  
  @override
  String toString() => displayName;
}