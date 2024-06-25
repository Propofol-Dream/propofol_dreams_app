import 'package:flutter/material.dart';

class PDStyledLabel extends StatelessWidget {
  final String title;
  final String leadingText;
  final String? supportingText;
  final Color backgroundColor;
  final Color textColor;

  const PDStyledLabel({
    Key? key,
    required this.title,
    required this.leadingText,
    this.supportingText, // Made optional
    required this.backgroundColor,
    required this.textColor,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: TextStyle(fontSize: 16.0, color: textColor),),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(leadingText, style: TextStyle(fontSize: 36.0,height: 1.0, color: textColor),),
                if (supportingText != null) ...[
                  SizedBox(width: 4.0),
                  Text(supportingText!,style: TextStyle(fontSize: 16.0, color: textColor),),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
