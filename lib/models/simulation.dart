import 'package:flutter/foundation.dart';
import 'package:propofol_dreams_app/constants.dart';
import 'dart:math';

class Simulation {
  Model model;
  int weight;
  int height;
  int age;
  Gender gender;
  int refresh_rate;

  Simulation(
      {required this.model,
      required this.weight,
      required this.height,
      required this.age,
      required this.gender,
      this.refresh_rate = 10});

  Simulation.marsh(
      {this.model = Model.Marsh,
      required this.weight,
      this.height = 0,
      this.age = 0,
      this.gender = Gender.Female,
      this.refresh_rate = 10});

  Simulation.schnider(
      {this.model = Model.Schnider,
      required this.weight,
      required this.height,
      required this.age,
      required this.gender,
      this.refresh_rate = 10});

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
      k10 = 0.1527 * pow(weight, -0.3); // per min;
      k12 = 0.114; // per min
      k13 = 0.0419; // per min
      k21 = 0.055; // per min
      k31 = 0.0033; // per min
      ke0 = 0.26; // per min

      V1 = 0.4584 * weight;
      V2 = V1 * k12 / k21;
      V3 = V1 * k13 / k31;

      if (age == 13) {
        k10 = 0.0678; // per min

        V1 = 0.4 * weight;
        V2 = V1 * k12 / k21;
        V3 = V1 * k13 / k31;
      } else if (age == 14) {
        k10 = 0.0792; // per min

        V1 = 0.342 * weight;
        V2 = V1 * k12 / k21;
        V3 = V1 * k13 / k31;
      } else if (age == 15) {
        k10 = 0.0954; // per min

        V1 = 0.284 * weight;
        V2 = V1 * k12 / k21;
        V3 = V1 * k13 / k31;
      } else if (age == 16) {
        k10 = 0.119; // per min

        V1 = 0.22857 * weight;
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

      V1 = 0.41 * weight;
      V2 = 0.78 * weight + 3.1 * age;
      V3 = 6.9 * weight;
    } else if (model == Model.Marsh) {
      k10 = 0.119; // per min
      k12 = 0.112; // per min
      k13 = 0.042; // per min
      k21 = 0.055; // per min
      k31 = 0.0033; // per min
      ke0 = 1.2; // per min

      V1 = 0.228 * weight;
      V2 = 0.463 * weight;
      V3 = 2.893 * weight;
    } else if (model == Model.Schnider) {
      V1 = 4.27; //litre
      V2 = 18.9 - 0.391 * (age - 53); //litre
      V3 = 238.0; //litre

      k10 = (0.443 +
          0.0107 * (weight - 77) -
          0.0159 * (lbm - 59) +
          0.0062 * (height - 177)); // per min

      k12 = (0.302 - 0.0056 * (age - 53)); // per min
      k13 = 0.196; // per min
      k21 =
          (1.29 - 0.024 * (age - 53)) / (18.9 - 0.391 * (age - 53)); // per min
      k31 = 0.0035; // per min
      ke0 = 0.456; // per min
      // t_half_keo = np.log(2) / (ke0 * steps_per_min) //deprecated

    }
    double Cl1 = k10 * V1; //litre / steps per min
    double Cl2 = k21 * V2; //litre / steps per min
    double Cl3 = k31 * V3; //litre / steps per min

