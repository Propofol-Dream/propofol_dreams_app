class Pump{
  int time_step;
  int dilution;
  int max_pump_rate;

  Pump({required this.time_step, required this.dilution, required this.max_pump_rate});

  String toString(){
    return '{time step: $time_step, dilution: $dilution, max pump rate: $max_pump_rate}';
  }
}