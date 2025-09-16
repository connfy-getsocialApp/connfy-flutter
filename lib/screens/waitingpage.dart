import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'NetworkService.dart';

class HomeScreengttt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Network Connectivity Check'),
      ),
      body: Center(
        child: Consumer<NetworkService>(
          builder: (context, networkService, child) {
            if (networkService.networkStatus == NetworkStatus.Online) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'You are Online',
                    style: TextStyle(color: Colors.green, fontSize: 24),
                  ),
                  SizedBox(height: 20),
                  Text('Wifi Name: ${networkService.wifiName}'),
                  Text('Wifi BSSID: ${networkService.wifiBSSID}'),
                  Text('Wifi IPv4: ${networkService.wifiIPv4}'),
                  Text('Wifi IPv6: ${networkService.wifiIPv6}'),
                  Text('Wifi Submask: ${networkService.wifiSubmask}'),
                  Text('Wifi Broadcast: ${networkService.wifiBroadcast}'),
                  Text('Wifi Gateway: ${networkService.wifiGatewayIP}'),
                ],
              );
            } else {
              return Text(
                'You are Offline',
                style: TextStyle(color: Colors.red, fontSize: 24),
              );
            }
          },
        ),
      ),
    );
  }
}
