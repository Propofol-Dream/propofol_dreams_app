enum DrugUnit {
  mgPerMl('mg/mL'),
  mcgPerMl('mcg/mL');
  
  const DrugUnit(this.displayName);
  final String displayName;
  
  @override
  String toString() => displayName;
}