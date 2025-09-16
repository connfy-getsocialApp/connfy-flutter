// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:jumping_dot/jumping_dot.dart';

class UserChatContainer extends StatelessWidget {

  final String question;
  final String? answer;

  const UserChatContainer({
    super.key,
    required this.question,
    this.answer
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        // User's question bubble
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(51, 0, 7, 22),
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:Colors.green.shade200,
                // color: greenThemeColor,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(12),
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(3),
                ),
              ),
              child: Text(
                question,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 17,
                  fontFamily: 'Urbanist',
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),

        // Answer or Loading Indicator
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(2, 0, 55, 22),
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade300,
                // color: gray5Color,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(12),
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(3),
                  bottomRight: Radius.circular(12),
                ),
              ),
              // Show loading indicator or answer text
              child: answer != null && answer!.isNotEmpty
                  ? Text(
                answer!,
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 17,
                  fontFamily: 'Urbanist',
                  color: Color.fromRGBO(51, 51, 51, 1),
                ),
              )
                  : SizedBox(
                width: 30,
                child: JumpingDots(
                  color: Colors.green,
                  // color: greenThemeColor,
                  radius: 10,
                  numberOfDots: 3,
                  innerPadding: 0,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}