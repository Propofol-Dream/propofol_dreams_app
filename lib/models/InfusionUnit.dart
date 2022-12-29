enum InfusionUnit {
  mg_kg_hr(),
  mcg_kg_min(),
  mL_hr();

  @override
  String toString() {
    return name.replaceAll('_', '/');
  }

  const InfusionUnit();
}
