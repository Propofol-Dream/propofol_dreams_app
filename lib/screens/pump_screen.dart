import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PumpScreen extends StatelessWidget {
  const PumpScreen({Key? key}) : super(key: key);

  _launchURL() async {
    const url = 'https://propofoldreams.org';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Text(
                'We are building this feature for you.\n Click to learn more',style: TextStyle(fontSize: 16),textAlign: TextAlign.center,),
          ),
          SizedBox(height: 16,),
          ElevatedButton(onPressed: _launchURL, child: Text('Learn More'))
        ]);
  }
}
