enum Gender {
  Female(),
  Male();

  @override
  String toString() {
    return name;
  }

  final bool enabled;

  const Gender({this.enabled = true});
}