import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class NetworkStatus extends ChangeNotifier {
  ConnectivityResult _status = ConnectivityResult.none;

  ConnectivityResult get status => _status;

  void updateStatus(ConnectivityResult result) {
    _status = result;
    notifyListeners();
  }
}
