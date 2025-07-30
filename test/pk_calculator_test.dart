import 'package:flutter_test/flutter_test.dart';
import 'package:propofol_dreams_app/models/model.dart';
import 'package:propofol_dreams_app/models/sex.dart';
import 'package:propofol_dreams_app/models/parameters.dart';

void main() {
  group('PK Calculator', () {
    
    /// Helper function to calculate and display parameters for a patient
    void calculateForPatient({
      required Sex sex,
      required int weight, 
      required int height,
      required int age,
      required String description,
    }) {
      print('\n=== $description ===');
      print('Sex: ${sex.name}, Age: ${age}y, Height: ${height}cm, Weight: ${weight}kg');
      print('BMI: ${(weight / ((height/100) * (height/100))).toStringAsFixed(1)}');
      
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
      
      print('\n--- PHARMACOKINETIC PARAMETERS ---\n');
      
      for (final model in allModels) {
        try {
          // Check if model is applicable
          if (!model.isEnable(age: age, height: height, weight: weight)) {
            print('${model.name}: NOT APPLICABLE (constraints not met)');
            continue;
          }
          
          final params = model.calculatePKParameters(
            sex: sex, weight: weight, height: height, age: age,
          );
          
          print('${model.name} (${model.drug.displayName})');
          print('  Concentration: ${model.drug.concentration} ${model.drug.concentrationUnit.displayName}');
          print('  Target: ${model.target.name} (${model.drug.targetUnit.displayName})');
          print('  V1=${params.V1.toStringAsFixed(3)}L, V2=${params.V2.toStringAsFixed(3)}L, V3=${params.V3.toStringAsFixed(3)}L');
          print('  Cl1=${params.Cl1.toStringAsFixed(4)}L/min, Cl2=${params.Cl2.toStringAsFixed(4)}L/min, Cl3=${params.Cl3.toStringAsFixed(4)}L/min');
          print('  k10=${params.k10.toStringAsFixed(4)}/min, ke0=${params.ke0.toStringAsFixed(4)}/min');
          
          // Check constraints
          final validation = model.validate(sex: sex, weight: weight, height: height, age: age);
          if (validation.hasError) {
            print('  ⚠️  ${validation.errorMessage}');
          }
          print('');
          
        } catch (e) {
          print('${model.name}: ERROR - $e\n');
        }
      }
    }

    test('Standard adult male', () {
      calculateForPatient(
        sex: Sex.Male,
        weight: 70,
        height: 170, 
        age: 35,
        description: 'STANDARD ADULT MALE (35y, 70kg, 170cm)',
      );
      expect(true, true);
    });

    test('Standard adult female', () {
      calculateForPatient(
        sex: Sex.Female,
        weight: 70,
        height: 180,
        age: 40,
        description: 'STANDARD ADULT FEMALE (40y, 70kg, 180cm)',
      );
      expect(true, true);
    });

    test('Elderly male', () {
      calculateForPatient(
        sex: Sex.Male,
        weight: 75,
        height: 175,
        age: 75,
        description: 'ELDERLY MALE (75y, 75kg, 175cm)',
      );
      expect(true, true);
    });

    test('Young adult female', () {
      calculateForPatient(
        sex: Sex.Female,
        weight: 55,
        height: 165,
        age: 25,
        description: 'YOUNG ADULT FEMALE (25y, 55kg, 165cm)',
      );
      expect(true, true);
    });

    test('Obese male', () {
      calculateForPatient(
        sex: Sex.Male,
        weight: 120,
        height: 180,
        age: 50,
        description: 'OBESE MALE (50y, 120kg, 180cm)',
      );
      expect(true, true);
    });

    test('Pediatric patient', () {
      calculateForPatient(
        sex: Sex.Male,
        weight: 30,
        height: 140,
        age: 10,
        description: 'PEDIATRIC PATIENT (10y, 30kg, 140cm)',
      );
      expect(true, true);
    });

    test('Compare propofol models', () {
      const sex = Sex.Male;
      const weight = 70;
      const height = 170;
      const age = 35;
      
      print('\n=== PROPOFOL MODEL COMPARISON ===');
      print('Patient: ${sex.name}, ${age}y, ${height}cm, ${weight}kg\n');
      
      final propofolModels = [Model.EleveldPropofol, Model.MarshPropofol, Model.SchniderPropofol];
      
      print('Model           Conc     V1(L)    V2(L)    V3(L)    k10(/min) ke0(/min) Target');
      print('─' * 80);
      
      for (final model in propofolModels) {
        final params = model.calculatePKParameters(sex: sex, weight: weight, height: height, age: age);
        final concStr = '${model.drug.concentration.toStringAsFixed(0)}${model.drug.concentrationUnit.displayName}';
        print('${model.name.padRight(15)} ${concStr.padRight(8)} ${params.V1.toStringAsFixed(2).padLeft(6)} ${params.V2.toStringAsFixed(1).padLeft(7)} ${params.V3.toStringAsFixed(0).padLeft(7)} ${params.k10.toStringAsFixed(4).padLeft(9)} ${params.ke0.toStringAsFixed(3).padLeft(8)} ${model.target.name}');
      }
      
      expect(true, true);
    });

    test('All models summary', () {
      const sex = Sex.Male;
      const weight = 70;
      const height = 170;
      const age = 35;
      
      print('\n=== ALL MODELS SUMMARY ===');
      print('Patient: ${sex.name}, ${age}y, ${height}cm, ${weight}kg\n');
      
      final models = [
        Model.EleveldPropofol,
        Model.MarshPropofol,
        Model.SchniderPropofol,
        Model.MintoRemifentanil,
        Model.HannivoortDexmedetomidine,
        Model.EleveldRemimazolam,
      ];
      
      print('Model                    Drug            Conc      V1(L)  k10(/min) ke0(/min) Target');
      print('─' * 85);
      
      for (final model in models) {
        final params = model.calculatePKParameters(sex: sex, weight: weight, height: height, age: age);
        final concStr = '${model.drug.concentration.toStringAsFixed(0)}${model.drug.concentrationUnit.displayName}';
        print('${model.name.padRight(24)} ${model.drug.displayName.padRight(15)} ${concStr.padRight(9)} ${params.V1.toStringAsFixed(2).padLeft(5)} ${params.k10.toStringAsFixed(4).padLeft(9)} ${params.ke0.toStringAsFixed(3).padLeft(8)} ${model.target.name}');
      }
      
      expect(true, true);
    });

    // Test with custom parameters - modify these values as needed
    test('Custom patient', () {
      // MODIFY THESE VALUES FOR YOUR SPECIFIC PATIENT:
      const sex = Sex.Female;     // Sex.Male or Sex.Female
      const weight = 65;          // Weight in kg
      const height = 168;         // Height in cm
      const age = 42;             // Age in years
      
      calculateForPatient(
        sex: sex,
        weight: weight,
        height: height,
        age: age,
        description: 'CUSTOM PATIENT',
      );
      expect(true, true);
    });
  });
}