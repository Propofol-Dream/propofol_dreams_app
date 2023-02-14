import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/gender.dart';
import '../models/model.dart';
import '../models/operation.dart';
import '../models/patient.dart';
import '../models/pump.dart';
import '../models/simulation.dart' as PDSim;

class PumpScreen extends StatefulWidget {
  PumpScreen({Key? key}) : super(key: key);

  @override
  State<PumpScreen> createState() => _PumpScreenState();
}

class _PumpScreenState extends State<PumpScreen> {
  String volume = '';

  _launchURL() async {
    const url = 'https://propofoldreams.org/in_app_redirect/';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }

  run()  {
    DateTime start = DateTime.now();
    String result = '';

    Model model = Model.Eleveld;
    Patient patient =
        Patient(weight: 58, age: 50, height: 160, gender: Gender.Female);

    Pump pump =
        Pump(timeStep: Duration(seconds: 1), density: 10, maxPumpRate: 1200);

    Operation operation =
        Operation(target: 4, duration: Duration(minutes: 600));

    PDSim.Simulation sim = PDSim.Simulation(
        model: model, patient: patient, pump: pump, operation: operation);

    pump.updateTarget(at: Duration(minutes: 10), target: 8);
    pump.updateBolus(
        at: Duration(minutes: 10),
        bolus: sim.estimateBolus(8 - operation.target));

    var tmp = sim.estimate2;
    result = tmp['cumulative_infused_volumes']!.last.toString();

    // result = sim.maxCeReachesAt.toString();

    DateTime end = DateTime.now();

    Duration duration = end.difference(start);

    setState(() {
      volume = result + ' ' + duration.inMilliseconds.toString() +' milliseconds';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height - 90,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Center(
          child: Text(
            'We are building TCI for you.\n Be the first one to know',
            // volume,
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(
          height: 16,
        ),
        ElevatedButton(onPressed: _launchURL, child: Text('Learn More'))
        // ElevatedButton(onPressed: run, child: Text('Run'))
      ]),
    );
  }
}
