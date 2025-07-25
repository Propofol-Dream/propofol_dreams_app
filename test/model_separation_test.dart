import 'package:flutter_test/flutter_test.dart';
import 'package:propofol_dreams_app/models/model.dart';
import 'package:propofol_dreams_app/providers/settings.dart';

void main() {
  group('Model Separation Test', () {
    test('TCI screen and Volume screen models are independent', () {
      final settings = Settings();
      
      // Set initial models
      settings.adultModel = Model.MarshPropofol;  // Volume screen model
      settings.tciModel = Model.EleveldPropofol;   // TCI screen model
      
      // Verify they are different
      expect(settings.adultModel, equals(Model.MarshPropofol));
      expect(settings.tciModel, equals(Model.EleveldPropofol));
      
      // Change TCI model
      settings.tciModel = Model.MintoRemifentanil;
      
      // Verify Volume screen model is unchanged
      expect(settings.adultModel, equals(Model.MarshPropofol));
      expect(settings.tciModel, equals(Model.MintoRemifentanil));
      
      // Change Volume screen model  
      settings.adultModel = Model.SchniderPropofol;
      
      // Verify TCI screen model is unchanged
      expect(settings.adultModel, equals(Model.SchniderPropofol));
      expect(settings.tciModel, equals(Model.MintoRemifentanil));
      
      print('✓ TCI and Volume screen models are independent');
    });

    test('TCI model defaults to Eleveld', () {
      final settings = Settings();
      
      // TCI model should default to Eleveld (good starting model for new drugs)
      expect(settings.tciModel, equals(Model.EleveldPropofol));
      
      print('✓ TCI model defaults to Eleveld');
    });

    test('Both models can be new drug models simultaneously', () {
      final settings = Settings();
      
      // Set both to new drug models
      settings.tciModel = Model.HannivoortDexmedetomidine;
      settings.adultModel = Model.EleveldRemimazolam;
      
      // Verify they maintain independent values
      expect(settings.tciModel, equals(Model.HannivoortDexmedetomidine));
      expect(settings.adultModel, equals(Model.EleveldRemimazolam));
      
      print('✓ Both screens can use new drug models independently');
    });
  });
}