    if (model == Model.Eleveld) {
      bool opioid = true; // arbitralily set YES to intraop opioids

      //Below is the SimTIVA's version
      // V1 = 6.28 * central(weight) / central(70);
      // V2 = 25.5 * weight / 70 * ageing(-0.0156, age);
      // double V2ref = 25.5;
      // double V3ref = 273; //Note from simTIVAjust use this from the table
      // double ffmref = (0.88 + (1 - 0.88) / (1 + pow((35 / 13.4), -12.7))) *
      //     ((9270 * 70) / (6680 + 216 * 24.22145));
      // if (opioid == true) {
      //   V3 = 273 *
      //       ffm(weight, height, age, gender) /
      //       ffmref *
      //       exp(-0.0138 * age);
      // } else {
      //   V3 = 273 * ffm(weight, height, age, gender) / ffmref;
      // }
      // if (gender == Gender.Male) {
      //   Cl1 = 1.79 *
      //       pow((weight / 70), 0.75) *
      //       (clmaturation(pma) / clmaturation(35 * year_to_weeks + 40)) *
      //       exp(-0.00286 * age) /
      //       steps_per_min;
      // } else {
      //   Cl1 = 2.1 *
      //       pow((weight / 70), 0.75) *
      //       (clmaturation(pma) / clmaturation(35 * year_to_weeks + 40)) *
      //       exp(-0.00286 * age) /
      //       steps_per_min;
      // }
      // Cl2 = 1.75 *
      //     pow((V2 / V2ref), 0.75) *
      //     (1 + 1.3 * (1 - q3maturation(age * year_to_weeks))) /
      //     steps_per_min;
      // Cl3 = 1.11 *
      //     pow((V3 / V3ref), 0.75) *
      //     (q3maturation(age * year_to_weeks) /
      //         q3maturation(35 * year_to_weeks)) /
      //     steps_per_min;

      V1 = 6.28 * (weight / (weight + 33.6)) / (0.675675675676);
      V2 = 25.5 * (weight / 70) * exp(-0.0156 * (age - 35));

      V3 = 273 * ffm * (opioid ? exp(-0.0138 * age) : 1) / 54.4752059601377;

      Cl1 = ((gender == Gender.Male ? 1.79 : 2.1) *
              (pow((weight / 70), 0.75)) *
              (pow(pma, 9.06)) /
              (pow(pma, 9.06) + pow(42.3, 9.06))) *
          (opioid ? exp(-0.00286 * age) : 1);

      Cl2 = 1.75 *
          (pow(((25.5 * (weight / 70) * exp(-0.0156 * (age - 35))) / 25.5),
              0.75)) *
          (1 + 1.3 * (1 - pma / (pma + 68.3)));

      Cl3 = 1.11 *
          (pow((ffm * (opioid ? exp(-0.0138 * age) : 1) / 54.4752059601377),
              0.75)) *
          (pma / (pma + 68.3) / 0.964695544);

      k10 = Cl1 / V1;
      k12 = Cl2 / V1;
      k13 = Cl3 / V1;
      k21 = Cl2 / V2;
      k31 = Cl3 / V3;
      ke0 = 0.146 * pow((weight / 70), -0.25);
    }

    double ce50 = 3.08 * exp(-0.00635 * (age - 35));
    double baseline_BIS = 93;
    double delay_BIS = 15 + exp(0.0517 * (age - 35));

    double a0 = k10 * k21 * k31;
    double a1 = k10 * k31 + k21 * k31 + k21 * k13 + k10 * k21 + k31 * k12;
    double a2 = k10 + k12 + k13 + k21 + k31;

    double p = a1 - (a2 * a2 / 3);
    double q = (2 * a2 * a2 * a2 / 27) - (a1 * a2 / 3) + a0;

    double r1 = sqrt(-(p * p * p) / 27);
    double r2 = 2 * pow(e, (log(r1) / 3)).toDouble();
    double phi = acos((-q / 2) / r1) / 3;

    double root1 = -(cos(phi) * r2 - a2 / 3);
    double root2 = -(cos(phi + 2 * pi / 3) * r2 - a2 / 3);
    double root3 = -(cos(phi + 4 * pi / 3) * r2 - a2 / 3);

    List<double> arr = <double>[root1, root2, root3];
    arr.sort();

    double lambda1, lambda2, lambda3, l1, l2, l3;
    lambda1 = l1 = arr[2];
    lambda2 = l2 = arr[1];
    lambda3 = l3 = arr[0];

