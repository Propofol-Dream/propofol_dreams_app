import 'package:flutter/material.dart';

class DurationScreen extends StatelessWidget {
  const DurationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height-90,
      child: Center(
        child:Text('Duration'),
      ),
    );
  }
}
