import 'package:flutter/material.dart';

import 'package:propofol_dreams_app/constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        height: 96,
        padding: EdgeInsets.symmetric(horizontal: horizontalSidesPaddingPixel),
        alignment: Alignment.bottomLeft,
        child: Text(
          'Settings',
          style: TextStyle(
              fontSize: 24, color: Theme.of(context).colorScheme.primary),
        ),
      ),
      Divider(
        color: Theme.of(context).colorScheme.primary,
      ),
      Container(
        height: MediaQuery.of(context).size.height - 90 - 96 - 16,
        padding: EdgeInsets.symmetric(horizontal: horizontalSidesPaddingPixel),
        // decoration: BoxDecoration(
        //   border: Border.all(color: Theme.of(context).colorScheme.primary),
        // ),
        child: ListView(
          padding: EdgeInsets.zero,
          physics: NeverScrollableScrollPhysics(),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Propofol Density',
                  style: TextStyle(fontSize: 16),
                ),
                Row(
                  children: [
                    ElevatedButton(onPressed: () {}, child: Text('1%')),
                    ElevatedButton(onPressed: () {}, child: Text('2%')),
                  ],
                )
              ],
            ),
            SizedBox(height: 16,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Dark Mode',
                  style: TextStyle(fontSize: 16),
                ),
                Row(
                  children: [
                    ElevatedButton(onPressed: () {}, child: Text('Light')),
                    ElevatedButton(onPressed: () {}, child: Text('Dark')),
                    ElevatedButton(onPressed: () {}, child: Text('Auto')),
                  ],
                )
              ],
            ),
          ],
        ),
      )
    ]);
  }
}
