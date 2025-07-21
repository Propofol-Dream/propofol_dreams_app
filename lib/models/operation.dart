class Operation {
  double target;
  Duration duration;

  Operation({required this.target, required this.duration});

  Operation copy() {
    return Operation(target: target, duration: duration);
  }

  @override
  String toString() {
    return 'Operation(target: $target, duration: $duration)';
  }
}