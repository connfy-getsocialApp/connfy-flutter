// ignore_for_file: prefer_const_constructors
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
// import 'package:helix_ai/components/chat_text.dart';
// import 'package:helix_ai/constants/colors.dart';

class ChatStart extends StatelessWidget {
  ChatStart({super.key});

  final List<String> capability = [
    'Revolutionize your nutrition with Gene – the ultimate solution for automating your diet.',
    'Prioritize your mental well-being with Gene',
    'Effortlessly order and track essential tests and other health metrics,'
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SvgPicture.asset(
              '',
              height: 70,
              width: 30,
            ),
            SizedBox(
              height: 25,
            ),
            ChatText(text: "Gene Capabilities"),
            SizedBox(
              height: 25,
            ),
            ListView.builder(
              itemCount: capability.length,
              shrinkWrap: true,
              physics: ClampingScrollPhysics(),
              itemBuilder: (context, index) {
                return Container(
                  padding: EdgeInsets.all(12),
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: f5f5feColor,
                      borderRadius: BorderRadius.circular(12)),
                  width: double.infinity,
                  child: Column(
                    children: [
                      ChatText(text: capability[index]),
                    ],
                  ),
                );
              },
            ),
            SizedBox(height: 15),
            Text(
              "These are just examples what can I do.",
              style: TextStyle(
                fontSize: 17,
                color: gray1Color,
              ),
            )
          ],
        ),
      ),
    );
  }
}
// Replace these with your actual color constants
const Color f5f5feColor = Color(0xFFF5F5FE);
const Color gray1Color = Colors.grey;

// Simple ChatText widget replacement
class ChatText extends StatelessWidget {
  final String text;

  const ChatText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

