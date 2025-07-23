enum DrugUnit {
  mgPerMl('mg/mL'),
  mcgPerMl('mcg/mL');
  
  const DrugUnit(this.displayName);
  final String displayName;
  
  /// Conversion factor to standardized mg/mL for internal calculations
  double get toMgPerMlFactor {
    switch (this) {
      case DrugUnit.mgPerMl:
        return 1.0;
      case DrugUnit.mcgPerMl:
        return 0.001; // 1 mcg = 0.001 mg
    }
  }
  
  @override
  String toString() => displayName;
}