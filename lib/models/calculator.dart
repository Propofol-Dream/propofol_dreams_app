import 'dart:math';

class Calculator {
  ({double wakeCeLow, double wakeCeHigh})calcWakeUpCE({required double ce, required int se}){
    double basese = 100.0;
    double gammawake = 6.63495422005024;
    double gammaeeg = 6.7480404291049673;
    double shiftratio = 0.0;

    double wakelinearcoeff = 0.671640268042454;
    double wakelinearoffset = -0.135905829113675;
    double eeglinearcoeff = 0.710061382722482;
    double eeglinearoffset = 0.133079534579095;

    // Calculate wake up CE
    double ce50wake = ce / (pow((basese / se - 1), (1 / gammawake)) + shiftratio);
    double ce50shift = ce50wake * shiftratio;
    double wakece = ce50wake * wakelinearcoeff + wakelinearoffset;

    // Calculate EEG speed up CE
    double ce50eeg = ce / (pow((basese / se - 1), (1 / gammaeeg)) + shiftratio);
    double eegce = ce50eeg * eeglinearcoeff + eeglinearoffset;

    // Output results
    return(wakeCeLow: wakece, wakeCeHigh: eegce );
  }
}