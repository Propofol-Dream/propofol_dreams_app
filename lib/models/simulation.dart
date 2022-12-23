

import 'dart:math';
import 'package:propofol_dreams_app/models/patient.dart';
import 'package:propofol_dreams_app/models/pump.dart';
import 'package:propofol_dreams_app/models/operation.dart';
import 'model.dart';
import 'gender.dart';
import 'target.dart';

class Simulation {
  Model model;
  Patient patient;
  Pump pump;

  Simulation({required this.model, required this.patient, required this.pump});

  Map<String, double> get variables {
    double k10 = 0,
        k12 = 0,
        k13 = 0,
        k21 = 0,
        k31 = 0,
        ke0 = 0,
        V1 = 0,
        V2 = 0,
        V3 = 0;
    if (model == Model.Paedfusor) {
      k10 = 0.1527 * pow(patient.weight, -0.3); // per min;
      k12 = 0.114; // per min
      k13 = 0.0419; // per min
      k21 = 0.055; // per min
      k31 = 0.0033; // per min
      ke0 = 0.26; // per min

      V1 = 0.4584 * patient.weight;
      V2 = V1 * k12 / k21;
      V3 = V1 * k13 / k31;

      if (patient.age == 13) {
        k10 = 0.0678; // per min

        V1 = 0.4 * patient.weight;
        V2 = V1 * k12 / k21;
        V3 = V1 * k13 / k31;
      } else if (patient.age == 14) {
        k10 = 0.0792; // per min

        V1 = 0.342 * patient.weight;
        V2 = V1 * k12 / k21;
        V3 = V1 * k13 / k31;
      } else if (patient.age == 15) {
        k10 = 0.0954; // per min

        V1 = 0.284 * patient.weight;
        V2 = V1 * k12 / k21;
        V3 = V1 * k13 / k31;
      } else if (patient.age == 16) {
        k10 = 0.119; // per min

        V1 = 0.22857 * patient.weight;
        V2 = V1 * k12 / k21;
        V3 = V1 * k13 / k31;
      }
    } else if (model == Model.Kataria) {
      k10 = 0.085; // per min
      k12 = 0.188; // per min
      k13 = 0.063; // per min
      k21 = 0.102; // per min
      k31 = 0.0038; // per min
      ke0 = 0; // per min

      V1 = 0.41 * patient.weight;
      V2 = 0.78 * patient.weight + 3.1 * patient.age;
      V3 = 6.9 * patient.weight;
    } else if (model == Model.Marsh) {
      k10 = 0.119; // per min
      k12 = 0.112; // per min
      k13 = 0.042; // per min
      k21 = 0.055; // per min
      k31 = 0.0033; // per min
      ke0 = 1.2; // per min

      V1 = 0.228 * patient.weight;
      V2 = 0.463 * patient.weight;
      V3 = 2.893 * patient.weight;
    } else if (model == Model.Schnider) {
      V1 = 4.27; //litre
      V2 = 18.9 - 0.391 * (patient.age - 53); //litre
      V3 = 238.0; //litre

      k10 = (0.443 +
          0.0107 * (patient.weight - 77) -
          0.0159 * (patient.lbm - 59) +
          0.0062 * (patient.height - 177)); // per min

      k12 = (0.302 - 0.0056 * (patient.age - 53)); // per min
      k13 = 0.196; // per min
      k21 = (1.29 - 0.024 * (patient.age - 53)) /
          (18.9 - 0.391 * (patient.age - 53)); // per min
      k31 = 0.0035; // per min
      ke0 = 0.456; // per min
      // t_half_keo = np.log(2) / (ke0 * steps_per_min) //deprecated

    }
    double Cl1 = k10 * V1; //litre / steps per min
    double Cl2 = k21 * V2; //litre / steps per min
    double Cl3 = k31 * V3; //litre / steps per min

    if (model == Model.Eleveld) {
      bool opioid = true; // arbitralily set YES to intraop opioids

      V1 = 6.28 * (patient.weight / (patient.weight + 33.6)) / (0.675675675676);
      V2 = 25.5 * (patient.weight / 70) * exp(-0.0156 * (patient.age - 35));

      V3 = 273 *
          patient.ffm *
          (opioid ? exp(-0.0138 * patient.age) : 1) /
          54.4752059601377;

      Cl1 = ((patient.gender == Gender.Male ? 1.79 : 2.1) *
              (pow((patient.weight / 70), 0.75)) *
              (pow(patient.pma, 9.06)) /
              (pow(patient.pma, 9.06) + pow(42.3, 9.06))) *
          (opioid ? exp(-0.00286 * patient.age) : 1);

      Cl2 = 1.75 *
          (pow(
              ((25.5 *
                      (patient.weight / 70) *
                      exp(-0.0156 * (patient.age - 35))) /
                  25.5),
              0.75)) *
          (1 + 1.3 * (1 - patient.pma / (patient.pma + 68.3)));

      Cl3 = 1.11 *
          (pow(
              (patient.ffm *
                  (opioid ? exp(-0.0138 * patient.age) : 1) /
                  54.4752059601377),
              0.75)) *
          (patient.pma / (patient.pma + 68.3) / 0.964695544);

      k10 = Cl1 / V1;
      k12 = Cl2 / V1;
      k13 = Cl3 / V1;
      k21 = Cl2 / V2;
      k31 = Cl3 / V3;
      ke0 = 0.146 * pow((patient.weight / 70), -0.25);
    }

    double ce50 = 3.08 * exp(-0.00635 * (patient.age - 35));
    double baseline_BIS = 93;
    double delay_BIS = 15 + exp(0.0517 * (patient.age - 35));

    return {
      'V1': V1,
      'V2': V2,
      'V3': V3,
      'k10': k10,
      'k12': k12,
      'k13': k13,
      'k21': k21,
      'k31': k31,
      'ke0': ke0,
      'Cl1': Cl1,
      'Cl2': Cl2,
      'Cl3': Cl3,
      'ce50': ce50,
      'baseline_BIS': baseline_BIS,
      'delay_BIS': delay_BIS,
    };
  }

