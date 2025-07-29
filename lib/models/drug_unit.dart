enum DrugUnit {
  mgPerMl('mg/mL'),
  mcgPerMl('μg/mL');
  
  const DrugUnit(this.displayName);
  final String displayName;
  
  @override
  String toString() => displayName;
}