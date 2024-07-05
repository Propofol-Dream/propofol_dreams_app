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
  bool isTextFieldVisible = true;
  TextEditingController textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height - 90,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Visibility(
              visible: isTextFieldVisible,
              child: Container(
                child: TextField(
                  controller: textController,
                  decoration: InputDecoration(
                    labelText: 'Age',
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  isTextFieldVisible = !isTextFieldVisible;
                });
              },
              child: Text('Toggle TextField Visibility'),
            ),
          ],
        ),
      ),
    );
  }
}
