import 'dart:async';
import 'dart:convert';

import 'package:chatapp/screens/email_verification_page.dart';
import 'package:chatapp/screens/registration_pagenew.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:localstorage/localstorage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helper/constants.dart';
import '../helper/shared_preference.dart';
import 'chatlistnew.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _SplashScreenState();
  }
}

class _SplashScreenState extends State<SplashScreen> {
  // final LocalStorage storage = new LocalStorage('wifi');

  Future<void> retrieveWifiName() async {
    var headers = {'Content-Type': 'application/json'};
    var request = http.Request('POST',
        Uri.parse('https://admin.connfy.at/api/wifi_details'));
    request.body = json.encode({"id": 1});
    request.headers.addAll(headers);

    try {
      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        Map<String, dynamic> responseData = json.decode(responseBody);

        // Ensure that the 'data' field is present and contains 'wifi_name'
        if (responseData.containsKey('data') && responseData['data'] != null) {
          Map<String, dynamic> data = responseData['data'];
          if (data.containsKey('wifi_name') && data['wifi_name'] != null) {
            String wifiName = data['wifi_name'];
            String url_ = data['google_url'];
            dynamic shopid = data['id'];
            // print('WiFi Name: $wifiName');
            savePost1(wifiName, wifiName, shopid, url_);
            // Now you can use the WiFi name as needed
          } else {
            // print('WiFi name not found or is null in the data');
          }
        } else {
          // print('Data not found or is null in the response');
        }
      } else {
        // print('Failed to retrieve WiFi name: ${response.reasonPhrase}');
      }
    } catch (e) {
      // print('Error occurred: $e');
    }
  }

  savePost1(String name, String ssid, dynamic shopid, String url) async {
    localStorage.setItem("wifiname", name);
    localStorage.setItem("SSID", ssid);
    localStorage.setItem("shopid", shopid.toString());
    localStorage.setItem("url", url);
  }

  startTimernew() {
    initLocalStorage();
    Timer(const Duration(seconds: 3), () => setAuthValue());
  }

  Future setAuthValue() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var status = prefs.getBool('isLoggedIn') ?? false;
    var email = prefs.getString('email') ?? '';
    var UserId = prefs.getString('UserId') ?? '';
    var uemail = prefs.getString('uemail') ?? '';
    // print(status);
    if (status) {
      await HelperFunctions.getUserNameSharedPreference().then((value) {
        setState(() {
          Constants.myName = value!;
        });
      });

      if (email.isNotEmpty) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => ChatListnew("")));
      } else {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => ThankYouPage(uemail, UserId)));
      }
    } else {
      if (email.isEmpty) {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const RegistrationPagenew()));
      } else {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => ThankYouPage(uemail, UserId)));
      }
      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => RegistrationPagenew()));
    }
  }

  startTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? firstTime = prefs.getBool('first_time');

    var duration = const Duration(seconds: 3);

    if (firstTime != null && !firstTime) {
      // Not first time
      return Timer(duration, getLoggedInState);
    } else {
      // First time
      prefs.setBool('first_time', false);
      return Timer(duration, navigateUser1);
    }
  }

  bool? userIsLoggedIn = false;

  @override
  void initState() {
    super.initState();

    //  retrieveWifiName();
    startTimernew();
    //  _checkPermissions();

    // 53
  }

  getLoggedInState() async {
    await HelperFunctions.getUserLoggedInSharedPreference().then((value) {
      setState(() {
        userIsLoggedIn = value;
        // print('userIsLoggedIn');
        // print(userIsLoggedIn);
      });
    });
    navigateUser();

    // startTimer();
  }

  Future<void> startTimer() async {
    Timer(const Duration(seconds: 3), () {
      //  showAlertDialog(context,"This is a jailbroken device");
      navigateUser();

      //It will redirect  after 3 seconds
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: Form(
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light,
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: Stack(
                children: <Widget>[
                  const SizedBox(
                    height: double.infinity,
                    width: double.infinity,
                  ),
                  Center(
                    child: Container(
                      width: 250.0,
                      height: 130.0,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/appicon.png'),
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
  }

  void navigateUser() async {
    savePost1("errrr", "eeeee", "", "url_");
    //  Fluttertoast.showToast(msg: userIsLoggedIn.toString(), toastLength: Toast.LENGTH_LONG, gravity: ToastGravity.CENTER, timeInSecForIosWeb: 1, backgroundColor: Colors.amber, textColor: Colors.white, fontSize: 16.0);
    if (userIsLoggedIn == true) {
      await HelperFunctions.getUserNameSharedPreference().then((value) {
        setState(() {
          Constants.myName = value!;
        });
      });
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => ChatListnew("")));

      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => RegistrationPagenew()));
    } else {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => const RegistrationPagenew()));
    }
  }

  void navigateUser1() async {
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (context) => const RegistrationPagenew()));
  }
}
