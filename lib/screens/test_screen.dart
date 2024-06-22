import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';


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
        ElevatedButton(onPressed: _launchURL, child: Text('Learn More'))
        // ElevatedButton(onPressed: run, child: Text('Run'))
      ]),
    );
  }
}