  List<double> cumulativeSum(List<double> l) {
    double cumSum = 0;
    List<double> cum_sums = [];
    l.forEach((i) {
      cumSum += i;
      cum_sums.add(cumSum);
    });
    return cum_sums;
  }

  double get calibrated_effect {
    int time_step = 1; //sec
    int duration = 720;
    double max_infusion = (pump.dilution * pump.max_pump_rate).toDouble();

    int step = 0;
    double k21 = variables['k21'] as double;
    double k31 = variables['k31'] as double;
    double k10 = variables['k10'] as double;
    double k12 = variables['k12'] as double;
    double k13 = variables['k13'] as double;
    double V1 = variables['V1'] as double;
    double ke0 = variables['ke0'] as double;

    List<double> A1s = [];
    List<double> A2s = [];
    List<double> A3s = [];
    List<Duration> times = [];
    List<int> steps = [];
    List<double> pump_infs = [];
    List<double> concentrations = [];
    List<double> concentrations_effect = [];

    for (int time = 0; time <= duration; time += time_step) {
      double pump_inf = time < 100 ? max_infusion : 0;

      double A2 = step == 0
          ? 0
          : A2s.last + (k12 * A1s.last - k21 * A2s.last) * time_step / 60;

      double A3 = step == 0
          ? 0
          : A3s.last + (k13 * A1s.last - k31 * A3s.last) * time_step / 60;

      double A1 = step == 0
          ? 0
          : (pump_infs.last / 60 +
                      A2 * k21 +
                      A3 * k31 -
                      A1s.last * (k10 + k12 + k13)) *
                  time_step /
                  60 +
              A1s.last;

      double concentration = A1 / V1;
      double concentration_effect = step == 0
          ? 0
          : concentrations_effect.last +
              ke0 *
                  (concentrations.last - concentrations_effect.last) *
                  time_step /
                  60;

      times.add(Duration(seconds: time));
      steps.add(step);
      pump_infs.add(pump_inf);
      A1s.add(A1);
      A2s.add(A2);
      A3s.add(A3);
      concentrations.add(concentration);
      concentrations_effect.add(concentration_effect);

      // print(
      //     '$time | $pump_inf | $A1 | $A2 | $A3 | ${Duration(seconds: time)} | $concentration | $concentration_effect');
      step = step + 1;
    }
    return concentrations_effect.reduce(max);
  }

