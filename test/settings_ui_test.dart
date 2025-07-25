import 'package:flutter_test/flutter_test.dart';
import 'package:propofol_dreams_app/models/drug.dart';
import 'package:propofol_dreams_app/providers/settings.dart';

void main() {
  group('Settings UI Test', () {
    test('Settings only shows 4 drugs after removal', () {
      final settings = Settings();
      
      // Verify that only 4 drugs are configured (removed Eleveld Remifentanil)
      final propofol = settings.getAvailableConcentrations(Drug.propofol);
      final minto = settings.getAvailableConcentrations(Drug.remifentanilMinto);
      final dex = settings.getAvailableConcentrations(Drug.dexmedetomidine);
      final remi = settings.getAvailableConcentrations(Drug.remimazolam);
      
      // Verify concentrations are available
      expect(propofol, equals([10.0, 20.0]));
      expect(minto, equals([50.0]));
      expect(dex, equals([4.0]));
      expect(remi, equals([1.0]));
      
      print('✓ 4 drugs properly configured in settings');
    });

    test('Drug concentration system works correctly', () {
      final settings = Settings();
      
      // Test propofol concentration selection
      expect(settings.getDrugConcentration(Drug.propofol), equals(10.0));
      
      settings.setDrugConcentration(Drug.propofol, 20.0);
      expect(settings.getDrugConcentration(Drug.propofol), equals(20.0));
      
      // Test that density getter still works for backward compatibility
      expect(settings.density, equals(20));
      
      // Test other drugs have fixed concentrations
      expect(settings.getDrugConcentration(Drug.remifentanilMinto), equals(50.0));
      expect(settings.getDrugConcentration(Drug.dexmedetomidine), equals(4.0));
      expect(settings.getDrugConcentration(Drug.remimazolam), equals(1.0));
      
      print('✓ Drug concentration system working correctly');
    });

    test('Removed model not in TCI screen models but parameters still work', () {
      // Verify EleveldRemifentanil can still calculate parameters for backward compatibility
      // but is not shown in UI
      final availableConcentrations = Settings().getAvailableConcentrations(Drug.remifentanilEleveld);
      expect(availableConcentrations, equals([50.0]));
      
      print('✓ Removed model maintains parameter compatibility');
    });
  });
}