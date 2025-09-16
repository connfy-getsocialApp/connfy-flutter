import 'package:connectivity_plus/connectivity_plus.dart';


class NetworkServicese {
  NetworkServicese() {
    _monitorNetworkChanges();
  }

  void _monitorNetworkChanges() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) {
      _handleNetworkChange(result);
    });
  }

  void _handleNetworkChange(List<ConnectivityResult> result) {
    String networkStatus = _getNetworkStatus(result);
    _scheduleBackgroundTask(networkStatus);
  }

  String _getNetworkStatus(List<ConnectivityResult> result) {
    switch (result) {
      case ConnectivityResult.mobile:
        return "Mobile";
      case ConnectivityResult.wifi:
        return "WiFi";
      case ConnectivityResult.none:
        return "Offline";
      default:
        return "Unknown";
    }
  }

  void _scheduleBackgroundTask(String networkStatus) {

  }
}