  Map<String, dynamic>  estimate ({required Operation operation}) {
    double max_infusion =
        (pump.dilution * pump.max_pump_rate).toDouble(); // mg per hr

    int step = 0;
    double k21 = variables['k21'] as double;
    double k31 = variables['k31'] as double;
    double k10 = variables['k10'] as double;
    double k12 = variables['k12'] as double;
    double k13 = variables['k13'] as double;
    double V1 = variables['V1'] as double;
    double ke0 = variables['ke0'] as double;

    //List for calibrated_effect only
    List<double> A1s = [];
    List<double> A2s = [];
    List<double> A3s = [];
    List<Duration> times = [];
    List<int> steps = [];
    List<double> pump_infs = []; //mg per hr
    List<double> concentrations = [];
    List<double> concentrations_effect = [];

    //List for volume estimation
    List<double> depths = [];
    List<double> overshoot_times = [];
    List<double> infs = []; //mg per hr
    List<double> A1_changes = [];
    List<double> cumulative_infused_volumes = []; // mL

    for (int time = 0; time <= operation.duration * 60; time += pump.time_step) {
      double A2 = step == 0
          ? 0
          : A2s.last + (k12 * A1s.last - k21 * A2s.last) * pump.time_step / 60;

      double A3 = step == 0
          ? 0
          : A3s.last + (k13 * A1s.last - k31 * A3s.last) * pump.time_step / 60;

      double concentration_effect = step == 0
          ? 0
          : concentrations_effect.last +
              ke0 *
                  (concentrations.last - concentrations_effect.last) *
                  pump.time_step /
                  60;

      double overshoot_time = (step == 0
          ? operation.depth /
                  calibrated_effect *
                  100 -
              1
          : (operation.depth - depths.last > 0
              ? (operation.depth - depths.last) /
                      calibrated_effect *
                      100 -
                  1
              : overshoot_times.last - pump.time_step));

      double A1_change = step == 0
          ? 0
          : (A2 * k21 + A3 * k31 - A1s.last * (k10 + k12 + k13)) *
          pump.time_step /
              60;

      double? inf;
      double? pump_inf;
      double? A1;

      if (model.depth == Target.Effect_Site) {
        A1 = step == 0
            ? 0
            : (pump_infs.last / 60) * pump.time_step / 60 + A1_change + A1s.last;

        inf = 3600 * (operation.depth * V1 - A1_change - A1) / pump.time_step;

        pump_inf = (concentration_effect > operation.depth
            ? 0.0
            : (overshoot_time > 0.0 ? max_infusion : (inf < 0.0 ? 0.0 : inf)));
      } else {
        inf = step == 0
            ? 0
            : 3600 * (operation.depth * V1 - A1_change - A1s.last) / pump.time_step;

        pump_inf = (step == 0
            ? inf
            : (inf > max_infusion ? max_infusion : (inf < 0 ? 0 : inf)));

        A1 = step == 0
            ? 0
            : (pump_inf / 60) * pump.time_step / 60 + A1_change + A1s.last;
      }

      double concentration = A1 / V1;

      double cumulative_infused_volume = step == 0
          ? pump_inf * pump.time_step / 3600 / pump.dilution
          : cumulative_infused_volumes.last +
              pump_inf * pump.time_step / 3600 / pump.dilution;

      times.add(Duration(seconds: time));
      steps.add(step);
      depths.add(operation.depth);
      overshoot_times.add(overshoot_time);
      infs.add(inf);
      pump_infs.add(pump_inf);
      A1_changes.add(A1_change);
      A1s.add(A1);
      A2s.add(A2);
      A3s.add(A3);
      concentrations.add(concentration);
      concentrations_effect.add(concentration_effect);
      cumulative_infused_volumes.add(cumulative_infused_volume);

      // print(
      //     '$time | ${operation.depth} | ${pump.time_step} | $overshoot_time | $inf | $pump_inf | $A1_change | $A1 | $A2 | $A3 | ${Duration(seconds: time)} | $concentration | $concentration_effect | $cumulative_infused_volume');
      step = step + 1;
    }

    return ({
      'times': times,
      'pump_infs': pump_infs,
      'concentrations': concentrations,
      'concentrations_effect': concentrations_effect,
      'cumulative_infused_volumes': cumulative_infused_volumes
    });
  }
}
