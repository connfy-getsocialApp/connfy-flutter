import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityExample extends StatefulWidget {
  @override
  _ConnectivityExampleState createState() => _ConnectivityExampleState();
}

class _ConnectivityExampleState extends State<ConnectivityExample> {
  late ConnectivityResult _connectionStatus;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _connectionStatus = ConnectivityResult.none;
    //  _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    ConnectivityResult result;
    try {
      //  result = await _connectivity.checkConnectivity();
    } catch (e) {
      result = ConnectivityResult.none;
    }
    if (!mounted) return;

    setState(() {
      // _connectionStatus = result;
    });
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    setState(() {
      _connectionStatus = result;
    });
    // Handle additional logic based on the connection status here
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Connectivity Example')),
      body: Center(
        child: Text('Connection Status: $_connectionStatus'),
      ),
    );
  }
}
