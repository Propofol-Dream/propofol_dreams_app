import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:propofol_dreams_app/models/calculator.dart';
import 'package:propofol_dreams_app/models/elemarsh.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:propofol_dreams_app/models/simulation.dart' as PDSim;
import 'package:propofol_dreams_app/providers/settings.dart';
import 'package:propofol_dreams_app/models/patient.dart';
import 'package:propofol_dreams_app/models/pump.dart';
import 'package:propofol_dreams_app/models/model.dart';
import 'package:propofol_dreams_app/models/sex.dart';

import 'package:propofol_dreams_app/controllers/PDSwitchController.dart';
import 'package:propofol_dreams_app/controllers/PDSwitchField.dart';
import 'package:propofol_dreams_app/controllers/PDTextField.dart';

import 'package:propofol_dreams_app/controllers/PDSegmentedController.dart';
import 'package:propofol_dreams_app/controllers/PDSegmentedControl.dart';

import '../constants.dart';

class EleMarshScreen extends StatefulWidget {
  EleMarshScreen({Key? key}) : super(key: key);

  @override
  State<EleMarshScreen> createState() => _EleMarshScreenState();
}

class _EleMarshScreenState extends State<EleMarshScreen> {
  PDSwitchController sexController = PDSwitchController();
  TextEditingController ageController = TextEditingController();
  TextEditingController heightController = TextEditingController();
  TextEditingController weightController = TextEditingController();
  TextEditingController targetController = TextEditingController();

  final PDSegmentedController flowController = PDSegmentedController();
  PDSwitchController modelController = PDSwitchController();
  TextEditingController maintenanceCeController = TextEditingController();
  TextEditingController maintenanceSEController = TextEditingController();
  TextEditingController infusionRateController = TextEditingController();

  //Displays
  String weightBestGuess = "--";
  String adjustmentBolus = "--";
  String inductionCPTarget = "--";
  String BMI = "--";
  String predictedBIS = "--";
  String range = "--";