    double A1, A2, A3, C1, C2, C3;
    A1 = C1 = (k21 - l1) * (k31 - l1) / (l1 - l2) / (l1 - l3) / V1;
    A2 = C2 = (k21 - l2) * (k31 - l2) / (l2 - l1) / (l2 - l3) / V1;
    A3 = C3 = (k21 - l3) * (k31 - l3) / (l3 - l2) / (l3 - l1) / V1;

    double CoefCe1 = (-ke0 * A1) / (l1 - ke0);
    double CoefCe2 = (-ke0 * A2) / (l2 - ke0);
    double CoefCe3 = (-ke0 * A3) / (l3 - ke0);
    double CoefCe4 = -(CoefCe1 + CoefCe2 + CoefCe3);

    double udf = A1 + A2 + A3;

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
      'a0': a0,
      'a1': a1,
      'a2': a2,
      'p': p,
      'q': q,
      'r1': r1,
      'r2': r2,
      'l1': l1,
      'l2': l2,
      'l3': l3,
      'A1': A1,
      'A2': A2,
      'A3': A3,
      'CoefCe1': CoefCe1,
      'CoefCe2': CoefCe2,
      'CoefCe3': CoefCe3,
      'CoefCe4': CoefCe4,
      'Cl1': Cl1,
      'Cl2': Cl2,
      'Cl3': Cl3,
      'ce50': ce50,
      'baseline_BIS': baseline_BIS,
      'delay_BIS': delay_BIS,
      'udf': udf
    };
  }

  Map<String, dynamic> simulate(
      {required double depth,
      required int duration,
      int propofol_density = 10,
      bool verbose = false}) {
    // Configure Temporal Variables
    int duration_in_secs = duration * 60; //in seconds
    int steps_per_min =
        (60 / refresh_rate).toInt(); //number of steps in one minute

    // Unpack model variables
    double CoefCe1 = variables['CoefCe1'] as double;
    double CoefCe2 = variables['CoefCe2'] as double;
    double CoefCe3 = variables['CoefCe3'] as double;
    double CoefCe4 = variables['CoefCe4'] as double;
    double l1 = variables['l1'] as double;
    double l2 = variables['l2'] as double;
    double l3 = variables['l3'] as double;
    double ke0 = variables['ke0'] as double;
    double udf = variables['udf'] as double;
    double A1 = variables['A1'] as double;
    double A2 = variables['A2'] as double;
    double A3 = variables['A3'] as double;

    // Initiate Empty Variables for the Iterative Process
    double bolus = 0.0;
    double infusion = 0.0;

    double Cp_target = depth;
    double Ce_target = depth;
    List<double> Ce_states = [0.0, 0.0, 0.0, 0.0];
    List<double> Cp_comp = [0.0, 0.0, 0.0];
    List<double> Cp_trail = [0.0, 0.0, 0.0];

    double Cp = 0.0;
    double Ce = 0.0;
    double udf_delta = 0.0;
    int step_delta = 0;

    List<int> steps = [];
    List<double> durations = [];
    List<Duration> times = [];
    List<int> step_deltas = [];
    List<double> bolus_volumes = [];
    List<double> infusion_volumes = [];
    List<double> CPs = [];
    List<double> CEs = [];
    List<double> bolus_accumulated_volumes = [];
    List<double> infusion_accumulated_volumes = [];

    //Commence Iterative Calculation, step_current = 0 is when the initial bolus is applied
    for (int d = 0; d < duration_in_secs + refresh_rate; d += refresh_rate) {
      //Setup Temporal configuration
      int step_current = (d / refresh_rate).toInt();
      double duration_current = d / 60;
      Duration time = Duration(seconds: d.toInt());

      //Calculate bolus
      if (step_current == 0) {
        if (model == Model.Paedfusor || model == Model.Kataria) {
          double estimatedBolus =
              (0.2197 * pow(Cp_target, 2) + 15.693 * Cp_target) / 70 * weight;
          if (weight < 15) {
            bolus = min(estimatedBolus, 3);
          } else if (weight < 30) {
            bolus = min(estimatedBolus, 6);
          } else {
            bolus = min(estimatedBolus, 12);
          }
        } else if (model == Model.Marsh) {
          bolus =
              (0.2197 * pow(Cp_target, 2) + 15.693 * Cp_target) / 70 * weight;
        } else if (model == Model.Schnider || model == Model.Eleveld) {
          double peakCe = cacl_peak_Ce['peak_Ce'] as double;
          // print(peakCe);
          bolus = Ce_target / peakCe;
        }
        step_delta = 0;
      } else {
        bolus = 0.0;
        step_delta = 1;
      }
      if (verbose && kDebugMode) {
        // print('bolus ${bolus}');
      }

      //calculate infusion
      Cp_trail[0] = Cp_comp[0] * pow(e, (-l1 * step_delta));
      Cp_trail[1] = Cp_comp[1] * pow(e, (-l2 * step_delta));
      Cp_trail[2] = Cp_comp[2] * pow(e, (-l3 * step_delta));

      udf_delta =
          max((Cp_target - Cp_trail.reduce((a, b) => a + b)) / udf, 0.0);
      if (step_current == 0) {
        infusion = 0.0;
      } else {
        infusion = udf_delta;
      }

      Cp_comp[0] = bolus * A1 +
          Cp_comp[0] * pow(e, (-l1 * step_delta)) +
          (infusion * (A1 / l1) * (1 - pow(e, (-l1 * step_delta))));
      Cp_comp[1] = bolus * A2 +
          Cp_comp[1] * pow(e, (-l2 * step_delta)) +
          (infusion * (A2 / l2) * (1 - pow(e, (-l2 * step_delta))));
      Cp_comp[2] = bolus * A3 +
          Cp_comp[2] * pow(e, (-l3 * step_delta)) +
          (infusion * (A3 / l3) * (1 - pow(e, (-l3 * step_delta))));
      Cp = Cp_comp.reduce((a, b) => a + b);

      //Avoid Calcuate Ce for Marsh & Paedfusor model
      if (model != Model.Marsh && model != Model.Paedfusor) {
        Ce_states[0] = bolus * CoefCe1 +
            Ce_states[0] * pow(e, (-l1 * step_delta)) +
            infusion * (CoefCe1 / l1) * (1 - pow(e, (-l1 * step_delta)));
        Ce_states[1] = bolus * CoefCe2 +
            Ce_states[1] * pow(e, (-l2 * step_delta)) +
            infusion * (CoefCe2 / l2) * (1 - pow(e, (-l2 * step_delta)));
        Ce_states[2] = bolus * CoefCe3 +
            Ce_states[2] * pow(e, (-l3 * step_delta)) +
            infusion * (CoefCe3 / l3) * (1 - pow(e, (-l3 * step_delta)));
        Ce_states[3] = bolus * CoefCe4 +
            Ce_states[3] * pow(e, (-ke0 * step_delta)) +
            infusion * (CoefCe4 / ke0) * (1 - pow(e, (-ke0 * step_delta)));

        Ce = Ce_states.reduce((a, b) => a + b);
      }
      steps.add(step_current);
      durations.add(duration_current);
      times.add(time);
      step_deltas.add(step_delta);
      bolus_volumes.add(bolus);
      infusion_volumes.add(infusion);
      CPs.add(Cp);
      CEs.add(Ce);
    }

    bolus_accumulated_volumes = cum_sum(bolus_volumes);
    infusion_accumulated_volumes = cum_sum(infusion_volumes);

    List<double> accumulated_volumes = [];
    for (int i = 0; i < bolus_accumulated_volumes.length; i++) {
      accumulated_volumes
          .add(bolus_accumulated_volumes[i] + infusion_accumulated_volumes[i]);
    }

    accumulated_volumes = [
      ...accumulated_volumes.map((volume) => volume / propofol_density)
    ];

    return ({
      'steps': steps,
      'times': times,
      'bolus_volumes': bolus_volumes,
      'CPs': CPs,
      'CEs': CEs,
      'accumulated_volumes': accumulated_volumes
    });
  }

  List<double> cum_sum(List<double> l) {
    double cum_sum = 0;
    List<double> cum_sums = [];
    l.forEach((i) {
      cum_sum += i;
      cum_sums.add(cum_sum);
    });
    return cum_sums;
  }

  //Deprecated
  Map<String, double> get cacl_peak_Ce {
    //Unpack model variables
    //1 second refresh rate for calculating Peak Ce to achieve the most accurate result
    double CoefCe1 = (variables['CoefCe1'] as double) / refresh_rate;
    double CoefCe2 = (variables['CoefCe2'] as double) / refresh_rate;
    double CoefCe3 = (variables['CoefCe3'] as double) / refresh_rate;
    double CoefCe4 = (variables['CoefCe4'] as double) / refresh_rate;
    double l1 = (variables['l1'] as double) / refresh_rate;
    double l2 = (variables['l2'] as double) / refresh_rate;
    double l3 = (variables['l3'] as double) / refresh_rate;
    double ke0 = (variables['ke0'] as double) / refresh_rate;

    //Calculate Peak Ce with 1 mcg bolus, 0 mcg infusion
    double bolus = 1.0; //mcg
    double infusion = 0.0; //mcg
    int step_delta = 1;
    List<double> Ce_states = [
      bolus * CoefCe1,
      bolus * CoefCe2,
      bolus * CoefCe3,
      bolus * CoefCe4
    ];
    List<double> Ce = [0.0];

    while ((Ce.length <= 2) || (Ce[Ce.length - 2] < Ce[Ce.length - 1])) {
      bolus = 0.0;
      Ce_states[0] = bolus * CoefCe1 +
          Ce_states[0] * pow(e, (-l1 * step_delta)) +
          infusion * (CoefCe1 / l1) * (1 - pow(e, (-l1 * step_delta)));
      Ce_states[1] = bolus * CoefCe2 +
          Ce_states[1] * pow(e, (-l2 * step_delta)) +
          infusion * (CoefCe2 / l2) * (1 - pow(e, (-l2 * step_delta)));
      Ce_states[2] = bolus * CoefCe3 +
          Ce_states[2] * pow(e, (-l3 * step_delta)) +
          infusion * (CoefCe3 / l3) * (1 - pow(e, (-l3 * step_delta)));
      Ce_states[3] = bolus * CoefCe4 +
          Ce_states[3] * pow(e, (-ke0 * step_delta)) +
          infusion * (CoefCe4 / ke0) * (1 - pow(e, (-ke0 * step_delta)));

      Ce.add(Ce_states.reduce((a, b) => a + b));
    }

    double peak_Ce = Ce[Ce.length - 2] * refresh_rate;
    double peak_TTPE = ((Ce.length - 2)).toDouble();

    return {'peak_Ce': peak_Ce, 'peak_TTPE': peak_TTPE};
  }

  double get lbm {
    if (gender == Gender.Female) {
      return 1.07 * weight - 148 * pow((weight / height), 2);
    } else if (gender == Gender.Male) {
      return 1.1 * weight - 128 * pow((weight / height), 2);
    }
    return 0.0;
  }

  // double sigmoid(x, y, z) {
  //   return pow(x, z) / (pow(x, z) + pow(y, z));
  // }
  //
  // double central(x) {
  //   return sigmoid(x, 33.6, 1);
  // }
  //
  // double ageing(x, age) {
  //   return exp(x * (age - 35));
  // }
  //
  // double clmaturation(x) {
  //   return sigmoid(x, 42.3, 9.06);
  // }

  //Note from simTIVA: age already converted to weeks
  // double q3maturation(x) {
  //   return sigmoid(x + 40, 68.3, 1);
  // }

  double get bmi {
    return (weight / pow((height / 100), 2));
  }

  //fat-free mass
  double get ffm {
    double b = bmi;
    if (gender == Gender.Male) {
      return (0.88 + (1 - 0.88) / (1 + pow((age / 13.4), -12.7))) *
          ((9270 * weight) / (6680 + 216 * b));
    } else {
      return (1.11 + (1 - 1.11) / (1 + pow((age / 7.1), -1.1))) *
          ((9270 * weight) / (8780 + 244 * b));
    }
  }

  //arbitrarily set pma 40 weeks +age
  double get pma {
    return age * 52.143 + 40;
  }

  double get calibrated_effect {
    int time_step = 1; //sec
    int duration = 720;

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
    List<int> pump_infs = [];
    List<double> concentrations = [];
    List<double> concentrations_effect = [];

    for (int time = 0; time <= duration; time += time_step) {
      int pump_inf = time < 100 ? max_infusion : 0;

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

      // print('$time | $pump_inf | $A1 | $A2 | $A3 | ${Duration(seconds: time)} | $concentration | $concentration_effect');
      step = step + 1;
    }
    return concentrations_effect.reduce(max);
  }

  // int get max_infusion {
  //   return dilution * max_pump_rate;
  // }

  Map<String, dynamic> estimate(
      {required double target,
      required int duration,
      int dilution = 10,
      int max_pump_rate = 1200,
      int time_step = 5}) {
    double max_infusion = (dilution * max_pump_rate).toDouble(); // mg per hr

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
    List<double> targets = [];
    List<double> overshoot_times = [];
    List<double> infs = []; //mg per hr
    List<double> A1_changes = [];
    List<double> cumulative_infused_volumes = []; // mL

    for (int time = 0; time <= duration * 60; time += time_step) {
      double A2 = step == 0
          ? 0
          : A2s.last + (k12 * A1s.last - k21 * A2s.last) * time_step / 60;

      double A3 = step == 0
          ? 0
          : A3s.last + (k13 * A1s.last - k31 * A3s.last) * time_step / 60;

      double concentration_effect = step == 0
          ? 0
          : concentrations_effect.last +
              ke0 *
                  (concentrations.last - concentrations_effect.last) *
                  time_step /
                  60;

      double overshoot_time = (step == 0
          ? target / calibrated_effect * 100 - 1
          : (target - targets.last > 0
              ? (target - targets.last) / calibrated_effect * 100 - 1
              : overshoot_times.last - time_step));

      double A1_change = step == 0
          ? 0
          : (A2 * k21 + A3 * k31 - A1s.last * (k10 + k12 + k13)) *
              time_step /
              60;

      double? inf;
      double? pump_inf;
      double? A1;

      if (model.target == Target.EffectSite) {
        A1 = step == 0
            ? 0
            : (pump_infs.last / 60) * time_step / 60 + A1_change + A1s.last;

        inf = step == 0 ? 0 : 3600 * (target * V1 - A1_change - A1) / time_step;

        pump_inf = (concentration_effect > target
            ? 0.0
            : (overshoot_time > 0.0 ? max_infusion : (inf < 0.0 ? 0.0 : inf)));
      } else {
        inf = step == 0
            ? 0
            : 3600 * (target * V1 - A1_change - A1s.last) / time_step;

        pump_inf = (step == 0
            ? inf
            : (inf > max_infusion ? max_infusion : (inf < 0 ? 0 : inf)));

        A1 = step == 0
            ? 0
            : (pump_inf / 60) * time_step / 60 + A1_change + A1s.last;
      }

      double concentration = A1 / V1;

      double cumulative_infused_volume = step == 0
          ? pump_inf * time_step / 3600 / dilution
          : cumulative_infused_volumes.last +
              pump_inf * time_step / 3600 / dilution;

      times.add(Duration(seconds: time));
      steps.add(step);
      targets.add(target);
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

      print(
          '$time | $target | $time_step | $overshoot_time | $inf | $pump_inf | $A1_change | $A1 | $A2 | $A3 | ${Duration(seconds: time)} | $concentration | $concentration_effect | $cumulative_infused_volume');
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
