class Operation{
  double depth;
  Duration duration;

  Operation({required this.depth, required this.duration});

  String toString(){
    return '{depth: $depth, duration: ${duration.toString()}}';
  }

}