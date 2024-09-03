enum InfusionUnit {
  mg_kg_hr(),
  mcg_kg_min(),
  mL_hr();

  @override
  String toString() {
    var result = name.replaceAll('_', '/');
    if (result == 'mcg/kg/min'){
      result = 'μg/kg/min';
    }
    return result;
  }

  const InfusionUnit();
}
