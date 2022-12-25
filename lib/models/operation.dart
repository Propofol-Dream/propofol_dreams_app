class Operation{
  double depth;
  int duration;

  Operation({required this.depth, required this.duration});

  String toString(){
    return '{depth: $depth, duration: $duration}';
  }


}