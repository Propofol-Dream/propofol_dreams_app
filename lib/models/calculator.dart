import 'dart:math';
import 'model.dart';

class Calculator {
  ({double lower, double upper})calcWakeUpCE({required double ce, required int se, required Model m}){

    double basese = 100.0;
    double gammaLower = 0.0, gammerUpper = 0.0;
    double coeffLower = 0.0, coeffUpper = 0.0;
    double offsetLower = 0.0, offsetUpper = 0.0;

    if( m == Model.Eleveld){

      gammaLower = 4.55410613557215;
      coeffLower = 0.465936758202314;
      offsetLower = 0.477223367024224;

      gammerUpper = 6.74804291049673;
      coeffUpper = 0.710061382722482;
      offsetUpper = 0.133079534579095;

    }else if ( m == Model.EleMarsh){

      gammaLower = 6.88986185235045;
      coeffLower = 0.404591957791188;
      offsetLower = 0.25102120174394;

      gammerUpper = 5.98370830613453;
      coeffUpper = 0.540328579876593;
      offsetUpper = 0.107298105871768;

    }

    double lower = ce / (pow((basese / se - 1), (1 / gammaLower))) * coeffLower + offsetLower;
    double upper = ce / (pow((basese / se - 1), (1 / gammerUpper))) * coeffUpper + offsetUpper;

    //Swap lower with upper if lower is greater than upper
    if (lower >= upper) {
      double temp = lower;
      lower = upper;
      upper = temp;
    }

    if (m == Model.EleMarsh){

      double gammaLowerEleveld = 4.55410613557215;
      double coeffLowerEleveld = 0.465936758202314;
      double offsetLowerEleveld = 0.477223367024224;
      double lowerEleveld = ce / (pow((basese / se - 1), (1 / gammaLowerEleveld))) * coeffLowerEleveld + offsetLowerEleveld;

      // The upper below is upperEleMarsh
      // Swap upperEleMarsh with lowerEleveld, if upper EleMarsh is less than lowerEleveld
      if (upper <= lowerEleveld) {
        upper = lowerEleveld;
      }
    }

    return(lower: lower, upper: upper );
  }
}