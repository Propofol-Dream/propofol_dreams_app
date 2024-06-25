import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:propofol_dreams_app/widgets/PDLabel.dart';
import 'package:propofol_dreams_app/widgets/PDStyledLabel.dart';

class TestScren extends StatefulWidget {
  TestScren({Key? key}) : super(key: key);

  @override
  State<TestScren> createState() => _TestScrenState();
}

class _TestScrenState extends State<TestScren> {
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
        PDLabel(
            leadingText: 'BMI',
            supportingText: '21.6',
            textColor: Theme.of(context).colorScheme.onPrimary,
            backgroundColor: Theme.of(context).colorScheme.primary),
        SizedBox(height: 8),
        PDStyledLabel(
            title: 'Infusion Rate',
            leadingText: "888.8",
            supportingText: "mL/hr",
            backgroundColor: Theme.of(context).colorScheme.primary,
            textColor: Theme.of(context).colorScheme.onPrimary),
        // Container(
        //   decoration: BoxDecoration(
        //       color: Theme.of(context).colorScheme.primary,
        //       borderRadius: BorderRadius.circular(8.0)),
        //   padding: EdgeInsets.all(8.0),
        //   child: FittedBox(
        //     fit: BoxFit.contain, // Adjust to your needs
        //     alignment: Alignment.topLeft,
        //     child: Column(
        //       crossAxisAlignment: CrossAxisAlignment.start,
        //       children: [
        //         Text('Learn More'),
        //         Row(
        //           mainAxisAlignment: MainAxisAlignment.start,
        //           children: [
        //             Text('Learn More'),
        //             SizedBox(width: 4.0),
        //             Text('Learn More'),
        //           ],
        //         ),
        //       ],
        //     ),
        //   ),
        // ),

        SizedBox(
          height: 16,
        ),
        ElevatedButton(onPressed: _launchURL, child: Text('Learn More'))
        // ElevatedButton(onPressed: run, child: Text('Run'))
      ]),
    );
  }
}
