import 'package:flutter_test/flutter_test.dart';
import 'package:propofol_dreams_app/models/model.dart';
import 'package:propofol_dreams_app/providers/settings.dart';

void main() {
  group('Model Separation Simple Test', () {
    test('TCI model and adult model are separate properties', () {
      final settings = Settings();
      
      // Verify they have different default values
      expect(settings.adultModel, equals(Model.None));
      expect(settings.tciModel, equals(Model.EleveldPropofol));
      
      // Verify they are separate properties by checking they're not equal
      expect(settings.adultModel != settings.tciModel, true);
      
      print('✓ TCI model and adult model are separate properties');
      print('  Adult model: ${settings.adultModel}');
      print('  TCI model: ${settings.tciModel}');
    });
  });
}