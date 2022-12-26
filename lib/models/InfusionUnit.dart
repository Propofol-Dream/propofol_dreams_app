enum InfusionUnit {
  mg_kg_h(),
  mcg_kg_min(),
  mL_hr();

  @override
  String toString() {
    return name.replaceAll('_', '/');
  }

  const InfusionUnit();
}
