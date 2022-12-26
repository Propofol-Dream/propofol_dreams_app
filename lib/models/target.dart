enum Target {
  Plasma(),
  Effect_Site();

  @override
  String toString() {
    return name.replaceAll('_', ' ');
  }

  const Target();
}