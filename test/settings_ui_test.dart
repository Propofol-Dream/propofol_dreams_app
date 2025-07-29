import 'package:flutter_test/flutter_test.dart';
import 'package:propofol_dreams_app/models/drug.dart';
import 'package:propofol_dreams_app/providers/settings.dart';

void main() {
  group('Settings UI Test', () {
    test('Settings only shows 4 drugs after removal', () {
      final settings = Settings();
      
      // Verify drug variants using drug type strings
      final propofolVariants = settings.getAvailableDrugVariants('Propofol');
      final remifentanilVariants = settings.getAvailableDrugVariants('Remifentanil');
      final dexVariants = settings.getAvailableDrugVariants('Dexmedetomidine');
      final remiVariants = settings.getAvailableDrugVariants('Remimazolam');
      
      // Verify concentrations are available
      expect(propofolVariants.length, equals(2)); // 10mg, 20mg
      expect(remifentanilVariants.length, equals(3)); // 20mcg, 40mcg, 50mcg
      expect(dexVariants.length, equals(1)); // 4mcg
      expect(remiVariants.length, equals(2)); // 1mg, 2mg
      
      print('✓ 4 drugs properly configured in settings');
    });

    test('Drug concentration system works correctly', () {
      final settings = Settings();
      
      // Test propofol concentration selection
      expect(settings.getDrugConcentration(Drug.propofol10mg), equals(10.0));
      
      settings.setDrugConcentration(Drug.propofol20mg, 20.0);
      expect(settings.getDrugConcentration(Drug.propofol20mg), equals(20.0));
      
      // Test that density getter still works for backward compatibility
      expect(settings.density, equals(20));
      
      // Test other drugs have their default concentrations
      expect(settings.getDrugConcentration(Drug.remifentanil50mcg), equals(50.0));
      expect(settings.getDrugConcentration(Drug.dexmedetomidine), equals(4.0));
      expect(settings.getDrugConcentration(Drug.remimazolam1mg), equals(1.0));
      expect(settings.getDrugConcentration(Drug.remimazolam2mg), equals(2.0));
      
      print('✓ Drug concentration system working correctly');
    });

    test('Remimazolam concentration variants work correctly', () {
      final settings = Settings();
      
      // Test that we can switch between remimazolam concentrations
      final currentRemi = settings.getCurrentDrugVariant('Remimazolam');
      expect(currentRemi, equals(Drug.remimazolam1mg)); // Default should be 1mg
      
      // Test switching to 2mg concentration
      settings.setDrugConcentration(Drug.remimazolam2mg, 2.0);
      expect(settings.remimazolam_concentration, equals(2.0));
      
      // Verify the current variant updates
      final newCurrentRemi = settings.getCurrentDrugVariant('Remimazolam');
      expect(newCurrentRemi, equals(Drug.remimazolam2mg));
      
      print('✓ Remimazolam concentration switching working correctly');
    });
  });
}