import 'package:flutter_test/flutter_test.dart';
import 'package:propofol_dreams_app/models/model.dart';
import 'package:propofol_dreams_app/providers/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Model Separation Test', () {
    test('TCI screen and Volume screen models are independent', () {
      final settings = Settings();
      
      // Set initial models
      settings.adultModel = Model.Marsh;  // Volume screen model
      settings.tciModel = Model.Eleveld;   // TCI screen model
      
      // Verify they are different
      expect(settings.adultModel, equals(Model.Marsh));
      expect(settings.tciModel, equals(Model.Eleveld));
      
      // Change TCI model
      settings.tciModel = Model.Eleveld;
      
      // Verify Volume screen model is unchanged
      expect(settings.adultModel, equals(Model.Marsh));
      expect(settings.tciModel, equals(Model.Eleveld));
      
      // Change Volume screen model  
      settings.adultModel = Model.Schnider;
      
      // Verify TCI screen model is unchanged
      expect(settings.adultModel, equals(Model.Schnider));
      expect(settings.tciModel, equals(Model.Eleveld));
      
      print('✓ TCI and Volume screen models are independent');
    });

    test('TCI model defaults to Eleveld', () {
      final settings = Settings();
      
      // TCI model should default to Eleveld (good starting model for new drugs)
      expect(settings.tciModel, equals(Model.Eleveld));
      
      print('✓ TCI model defaults to Eleveld');
    });

    test('Both models can be new drug models simultaneously', () {
      final settings = Settings();
      
      // Set both to new drug models
      settings.tciModel = Model.Hannivoort;
      settings.adultModel = Model.Eleveld;
      
      // Verify they maintain independent values
      expect(settings.tciModel, equals(Model.Hannivoort));
      expect(settings.adultModel, equals(Model.Eleveld));
      
      print('✓ Both screens can use new drug models independently');
    });
  });
}
