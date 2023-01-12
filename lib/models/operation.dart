class Operation{
  double target;
  Duration duration;

  Operation({required this.target, required this.duration});

  @override
  String toString(){
    return '{target: $target, duration: ${duration.toString()}}';
  }

}