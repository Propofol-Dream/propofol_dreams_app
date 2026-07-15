import 'package:flutter_test/flutter_test.dart';
import 'package:propofol_dreams_app/models/drug.dart';
import 'package:propofol_dreams_app/models/model.dart';
import 'package:propofol_dreams_app/screens/tci_screen_new.dart';

void main() {
  test('TCIScreenNew drug mapping matches legacy pdtci behavior', () {
    expect(TCIScreenNew.modelForDrug(Drug.propofol10mg), Model.Eleveld);
    expect(TCIScreenNew.modelForDrug(Drug.remifentanil50mcg), Model.Eleveld);
    expect(TCIScreenNew.modelForDrug(Drug.dexmedetomidine), Model.Hannivoort);
    expect(TCIScreenNew.modelForDrug(Drug.remimazolam1mg), Model.Schnider);
  });
}
