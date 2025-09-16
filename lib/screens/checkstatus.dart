import 'package:flutter/material.dart';

class MyAppchech extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Connectivity Status'),
      ),
      body: Center(
        child: Text(
          'Checking connectivity in the background...',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
