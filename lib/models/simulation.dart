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
    if (model == Model.Paedfusor) {
      double steps_per_min = 60 / refresh_rate; //number of steps in one minute

      double k10 = 0.1527 * pow(weight, -0.3) / steps_per_min;
      double k12 = 0.114 / steps_per_min;
      double k13 = 0.0419 / steps_per_min;
      double k21 = 0.055 / steps_per_min;
      double k31 = 0.0033 / steps_per_min;
      double ke0 = 0.26 / steps_per_min;

      double V1 = 0.4584 * weight;
      double V2 = V1 * k12 / k21;
      double V3 = V1 * k13 / k31;

      if (age == 13) {
        k10 = 0.0678 / steps_per_min;

        V1 = 0.4 * weight;
        V2 = V1 * k12 / k21;
        V3 = V1 * k13 / k31;
      } else if (age == 14) {
        k10 = 0.0792 / steps_per_min;

        V1 = 0.342 * weight;
        V2 = V1 * k12 / k21;
        V3 = V1 * k13 / k31;
      } else if (age == 15) {
        k10 = 0.0954 / steps_per_min;

        V1 = 0.284 * weight;
        V2 = V1 * k12 / k21;
        V3 = V1 * k13 / k31;
      } else if (age == 16) {
        k10 = 0.119 / steps_per_min;

        V1 = 0.22857 * weight;
        V2 = V1 * k12 / k21;
        V3 = V1 * k13 / k31;
      }

      double Cl1 = k10 * V1;
      double Cl2 = k21 * V2;
      double Cl3 = k31 * V3;

      double a0 = k10 * k21 * k31;
      double a1 = k10 * k31 + k21 * k31 + k21 * k13 + k10 * k21 + k31 * k12;
      double a2 = k10 + k12 + k13 + k21 + k31;

      double p = a1 - (a2 * a2 / 3);
      double q = (2 * a2 * a2 * a2 / 27) - (a1 * a2 / 3) + a0;

      double r1 = sqrt(-(p * p * p) / 27);
      double phi = acos((-q / 2) / r1) / 3;
      double r2 = 2 * pow(e, (log(r1) / 3)) as double;

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
        'udf': udf
      };
    } else if (model == Model.Kataria) {
      double steps_per_min = 60 / refresh_rate; //number of steps in one minute

      double k10 = 0.085 / steps_per_min;
      double k12 = 0.188 / steps_per_min;
      double k13 = 0.063 / steps_per_min;
      double k21 = 0.102 / steps_per_min;
      double k31 = 0.0038 / steps_per_min;
      double ke0 = 0 / steps_per_min;

      double V1 = 0.41 * weight;
      double V2 = 0.78 * weight + 3.1 * age;
      double V3 = 6.9 * weight;

      double Cl1 = k10 * V1;
      double Cl2 = k21 * V2;
      double Cl3 = k31 * V3;

      double a0 = k10 * k21 * k31;
      double a1 = k10 * k31 + k21 * k31 + k21 * k13 + k10 * k21 + k31 * k12;
      double a2 = k10 + k12 + k13 + k21 + k31;

      double p = a1 - (a2 * a2 / 3);
      double q = (2 * a2 * a2 * a2 / 27) - (a1 * a2 / 3) + a0;

      double r1 = sqrt(-(p * p * p) / 27);
      double phi = acos((-q / 2) / r1) / 3;
      double r2 = 2 * pow(e, (log(r1) / 3)) as double;

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
        'udf': udf
      };
    } else if (model == Model.Marsh) {
      double steps_per_min = 60 / refresh_rate; //number of steps in one minute

      double k10 = 0.119 / steps_per_min;
      double k12 = 0.112 / steps_per_min;
      double k13 = 0.042 / steps_per_min;
      double k21 = 0.055 / steps_per_min;
      double k31 = 0.0033 / steps_per_min;
      double ke0 = 1.2 / steps_per_min;

      double V1 = 0.228 * weight;
      double V2 = 0.463 * weight;
      double V3 = 2.893 * weight;

      double Cl1 = k10 * V1;
      double Cl2 = k21 * V2;
      double Cl3 = k31 * V3;

      double a0 = k10 * k21 * k31;
      double a1 = k10 * k31 + k21 * k31 + k21 * k13 + k10 * k21 + k31 * k12;
      double a2 = k10 + k12 + k13 + k21 + k31;

      double p = a1 - (a2 * a2 / 3);
      double q = (2 * a2 * a2 * a2 / 27) - (a1 * a2 / 3) + a0;

      double r1 = sqrt(-(p * p * p) / 27);
      double phi = acos((-q / 2) / r1) / 3;
      double r2 = 2 * pow(e, (log(r1) / 3)) as double;

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
        'udf': udf
      };
    } else if (model == Model.Schnider) {
      // Configure Temporal Variables
      int steps_per_min =
          (60 / refresh_rate).toInt(); //number of steps in one minute

      double lbm = calc_LBM;

      //Calculate Model Variables
      double V1 = 4.27; //litre
      double V2 = 18.9 - 0.391 * (age - 53); //litre
      double V3 = 238.0; //litre

      double k10 = (0.443 +
              0.0107 * (weight - 77) -
              0.0159 * (lbm - 59) +
              0.0062 * (height - 177)) /
          steps_per_min;

      double k12 = (0.302 - 0.0056 * (age - 53)) / steps_per_min;
      double k13 = 0.196 / steps_per_min;
      double k21 = (1.29 - 0.024 * (age - 53)) /
          (18.9 - 0.391 * (age - 53)) /
          steps_per_min;
      double k31 = 0.0035 / steps_per_min;
      double ke0 = 0.456 / steps_per_min;
      // t_half_keo = np.log(2) / (ke0 * steps_per_min) //deprecated

      double Cl1 = k10 * V1; //litre / steps per min
      double Cl2 = k21 * V2; //litre / steps per min
      double Cl3 = k31 * V3; //litre / steps per min

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
        'udf': udf
      };
    } else if (model == Model.Eleveld) {
      // Configure Temporal Variables
      int steps_per_min =
      (60 / refresh_rate).toInt(); //number of steps in one minute

      double lbm = calc_LBM;

      //Calculate Model Variables
      double V1 = 4.27; //litre
      double V2 = 18.9 - 0.391 * (age - 53); //litre
      double V3 = 238.0; //litre

      double k10 = (0.443 +
          0.0107 * (weight - 77) -
          0.0159 * (lbm - 59) +
          0.0062 * (height - 177)) /
          steps_per_min;

      double k12 = (0.302 - 0.0056 * (age - 53)) / steps_per_min;
      double k13 = 0.196 / steps_per_min;
      double k21 = (1.29 - 0.024 * (age - 53)) /
          (18.9 - 0.391 * (age - 53)) /
          steps_per_min;
      double k31 = 0.0035 / steps_per_min;
      double ke0 = 0.456 / steps_per_min;
      // t_half_keo = np.log(2) / (ke0 * steps_per_min) //deprecated

      double Cl1 = k10 * V1; //litre / steps per min
      double Cl2 = k21 * V2; //litre / steps per min
      double Cl3 = k31 * V3; //litre / steps per min

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
        'udf': udf
      };
    }

    else {
      return {'error': 404};
    }
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

  double get calc_LBM {
    if (gender == Gender.Female) {
      return 1.07 * weight - 148 * pow((weight / height), 2);
    } else if (gender == Gender.Male) {
      return 1.1 * weight - 128 * pow((weight / height), 2);
    }
    return 0.0;
  }
}
