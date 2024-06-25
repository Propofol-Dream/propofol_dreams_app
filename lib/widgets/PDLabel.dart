import 'package:flutter/material.dart';

class PDLabel extends StatelessWidget {
  final String leadingText;
  final String? supportingText;
  final Color backgroundColor;
  final Color textColor;

  const PDLabel({
    Key? key,
    required this.leadingText,
    this.supportingText, // Made optional
    required this.backgroundColor,
    required this .textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8.0),
      ),
      padding: EdgeInsets.all(8.0),
      child: FittedBox(
          fit: BoxFit.contain, // Adjust to your needs
          alignment: Alignment.topLeft,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(leadingText, style: TextStyle(fontSize: 16, color: textColor)),
              if (supportingText != null) ...[
                SizedBox(width: 4.0),
                Text(supportingText!, style: TextStyle(fontSize: 16, color: textColor)),
              ],
            ],
          )
      ),
    );
  }
}