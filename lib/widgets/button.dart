import 'package:flutter/material.dart';

class MyButoon extends StatelessWidget {
  final String title;
  final Function() onPressed;
  final bool loading;
  MyButoon({super.key, required this.title, required this.onPressed, this.loading = false});

  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 5),
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(40)),
      child: TextButton(
          onPressed: onPressed,
          child: loading
              ? CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white,
                )
              : Text(
                  title,
                  style: TextStyle(color: Colors.white, fontSize: 20),
                )),
    );
  }
}
