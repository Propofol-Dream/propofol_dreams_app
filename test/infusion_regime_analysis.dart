import 'package:propofol_dreams_app/models/simulation.dart' as PDSim;
import 'package:propofol_dreams_app/models/patient.dart';
import 'package:propofol_dreams_app/models/pump.dart';
import 'package:propofol_dreams_app/models/model.dart';
import 'package:propofol_dreams_app/models/sex.dart';

void main() {
  // Test to understand initial high rate duration
  print('=== Infusion Regime Analysis ===\n');
  
  // Standard reference patient
  final patient = Patient(
    weight: 70,
    age: 35, 
    height: 170,
    sex: Sex.Male,
  );
  
  // Standard pump settings
  final pump = Pump(
    timeStep: Duration(seconds: 1), // 1-second resolution
    density: 10, // mg/mL
    maxPumpRate: 1200, // mL/hr
    target: 3.0, // mcg/mL
    duration: Duration(minutes: 10), // Short duration for analysis
  );
  
  // Test with Eleveld model
  final simulation = PDSim.Simulation(
    model: Model.Eleveld,
    patient: patient,
    pump: pump,
  );
  
  final results = simulation.estimate;
  
  print('Time Step: ${pump.timeStep.inSeconds} seconds');
  print('Max Pump Rate: ${pump.maxPumpRate} mL/hr = ${pump.maxPumpRate * pump.density} mg/hr');
  print('Target: ${pump.target} mcg/mL\n');
  
  // Analyze first 5 minutes (300 seconds) to see rate changes
  print('Time\t\tPump Rate (mg/hr)\tPump Rate (mL/hr)\tAccum Volume (mL)');
  print('----\t\t-----------------\t-----------------\t-----------------');
  
  int maxRateCount = 0;
  double lastHighRate = 0;
  Duration? highRateEndTime;
  
  for (int i = 0; i < results.times.length && results.times[i].inSeconds <= 300; i++) {
    final time = results.times[i];
    final pumpRateMgHr = results.pumpInfs[i];
    final pumpRateMlHr = pumpRateMgHr / pump.density;
    final accumVolume = results.cumulativeInfusedVolumes[i];
    
    // Check if at max rate
    final maxRateMgHr = pump.maxPumpRate * pump.density;
    final isMaxRate = (pumpRateMgHr >= maxRateMgHr * 0.95); // 95% threshold for floating point comparison
    
    if (isMaxRate) {
      maxRateCount++;
      lastHighRate = pumpRateMgHr;
    } else if (maxRateCount > 0 && highRateEndTime == null) {
      highRateEndTime = time;
    }
    
    // Print every 15 seconds for first minute, then every 30 seconds
    final shouldPrint = time.inSeconds <= 60 
        ? time.inSeconds % 15 == 0
        : time.inSeconds % 30 == 0;
        
    if (shouldPrint || i == 0 || (highRateEndTime != null && time == highRateEndTime)) {
      final timeStr = '${time.inMinutes}:${(time.inSeconds % 60).toString().padLeft(2, '0')}';
      print('$timeStr\t\t${pumpRateMgHr.toStringAsFixed(1)}\t\t\t${pumpRateMlHr.toStringAsFixed(1)}\t\t\t${accumVolume.toStringAsFixed(1)}');
    }
  }
  
  print('\n=== Analysis Summary ===');
  print('High rate duration: ${highRateEndTime?.inSeconds ?? 'Unknown'} seconds');
  print('High rate steps: $maxRateCount steps');
  print('Last high rate: ${lastHighRate.toStringAsFixed(1)} mg/hr');
  
  if (highRateEndTime != null) {
    final highRateSeconds = highRateEndTime.inSeconds;
    print('High rate lasted: $highRateSeconds seconds (${(highRateSeconds/60).toStringAsFixed(1)} minutes)');
    
    // Calculate "bolus" equivalent volume delivered at high rate
    final highRateIndex = maxRateCount - 1;
    if (highRateIndex < results.cumulativeInfusedVolumes.length) {
      final bolusVolume = results.cumulativeInfusedVolumes[highRateIndex];
      print('Equivalent "bolus" volume: ${bolusVolume.toStringAsFixed(1)} mL');
    }
  }
}