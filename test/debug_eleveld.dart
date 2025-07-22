import 'package:propofol_dreams_app/models/model.dart';
import 'package:propofol_dreams_app/models/sex.dart';
import 'dart:math' as math;

void main() {
  // Test standard reference patient
  final pkParams = Model.Eleveld.calculatePKParameters(
    sex: Sex.Male,
    weight: 70,
    height: 170,
    age: 35,
  );

  print('Flutter Implementation Results:');
  print('V1: ${pkParams.V1.toStringAsFixed(6)}');
  print('V2: ${pkParams.V2.toStringAsFixed(6)}');
  print('V3: ${pkParams.V3.toStringAsFixed(6)}');
  print('Cl1: ${pkParams.Cl1.toStringAsFixed(6)}');
  print('Cl2: ${pkParams.Cl2.toStringAsFixed(6)}');
  print('Cl3: ${pkParams.Cl3.toStringAsFixed(6)}');
  print('k10: ${pkParams.k10.toStringAsFixed(6)}');
  print('k12: ${pkParams.k12.toStringAsFixed(6)}');
  print('k21: ${pkParams.k21.toStringAsFixed(6)}');
  print('k13: ${pkParams.k13.toStringAsFixed(6)}');
  print('k31: ${pkParams.k31.toStringAsFixed(6)}');
  print('ke0: ${pkParams.ke0.toStringAsFixed(6)}');
  print('ce50: ${pkParams.ce50!.toStringAsFixed(6)}');

  print('\nMATLAB Reference Results:');
  print('V1: 6.280000');
  print('V2: 25.500000');
  print('V3: 168.421842');
  print('Cl1: 1.619497');
  print('Cl2: 1.830371');
  print('Cl3: 0.772661');
  print('k10: 0.257882');
  print('k12: 0.291460');
  print('k21: 0.071779');
  print('k13: 0.123035');
  print('k31: 0.004588');
  print('ke0: 0.146000');
  print('ce50: 3.080000');

  print('\nDetailed V3 Calculation Debug:');
  
  // Step-by-step V3 calculation from MATLAB
  const age = 35.0;
  const weight = 70.0;
  const height = 170.0;
  const sex = 1; // male

  // MATLAB exact calculation
  final v3Component1 = sex * ((0.88 + (0.12) / (1 + math.pow(age / 13.4, -12.7))) * 
                              (9270 * weight / (6680 + 216 * weight / math.pow(height / 100, 2))));
  final v3Component2 = (1 - sex) * ((1.11 + (-0.11) / (1 + math.pow(age / 7.1, -1.1))) *
                                   (9270 * weight / (8780 + 244 * weight / math.pow(height / 100, 2))));
  final v3Matlab = 273 * math.exp(-0.0138 * age) * (v3Component1 + v3Component2) / 54.4752059601377;

  print('MATLAB V3 components:');
  print('v3Component1 (male): ${v3Component1.toStringAsFixed(6)}');
  print('v3Component2 (female): ${v3Component2.toStringAsFixed(6)}');
  print('Combined: ${(v3Component1 + v3Component2).toStringAsFixed(6)}');
  print('After age factor: ${(273 * math.exp(-0.0138 * age)).toStringAsFixed(6)}');
  print('Final V3: ${v3Matlab.toStringAsFixed(6)}');

  print('\nFlutter V3 calculation step-by-step:');
  // Current Flutter calculation (simplified)
  print('Flutter V3: ${pkParams.V3.toStringAsFixed(6)}');
  
  // Check if we're using the opioid adjustment
  print('\nOpioid adjustment check:');
  print('With opioid exp(-0.0138*age): ${math.exp(-0.0138 * age).toStringAsFixed(6)}');
  print('Without opioid: 1.0');
}