  @override
  void initState() {
    final settings = context.read<Settings>();

    sexController.val = settings.EMSex == Sex.Female ? true : false;
    ageController.text = settings.EMAge.toString();
    heightController.text = settings.EMHeight.toString();
    weightController.text = settings.EMWeight.toString();
    targetController.text = settings.EMTarget.toString();

    flowController.val = settings.EMFlow == 'induce' ? 0 : 1;

    modelController.val =
        settings.EMWakeUpModel == Model.Eleveld ? true : false;
    maintenanceCeController.text = settings.EMMaintenanceCe.toString();
    maintenanceSEController.text = settings.EMMaintenanceSE.toString();
    infusionRateController.text = settings.EMInfusionRate.toString();

    load();

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> load() async {
    var pref = await SharedPreferences.getInstance();
    final settings = context.read<Settings>();

    if (pref.containsKey('density')) {
      settings.density = pref.getInt('density')!;
    } else {
      settings.density = 10;
    }

    if (pref.containsKey('EMSex')) {
      String sex = pref.getString('EMSex')!;
      settings.EMSex = sex == 'Female' ? Sex.Female : Sex.Male;
    } else {
      settings.EMSex = Sex.Female;
    }

    if (pref.containsKey('EMAge')) {
      settings.EMAge = pref.getInt('EMAge');
    } else {
      settings.EMAge = 40;
    }

    if (pref.containsKey('EMHeight')) {
      settings.EMHeight = pref.getInt('EMHeight');
    } else {
      settings.EMHeight = 170;
    }

    if (pref.containsKey('EMWeight')) {
      settings.EMWeight = pref.getInt('EMWeight');
    } else {
      settings.EMWeight = 70;
    }

    if (pref.containsKey('EMTarget')) {
      settings.EMTarget = pref.getDouble('EMTarget');
    } else {
      settings.EMTarget = 3.0;
    }

    if (pref.containsKey('EMDuration')) {
      settings.EMDuration = pref.getInt('EMDuration');
    } else {
      settings.EMDuration = 60;
    }

    if (pref.containsKey('EMFlow')) {
      settings.EMFlow = pref.getString('EMFlow')!;
    } else {
      settings.EMFlow = 'induce';
    }

    if (pref.containsKey('EMWakeUpModel')) {
      String model = pref.getString('EMWakeUpModel')!;
      settings.EMWakeUpModel =
          model == 'Eleveld' ? Model.Eleveld : Model.EleMarsh;
    } else {
      settings.EMWakeUpModel = Model.EleMarsh;
    }

    if (pref.containsKey('EMMaintenanceCe')) {
      settings.EMMaintenanceCe = pref.getDouble('EMMaintenanceCe');
    } else {
      settings.EMMaintenanceCe = 3.0;
    }

    if (pref.containsKey('EMMaintenanceSE')) {
      settings.EMMaintenanceSE = pref.getInt('EMMaintenanceSE');
    } else {
      settings.EMMaintenanceSE = 40;
    }

    if (pref.containsKey('EMInfusionRate')) {
      settings.EMInfusionRate = pref.getDouble('EMInfusionRate');
    } else {
      settings.EMInfusionRate = 100;
    }

    sexController.val = settings.EMSex == Sex.Female ? true : false;
    ageController.text = settings.EMAge.toString();
    heightController.text = settings.EMHeight.toString();
    weightController.text = settings.EMWeight.toString();
    targetController.text = settings.EMTarget.toString();

    flowController.val = settings.EMFlow == 'induce' ? 0 : 1;
    modelController.val =
        settings.EMWakeUpModel == Model.Eleveld ? true : false;
    maintenanceCeController.text = settings.EMMaintenanceCe.toString();
    maintenanceSEController.text = settings.EMMaintenanceSE.toString();
    infusionRateController.text = settings.EMInfusionRate.toString();
    run(initState: true);
  }

  void updatePDTextEditingController() {
    // final settings = Provider.of<Settings>(context, listen: false);
    run();
  }

  run({initState = false}) async {
    final settings = Provider.of<Settings>(context, listen: false);

    int? age = int.tryParse(ageController.text);
    int? height = int.tryParse(heightController.text);
    int? weight = int.tryParse(weightController.text);
    double? target = double.tryParse(targetController.text);
    Sex sex = sexController.val ? Sex.Female : Sex.Male;

    String flow = flowController.val == 0 ? 'induce' : 'wake';
    Model m = modelController.val ? Model.Eleveld : Model.EleMarsh;
    double? maintenanceCe = double.tryParse(maintenanceCeController.text);
    int? maintenanceSE = int.tryParse(maintenanceSEController.text);

    //Save all the settings
    if (initState == false) {
      settings.EMSex = sex;
      settings.EMAge = age;
      settings.EMHeight = height;
      settings.EMWeight = weight;
      settings.EMTarget = target;
      settings.EMFlow = flow;
      settings.EMWakeUpModel = m;
      settings.EMMaintenanceCe = maintenanceCe;
      settings.EMMaintenanceSE = maintenanceSE;
    }

    if (age != null &&
        height != null &&
        weight != null &&
        target != null &&
        m != null &&
        maintenanceCe != null &&
        maintenanceSE != null) {

      switch (age) {
        case 5:
          minWeightEleMarsh = 20;
          maxWeightEleMarsh = 40;
          minHeightEleMarsh = 85;
          maxHeightEleMarsh = 132;
        case 6:
          minWeightEleMarsh = 20;
          maxWeightEleMarsh = 55;
          minHeightEleMarsh = 85;
          maxHeightEleMarsh = 140;
        case 7:
          minWeightEleMarsh = 20;
          maxWeightEleMarsh = 75;
          minHeightEleMarsh = 85;
          maxHeightEleMarsh = 148;
        case 8:
          minWeightEleMarsh = 20;
          maxWeightEleMarsh = 90;
          minHeightEleMarsh = 85;
          maxHeightEleMarsh = 156;
        case 9:
          minWeightEleMarsh = 20;
          maxWeightEleMarsh = 110;
          minHeightEleMarsh = 85;
          maxHeightEleMarsh = 165;
        case 10:
          minWeightEleMarsh = 20;
          maxWeightEleMarsh = 140;
          minHeightEleMarsh = 85;
          maxHeightEleMarsh = 170;
        case >= 11 && <= 13:
          minWeightEleMarsh = 20;
          maxWeightEleMarsh = 200;
          minHeightEleMarsh = 85;
          maxHeightEleMarsh = 200;
        case > 13:
          minWeightEleMarsh = 35;
          maxWeightEleMarsh = 350;
          minHeightEleMarsh = 100;
          maxHeightEleMarsh = 220;
        default:
          minWeightEleMarsh = 20;
          maxWeightEleMarsh = 350;
          minHeightEleMarsh = 85;
          maxHeightEleMarsh = 220;
      }

      if (age >= m.minAge &&
          age <= m.maxAge &&
          height >= minHeightEleMarsh &&
          height <= maxHeightEleMarsh &&
          weight >= minWeightEleMarsh &&
          weight <= maxWeightEleMarsh &&
          target >= 0.5 &&
          target <= 8.0 &&
          maintenanceCe >= 0.5 &&
          maintenanceCe <= 10 &&
          maintenanceSE >= 1 &&
          maintenanceSE <= 99) {
        DateTime start = DateTime.now();

        Model model = Model.Eleveld;
        Patient patient =
            Patient(weight: weight, height: height, age: age, sex: sex);
        Pump pump = Pump(
            timeStep: Duration(seconds: settings.time_step),
            density: settings.density,
            maxPumpRate: settings.max_pump_rate,
            target: target,
            duration: Duration(hours: 3));
        // Operation operation =
        //     Operation(target: target, duration: Duration(hours: 3));
        PDSim.Simulation simulation =
            PDSim.Simulation(model: model, patient: patient, pump: pump);

        EleMarsh elemarsh = EleMarsh(goldSimulation: simulation);

        var resultInduction = elemarsh.estimate(weightBound: 0, bolusBound: 0);

        Calculator calculator = Calculator();
        var resultWakeUp =
            calculator.calcWakeUpCE(ce: maintenanceCe, se: maintenanceSE, m: m);

        DateTime finish = DateTime.now();

        Duration calculationDuration = finish.difference(start);

        setState(() {
          weightBestGuess = resultInduction.weightBestGuess.toString();
          inductionCPTarget =
              resultInduction.inductionCPTarget.toStringAsFixed(1);
          adjustmentBolus = resultInduction.adjustmentBolus.round().toString();
          // int guessIndex = result.guessIndex;
          predictedBIS = resultInduction.predictedBIS.toStringAsFixed(0);
          // MDAPE = (result.MDAPEs[guessIndex] * 100).toStringAsFixed(1);
          BMI = patient.bmi.toStringAsFixed(1);

          String lower = resultWakeUp.lower.toStringAsFixed(2);
          String upper = resultWakeUp.upper.toStringAsFixed(2);

          range = lower + ' - ' + upper;

          print({
            'weightBestGuess': weightBestGuess,
            'adjustmentBolus': adjustmentBolus,
            'inductionCPTarget': inductionCPTarget,
            'flow': flow,
            'range': range,
            'calculation time':
                '${calculationDuration.inMilliseconds.toString()} milliseconds'
          });
        });
      } else {
        setState(() {
          weightBestGuess = "--";
          adjustmentBolus = "--";
          inductionCPTarget = "--";
          range = "--";
        });
      }
    } else {
      setState(() {
        weightBestGuess = "--";
        adjustmentBolus = "--";
        inductionCPTarget = "--";
        range = "--";
      });
    }
  }

  void reset({bool toDefault = false}) {
    final settings = Provider.of<Settings>(context, listen: false);

    if (flowController.val == 0) {
      sexController.val = toDefault
          ? true
          : settings.EMSex == Sex.Female
              ? true
              : false;
      ageController.text = toDefault
          ? 40.toString()
          : settings.EMAge != null
              ? settings.EMAge.toString()
              : '';
      heightController.text = toDefault
          ? 170.toString()
          : settings.EMHeight != null
              ? settings.EMHeight.toString()
              : '';
      weightController.text = toDefault
          ? 70.toString()
          : settings.EMWeight != null
              ? settings.EMWeight.toString()
              : '';
      targetController.text = toDefault
          ? 3.0.toString()
          : settings.EMTarget != null
              ? settings.EMTarget.toString()
              : '';
    } else {
      modelController.val = toDefault
          ? false
          : settings.EMWakeUpModel == Model.EleMarsh
              ? false
              : true;

      maintenanceCeController.text = toDefault
          ? 3.0.toString()
          : settings.EMMaintenanceCe != null
              ? settings.EMMaintenanceCe.toString()
              : '';

      maintenanceSEController.text = toDefault
          ? 40.toString()
          : settings.EMMaintenanceSE != null
              ? settings.EMMaintenanceSE.toString()
              : '';
    }
    run();
  }

  int minWeightEleMarsh = 20;
  int maxWeightEleMarsh = 350;
  int minHeightEleMarsh = 85;
  int maxHeightEleMarsh = 220;

  @override
  Widget build(BuildContext context) {
    // print(weightBestGuess);

    final mediaQuery = MediaQuery.of(context);

    final double UIHeight = mediaQuery.size.aspectRatio >= 0.455
        ? mediaQuery.size.height >= screenBreakPoint1
            ? 56
            : 48
        : 48;
    final double UIWidth =
        (mediaQuery.size.width - 2 * (horizontalSidesPaddingPixel + 4)) / 2;

    final double rowHeight = 20 + 34 + 2 + 4;

    final double screenHeight = mediaQuery.size.height -
        (Platform.isAndroid
            ? 48
            : mediaQuery.size.height >= screenBreakPoint1
                ? 88
                : 56);

    final settings = context.watch<Settings>();

    bool isMaintenanceSEOutOfRange = ((settings.EMMaintenanceSE ?? 40) >= 21 &&
            (settings.EMMaintenanceSE ?? 40) <= 60)
        ? false
        : true;

    int density = settings.density;

    void showInduceAlertDialog(BuildContext context) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            switch (Localizations.localeOf(context).languageCode) {
              case 'ja':
                return AlertDialog(
                  title: Text('EleMarshハアルゴリズム'),
                  content: SingleChildScrollView(
                    child: Text.rich(TextSpan(children: [
                      TextSpan(text: '''目的：
MarshモデルがEleveldモデルの注入挙動を正確に模倣するようにします。

使用方法：
(1) 患者の詳細と希望するEleveld Ce（効果部位濃度）目標を入力します。

(2) EleMarshが調整体重と導入時CpTを計算します。

(3) TCIポンプのMarshモデルの入力体重として調整体重を使用します。

(4) 初期CpT設定として導入時CpTを使用します。ボーラス投与が終わり次第、維持のために希望するCeT（効果部位目標濃度）まで CpT（血漿中目標濃度）を下げます。これにより、ポンプ上のMarshモデルがEleveldモデルを正確に模倣するようになります。''')
                    ])),
                  ),
                );
              default:
                return AlertDialog(
                  title: Text('EleMarsh Algorithm'),
                  content: SingleChildScrollView(
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(
                            text: "Aim:",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: "\n"),
                        TextSpan(
                            text:
                                "Make the Marsh model accurately mimic the infusion behaviour of the Eleveld model."),
                        TextSpan(text: "\n\n"),
                        TextSpan(
                            text: "Usage:",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: "\n"),
                        TextSpan(
                            text:
                                """(1) Enter patient details and desired Eleveld Ce target

(2) EleMarsh calculates the """),
                        TextSpan(
                            text: """Adjusted Body Weight""",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: """and """),
                        TextSpan(
                            text: """Induction CpT""",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: """


(3) Use the """),
                        TextSpan(
                            text: """Adjusted Body Weight""",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(
                            text:
                                """ as the input weight for Marsh model on TCI pump

(4) Use the """),
                        TextSpan(
                            text: """Induction CpT""",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(
                          text:
                              """ as the initial CpT setting. As soon as the bolus is finished, drop CpT down to the desired CeT for maintenance. The Marsh model on your pump will now accurately mimic the Eleveld model.""",
                        ),
                        TextSpan(text: "\n\n"),
                        TextSpan(
                            text: "References:",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: "\n"),
                        TextSpan(text: """
Zhong G., Xu X. General purpose propofol target-controlled infusion using the Marsh model with adjusted body weight. J Anesth. 2024;38(2):275-278."""),
                      ]),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () async {
                        await HapticFeedback.mediumImpact();
                        // Close the modal
                        Navigator.of(context).pop();
                      },
                      child: Text('Close'),
                    ),
                  ],
                );
            }
          });
    }

    void showWakeAlertDialog(BuildContext context) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            switch (Localizations.localeOf(context).languageCode) {
              case 'ja':
                return AlertDialog(
                  title: Text('麻酔覚醒濃度推定'),
                  content: SingleChildScrollView(
                    child: Text.rich(TextSpan(children: [
                      TextSpan(text: '''目的：
全身麻酔から患者が覚醒する（つまり、声に反応して目を開ける）プロポフォールの効果部位濃度を推定します。

使用方法：
(1) 維持期のEleveld Ce（効果部位濃度）を入力します。（注：代わりにEleMarsh Cp（血漿中濃度）を使用する場合は、定常状態に達していることを確認してください）

(2) 観察された対応する状態エントロピー（SE）を入力します。

(3) アルゴリズムは、個人のプロポフォール感受性に基づいて麻酔覚醒の濃度範囲を導き出します。

注意事項：
(a) アルゴリズムはEleveldモデルに基づいています。EleMarshalはヒステリシスを示す可能性があります。

(b) 覚醒Ce推定値は最小の刺激を前提としています。実際の覚醒Ceは刺激、鎮痛、筋弛緩、補助薬に依存します。

(c) 臨床検証研究が進行中です。''')
                    ])),
                  ),
                );
              default:
                return AlertDialog(
                  title: Text('Wake Up Estimation'),
                  content: SingleChildScrollView(
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(
                            text: "Aim:",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: "\n"),
                        TextSpan(
                            text:
                                "Estimate the propofol Ce at which the patient emerges from general anaesthesia (i.e. eye open to voice)."),
                        TextSpan(text: "\n\n"),
                        TextSpan(
                            text: "Usage:",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: "\n"),
                        TextSpan(text: """
(1) Enter the Eleveld Ce during maintenance phase. (N.B. if EleMarsh Cp is used instead, please ensure steady state has been achieved)

(2) Enter the corresponding state entropy (SE) observed.

(3) The algorithm will derive the Ce range for anaesthesia emergence based on the individual’s propofol sensitivity."""),
                        TextSpan(text: "\n\n"),
                        TextSpan(
                            text: "Caveats:",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: "\n"),
                        TextSpan(
                            text:
                                """(a) Algorithm based on Eleveld model. EleMarsh may demonstrate hysteresis.

(b) Wake up Ce estimate assumes minimal stimulus. Actual wake up Ce will depend on stimulus, analgesia, paralysis and adjuvants.

(c) Clinical validation study is in progress."""),
                      ]),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () async {
                        await HapticFeedback.mediumImpact();
                        Navigator.of(context).pop();
                      },
                      child: Text('Close'),
                    ),
                  ],
                );
            }
          });
    }

    int? age = int.tryParse(ageController.text);
    bool isAdult = true;
    if(age != null){
      if(age<17){
        isAdult = false;
      }else{
        isAdult=true;
      }
    }


    return Container(
      height: screenHeight,
      margin: EdgeInsets.symmetric(horizontal: horizontalSidesPaddingPixel),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Expanded(child: Container()),
          ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
            child: Column(
              children: [
                Opacity(
                  opacity: flowController.val == 0 ? 1 : 0,
                  child: Container(
                    height: flowController.val == 0 ? rowHeight * 3 : 0,
                    child: Column(
                      children: [
                        Container(
                          height: rowHeight,
                          color: Theme.of(context).colorScheme.onPrimary,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Divider(
                                height: 0.0,
                                color: Colors.transparent,
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 16.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "EleMarsh ${AppLocalizations.of(context)!.abw}",
                                      style: TextStyle(
                                          fontSize: 18,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary),
                                    ),
                                    Row(
                                      children: [
                                        Text("$weightBestGuess",
                                            style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.w600,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary)),
                                        Text(" kg",
                                            style: TextStyle(
                                                fontSize: 24,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.only(left: 16.0),
                                child: Divider(
                                  height: 1.0,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              )
                            ],
                          ),
                        ),
                        Container(
                          height: rowHeight,
                          color: Theme.of(context).colorScheme.onPrimary,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Divider(
                                height: 0.0,
                                color: Colors.transparent,
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 16.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "${AppLocalizations.of(context)!.induction} CpT",
                                      style: TextStyle(
                                        fontSize: 16,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          "$inductionCPTarget",
                                          style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          " μg/mL",
                                          style: TextStyle(fontSize: 20),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.only(left: 16.0),
                                child: Divider(
                                  height: 1.0,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              )
                            ],
                          ),
                        ),
                        Container(
                          height: rowHeight,
                          color: Theme.of(context).colorScheme.onPrimary,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Divider(
                                height: 0.0,
                                color: Colors.transparent,
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 16.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      child: Row(
                                        children: [
                                          Text(
                                            "${AppLocalizations.of(context)!.predicted} BIS",
                                            style: TextStyle(
                                                fontSize: 16,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary),
                                          ),
                                          SizedBox(
                                            width: 8.0,
                                          ),
                                          Text(
                                            "$predictedBIS",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          "BMI",
                                          style: TextStyle(fontSize: 14),
                                        ),
                                        SizedBox(
                                          width: 8.0,
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              "$BMI",
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    // Row(
                                    //   children: [
                                    //     Text(
                                    //       "MaxAPE",
                                    //       style: TextStyle(fontSize: 14),
                                    //     ),
                                    //     SizedBox(
                                    //       width: 8.0,
                                    //     ),
                                    //     Text(
                                    //       "$MaxAPE %",
                                    //       style: TextStyle(fontSize: 14),
                                    //     ),
                                    //   ],
                                    // ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.only(left: 16.0),
                                child: Divider(
                                  height: 1.0,
                                  color: Colors.transparent,
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Opacity(
                  opacity: flowController.val == 1 ? 1 : 0,
                  child: Container(
                    height: flowController.val == 1 ? 119 : 0,
                    child: Column(
                      children: [
                        Container(
                          color: isMaintenanceSEOutOfRange
                              ? Theme.of(context).colorScheme.onTertiary
                              : Theme.of(context).colorScheme.onPrimary,
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              SizedBox(
                                height: 16,
                              ),
                              Text(
                                AppLocalizations.of(context)!.wakeUpRange,
                                style: TextStyle(
                                    fontSize: 18,
                                    color: isMaintenanceSEOutOfRange
                                        ? Theme.of(context).colorScheme.tertiary
                                        : Theme.of(context)
                                            .colorScheme
                                            .primary),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    range,
                                    style: TextStyle(
                                        fontSize: 54,
                                        color: isMaintenanceSEOutOfRange
                                            ? Theme.of(context)
                                                .colorScheme
                                                .tertiary
                                            : Theme.of(context)
                                                .colorScheme
                                                .primary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 24,
          ),
          Container(
            width: mediaQuery.size.width - horizontalSidesPaddingPixel * 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  height: UIHeight,
                  child: PDSegmentedControl(
                      fitHeight: true,
                      fontSize: 14,
                      defaultColor: Theme.of(context).colorScheme.primary,
                      defaultOnColor: Theme.of(context).colorScheme.onPrimary,
                      labels: [
                        AppLocalizations.of(context)!.induce,
                        AppLocalizations.of(context)!.emerge
                      ],
                      segmentedController: flowController,
                      onPressed: [
                        () {
                          settings.EMFlow = 'induce';
                        },
                        () {
                          settings.EMFlow = 'wake';
                        }
                      ]),
                ),
                Row(
                  children: [
                    Container(
                        height: UIHeight,
                        width: UIHeight,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.all(0),
                            backgroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  strokeAlign: BorderSide.strokeAlignOutside,
                                ),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(5))),
                          ),
                          onPressed: () async {
                            await HapticFeedback.mediumImpact();
                            flowController.val == 0
                                ? showInduceAlertDialog(context)
                                : showWakeAlertDialog(context);
                          },
                          child:
                              Center(child: Icon(Icons.info_outline_rounded)),
                        )),
                    SizedBox(
                      width: 8,
                    ),
                    Container(
                        height: UIHeight,
                        width: UIHeight,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.all(0),
                            backgroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  strokeAlign: BorderSide.strokeAlignOutside,
                                ),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(5))),
                          ),
                          onPressed: () async {
                            await HapticFeedback.mediumImpact();
                            reset(toDefault: true);
                          },
                          child: Icon(Icons.restart_alt_outlined),
                        )),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(
            height:
                28, //this has been manually adjusted from 24, don't know the root cause yet.
          ),
          Opacity(
            opacity: flowController.val == 0 ? 1 : 0,
            child: Container(
              height: flowController.val == 0 ? UIHeight + 24 : 0,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: UIWidth,
                    child: PDSwitchField(
                      labelText: AppLocalizations.of(context)!.sex,
                      prefixIcon: sexController.val == true
                          ? isAdult ? Icons.woman : Icons.girl
                          : isAdult ? Icons.man : Icons.boy,
                      controller: sexController,
                      switchTexts: {
                        true: isAdult ? Sex.Female.toLocalizedString(context) : Sex.Girl.toLocalizedString(context),
                        false: isAdult ? Sex.Male.toLocalizedString(context) : Sex.Boy.toLocalizedString(context)
                      },
                      onChanged: run,
                      height: UIHeight,
                    ),
                  ),
                  SizedBox(
                    width: 8,
                    height: 0,
                  ),
                  Container(
                    width: UIWidth,
                    child: PDTextField(
                      prefixIcon: Icons.calendar_month,
                      labelText: AppLocalizations.of(context)!.age,
                      // helperText: '',
                      interval: 1.0,
                      fractionDigits: 0,
                      controller: ageController,
                      range: [Model.EleMarsh.minAge, Model.EleMarsh.maxAge],
                      onPressed: updatePDTextEditingController,
                      // onChanged: restart,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Opacity(
            opacity: flowController.val == 1 ? 1 : 0,
            child: Container(
              height: flowController.val == 1 ? UIHeight + 24 : 0,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width:
                        mediaQuery.size.width - 2 * horizontalSidesPaddingPixel,
                    child: PDSwitchField(
                      labelText: AppLocalizations.of(context)!.model,
                      // labelText: "Model",
                      prefixIcon: modelController.val == true
                          ? Icons.spoke_outlined
                          : Icons.hub_outlined,
                      controller: modelController,
                      switchTexts: {
                        true: Model.Eleveld.toString(),
                        false: Model.EleMarsh.toString()
                      },
                      onChanged: run,
                      height: UIHeight,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          Opacity(
            opacity: flowController.val == 0 ? 1 : 0,
            child: Container(
              height: flowController.val == 0 ? UIHeight + 24 : 0,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: UIWidth,
                    child: PDTextField(
                      prefixIcon: Icons.straighten,
                      labelText: '${AppLocalizations.of(context)!.height} (cm)',
                      // helperText: '',
                      interval: 1,
                      fractionDigits: 0,
                      controller: heightController,
                      range: [minHeightEleMarsh, maxHeightEleMarsh],
                      onPressed: updatePDTextEditingController,
                    ),
                  ),
                  SizedBox(
                    width: 8,
                    height: 0,
                  ),
                  Container(
                    width: UIWidth,
                    child: PDTextField(
                      prefixIcon: Icons.monitor_weight_outlined,
                      labelText: '${AppLocalizations.of(context)!.weight} (kg)',
                      // helperText: '',
                      interval: 1.0,
                      fractionDigits: 0,
                      controller: weightController,
                      range: [minWeightEleMarsh, maxWeightEleMarsh],
                      onPressed: updatePDTextEditingController,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Opacity(
            opacity: flowController.val == 1 ? 1 : 0,
            child: Container(
              height: flowController.val == 1 ? UIHeight + 24 : 0,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width:
                        mediaQuery.size.width - 2 * horizontalSidesPaddingPixel,
                    child: PDTextField(
                      prefixIcon: Icons.monitor_heart_outlined,
                      labelText:
                          AppLocalizations.of(context)!.maintenanceStateEntropy,
                      helperText: isMaintenanceSEOutOfRange
                          ? '*Accuracy reduced, min: 21 and max: 60'
                          : '',
                      interval: 1,
                      fractionDigits: 0,
                      controller: maintenanceSEController,
                      range: [1, 99],
                      onPressed: updatePDTextEditingController,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          Opacity(
            opacity: flowController.val == 0 ? 1 : 0,
            child: Container(
              height: flowController.val == 0 ? UIHeight + 24 : 0,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: UIWidth * 2 + 8,
                    child: PDTextField(
                      prefixIcon: Icons.psychology_alt_outlined,
                      labelText:
                          '${AppLocalizations.of(context)!.effectSiteTarget} (μg/mL)',
                      interval: 0.5,
                      fractionDigits: 1,
                      controller: targetController,
                      range: [0.5, 8],
                      onPressed: updatePDTextEditingController,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Opacity(
            opacity: flowController.val == 1 ? 1 : 0,
            child: Container(
              height: flowController.val == 1 ? UIHeight + 24 : 0,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width:
                        mediaQuery.size.width - 2 * horizontalSidesPaddingPixel,
                    child: PDTextField(
                      prefixIcon: Icons.psychology_alt_outlined,
                      labelText: settings.EMWakeUpModel == Model.Eleveld
                            ? AppLocalizations.of(context)!.maintenanceCe
                            : AppLocalizations.of(context)!.maintenanceCp,
                      interval: 0.5,
                      fractionDigits: 1,
                      controller: maintenanceCeController,
                      range: [0.5, 8],
                      onPressed: updatePDTextEditingController,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 8,
          ),
        ],
      ),
    );
  }
}
