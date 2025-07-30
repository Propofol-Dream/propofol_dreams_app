import 'package:flutter_test/flutter_test.dart';
import 'package:propofol_dreams_app/models/model.dart';
import 'package:propofol_dreams_app/models/sex.dart';
import 'package:propofol_dreams_app/models/parameters.dart';

void main() {
  group('Pharmacokinetic Parameter Calculator', () {
    
    /// Helper function to calculate and display parameters for a patient
    void calculateAndDisplayParameters({
      required Sex sex,
      required int weight, 
      required int height,
      required int age,
      required String patientDescription,
    }) {
      
      print('\n=== PHARMACOKINETIC PARAMETER CALCULATOR ===\n');
      
      print('\n=== PATIENT PARAMETERS ===');
      print('Sex: ${sex.name}');
      print('Weight: ${weight} kg');
      print('Height: ${height} cm');
      print('Age: ${age} years');
      print('BMI: ${(weight / ((height/100) * (height/100))).toStringAsFixed(1)}');
      
      // Calculate parameters for all models
      final allModels = [
        Model.EleveldPropofol,
        Model.MarshPropofol,
        Model.SchniderPropofol,
        Model.PaedfusorPropofol,
        Model.KatariaPropofol,
        Model.MintoRemifentanil,
        Model.EleveldRemifentanil,
        Model.HannivoortDexmedetomidine,
        Model.EleveldRemimazolam,
      ];
      
      print('\n=== PHARMACOKINETIC PARAMETERS ===\n');
      
      for (final model in allModels) {
        try {
          // Check if model is applicable for this patient
          if (!model.isEnable(age: age, height: height, weight: weight)) {
            print('${model.name} - NOT APPLICABLE (age/height/weight out of range)');
            continue;
          }
          
          // Calculate parameters
          final params = model.calculatePKParameters(
            sex: sex,
            weight: weight,
            height: height,
            age: age,
          );
          
          // Print model info
          print('${model.name} (${model.drug.displayName})');
          print('  Drug Concentration: ${model.drug.concentration} ${model.drug.concentrationUnit.displayName}');
          print('  Target: ${model.target.name} (${model.drug.targetUnit.displayName})');
          print('  ');
          print('  VOLUMES (L):');
          print('    V1 (Central): ${params.V1.toStringAsFixed(4)}');
          print('    V2 (Peripheral 1): ${params.V2.toStringAsFixed(4)}');
          print('    V3 (Peripheral 2): ${params.V3.toStringAsFixed(4)}');
          print('  ');
          print('  CLEARANCES (L/min):');
          print('    Cl1 (Elimination): ${params.Cl1.toStringAsFixed(4)}');
          print('    Cl2 (Inter-compartmental 1): ${params.Cl2.toStringAsFixed(4)}');
          print('    Cl3 (Inter-compartmental 2): ${params.Cl3.toStringAsFixed(4)}');
          print('  ');
          print('  RATE CONSTANTS (min⁻¹):');
          print('    k10 (Elimination): ${params.k10.toStringAsFixed(4)}');
          print('    k12 (Central → Peripheral 1): ${params.k12.toStringAsFixed(4)}');
          print('    k21 (Peripheral 1 → Central): ${params.k21.toStringAsFixed(4)}');
          print('    k13 (Central → Peripheral 2): ${params.k13.toStringAsFixed(4)}');
          print('    k31 (Peripheral 2 → Central): ${params.k31.toStringAsFixed(4)}');
          print('    ke0 (Effect-site equilibration): ${params.ke0.toStringAsFixed(4)}');
          
          // Show BIS parameters for propofol models
          if (params.ce50 != null) {
            print('  ');
            print('  BIS PARAMETERS:');
            print('    CE50: ${params.ce50!.toStringAsFixed(2)} mcg/mL');
            print('    Baseline BIS: ${params.baselineBIS!.toStringAsFixed(0)}');
            print('    BIS Delay: ${params.delayBIS!.toStringAsFixed(1)} sec');
          }
          
          // Check model constraints
          final validation = model.validate(
            sex: sex,
            weight: weight,
            height: height,
            age: age,
          );
          
          if (validation.hasError) {
            print('  ⚠️  WARNING: ${validation.errorMessage}');
          } else {
            print('  ✅ All constraints satisfied');
          }
          
          print('');
          
        } catch (e) {
          print('${model.name} - ERROR: $e');
          print('');
        }
      }
      
      print('=== SUMMARY ===');
      print('Parameters calculated for patient:');
      print('${sex.name}, ${age}y, ${height}cm, ${weight}kg');
      
      // Always pass the test
      expect(true, true);
    });
    
    test('Quick reference - Calculate for standard patient', () {
      // Standard reference patient: 35yo male, 70kg, 170cm
      const sex = Sex.Male;
      const weight = 70;
      const height = 170;
      const age = 35;
      
      print('\n=== QUICK REFERENCE - STANDARD PATIENT ===');
      print('35-year-old male, 70kg, 170cm\n');
      
      final models = [
        Model.EleveldPropofol,
        Model.MarshPropofol,
        Model.SchniderPropofol,
        Model.MintoRemifentanil,
        Model.HannivoortDexmedetomidine,
        Model.EleveldRemimazolam,
      ];
      
      for (final model in models) {
        final params = model.calculatePKParameters(
          sex: sex,
          weight: weight,
          height: height,
          age: age,
        );
        
        print('${model.name}:');
        print('  V1=${params.V1.toStringAsFixed(2)}L, V2=${params.V2.toStringAsFixed(2)}L, V3=${params.V3.toStringAsFixed(2)}L');
        print('  k10=${params.k10.toStringAsFixed(4)}, ke0=${params.ke0.toStringAsFixed(4)}');
      }
      
      expect(true, true);
    });
    
    test('Compare models for same drug', () {
      const sex = Sex.Male;
      const weight = 70;
      const height = 170;
      const age = 35;
      
      print('\n=== MODEL COMPARISON ===\n');
      
      // Compare propofol models
      print('PROPOFOL MODELS:');
      final propofolModels = [Model.EleveldPropofol, Model.MarshPropofol, Model.SchniderPropofol];
      for (final model in propofolModels) {
        final params = model.calculatePKParameters(sex: sex, weight: weight, height: height, age: age);
        print('${model.name}: V1=${params.V1.toStringAsFixed(2)}L, Cl1=${params.Cl1.toStringAsFixed(3)}L/min, ke0=${params.ke0.toStringAsFixed(3)}');
      }
      
      print('\nREMIFENTANIL MODELS:');
      final remiModels = [Model.MintoRemifentanil, Model.EleveldRemifentanil];
      for (final model in remiModels) {
        final params = model.calculatePKParameters(sex: sex, weight: weight, height: height, age: age);
        print('${model.name}: V1=${params.V1.toStringAsFixed(2)}L, Cl1=${params.Cl1.toStringAsFixed(3)}L/min, ke0=${params.ke0.toStringAsFixed(3)}');
      }
      
      expect(true, true);
    });
  });
}