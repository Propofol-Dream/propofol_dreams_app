import 'package:flutter_test/flutter_test.dart';
import 'package:propofol_dreams_app/models/model.dart';
import 'package:propofol_dreams_app/providers/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Model Separation Simple Test', () {
    test('TCI model and adult model are separate properties', () {
      final settings = Settings();
      
      // Verify current default values
      expect(settings.adultModel, equals(Model.Eleveld));
      expect(settings.tciModel, equals(Model.Eleveld));

      // Verify they are separate properties by changing one default.
      settings.adultModel = Model.Marsh;
      expect(settings.adultModel, equals(Model.Marsh));
      expect(settings.tciModel, equals(Model.Eleveld));
      
      print('✓ TCI model and adult model are separate properties');
      print('  Adult model: ${settings.adultModel}');
      print('  TCI model: ${settings.tciModel}');
    });
  });
}
