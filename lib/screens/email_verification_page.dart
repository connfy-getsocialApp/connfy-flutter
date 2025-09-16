// ignore_for_file: prefer_const_constructors

import 'dart:convert';
import 'dart:developer';

import 'package:chatapp/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:localstorage/localstorage.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:location/location.dart' as loc;
import '../constants/app_strings.dart';
import '../controller/Constant.dart';
import '../controller/loader.dart';
import 'NetworkService.dart';
import 'chatlistnew.dart';
import 'location_service.dart';

class ThankYouPage extends StatefulWidget {
  final email, userid;

  const ThankYouPage(this.email, this.userid, {super.key});

  @override
  State<ThankYouPage> createState() => _ThankYouPageState(email, userid);
}

Color themeColor = const Color(0xFF43D19E);

class _ThankYouPageState extends State<ThankYouPage> {
  final LocationService _locationService = LocationService();
  final String _locationLog = '';
  String? wifiName;
  String? wifiBSSID;
  String? wifiIPv4;
  String? wifiIPv6;
  String? wifiSubmask;
  String? wifiBroadcast;
  String? wifiGatewayIP;
  var email, userid;
  _ThankYouPageState(this.email, this.userid);
  double screenWidth = 600;
  double screenHeight = 400;
  Color textColor = const Color(0xFF32567A);
  bool isLoading = false;
  bool emailflag = false;
  bool updateflag = false;
  bool isEmailVerified = false;
  TextEditingController emailcontroller = TextEditingController();

  final SnakBarKey = GlobalKey<ScaffoldMessengerState>();
  void showSnakBar(String message) {
    final snakbar = SnackBar(
      content: Text(message),
      backgroundColor: Colors.redAccent,
      duration: const Duration(seconds: 4),
    );
    SnakBarKey.currentState?.showSnackBar(snakbar);
  }

  Future<void> showLocalNotification(String title, String body) async {
    Fluttertoast.showToast(
        msg: "Under Development $wifiName'",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 25.0);
  }

  Future<void> sendData() async {
    print("SEND DATA CALLED");
    try {
      NetworkService networkService = NetworkService();
      // Call initNetworkInfoOldmain
      await networkService.initNetworkInfoOld();

      /* Connectivity().onConnectivityChanged.listen((ConnectivityResult results) async {
      print(results);
      // Check if the results contain ConnectivityResult.none
      if (results == ConnectivityResult.none) {
        print("NO Connected ");
      } else if (results == ConnectivityResult.mobile) {
        await _initNetworkInfoold();
        print("Connected to Mobile Dataxxxxxxx");
      } else if (results == ConnectivityResult.wifi) {
        await  _initNetworkInfoold();
        print("Connected to Wi-Fi");
      }

      // Broadcast the network status to listeners
      // _networkStatusController.add(_networkStatus);
    });*/
    } catch (e) {
      print('Error in background service: $e');
    }
  }

  Future<bool> _onWillPop() async {
    return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Are you sure to exit?'),
            // content: const Text('Do you want to delete your data'),
            actions: <Widget>[
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(false), //<-- SEE HERE
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () async {
                  SharedPreferences preferences =
                      await SharedPreferences.getInstance();
                  preferences.clear();

                  localStorage.clear();
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (context) => SplashScreen()));
                }, // <-- SEE HERE
                child: const Text('Yes'),
              )
            ],
          ),
        )) ??
        false;
  }

  Future<void> _initNetworkInfo() async {
    final NetworkInfo networkInfo = NetworkInfo();
    String wifiNamenew = '';
    try {
      // Request location permission if not granted
      if (await Permission.locationAlways.request().isGranted) {
        wifiNamenew = await networkInfo.getWifiName() ?? '';
        wifiBSSID = await networkInfo.getWifiBSSID();
      } else if (await Permission.location.request().isGranted) {
        wifiNamenew = await networkInfo.getWifiName() ?? '';
        wifiBSSID = await networkInfo.getWifiBSSID();
      } else if (await Permission.locationWhenInUse.request().isGranted) {
        wifiNamenew = await networkInfo.getWifiName() ?? '';
        wifiBSSID = await networkInfo.getWifiBSSID();
      } else {
        wifiNamenew = await networkInfo.getWifiName() ?? '';
        wifiBSSID = await networkInfo.getWifiBSSID() ?? '';
      }

      setState(() {
        wifiName = wifiNamenew;
      });

      print("wifiName $wifiName");
    } catch (e) {
      log('Failed to get Wifi information: $e');
    }
  }

  doRegistration(String userId) async {
    /* setState(() {
      isLoading = true;
    });*/
    var headers = {'Content-Type': 'application/json'};
    Map<String, dynamic> data = {"user_id": userId};

    try {
      var request = http.Request(
          'POST',
          Uri.parse(
              'https://admin.connfy.at/api/email_verification_check'));
      request.body = json.encode(data);
      print(json.encode(data));

      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        setState(() {
          isLoading = false;
        });
        String jsonData = await response.stream.bytesToString();
        Map<String, dynamic> responseData = jsonDecode(jsonData);
        print(responseData);

        dynamic status = responseData['status'];
        print(status);

        if (status == 0) {
          showSnakBar('Your email id is not verified');
          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setBool("isLoggedIn", false);
          prefs.setString('email', '');
          isEmailVerified = false;
        } else {
          localStorage.clear();
          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setBool("isLoggedIn", true);
          prefs.setString('email', email);
          isEmailVerified = true;

          /*  await _locationService.startService();
          FlutterBackgroundService().on('update').listen((event) {
            if (event!['lat'] != null && event['lng'] != null) {
              setState(() {
                _locationLog += 'Location: ${event['lat']}, ${event['lng']}\n';
              });
            }
          });*/

          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => ChatListnew("")));
          /* Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => ThankYouPage(
                        title: '',
                      )));*/
        }
      } else {
        setState(() {
          isLoading = false;
        });

        print(response.reasonPhrase);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error creating account 11: $e");

      print('$e');
    }
  }

  doRegistration_resend(String emailid) async {
    if (isLoading) return; // Prevent multiple calls

    setState(() {
      isLoading = true;
    });

    var headers = {'Content-Type': 'application/json'};
    Map<String, dynamic> data = {"user_id": userid, "new_email": emailid};

    try {
      var request = http.Request(
          'POST',
          Uri.parse(
              'https://admin.connfy.at/api/email_verification_resend'));
      request.body = json.encode(data);
      print(json.encode(data));

      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        setState(() {
          isLoading = false;
        });
        String jsonData = await response.stream.bytesToString();
        Map<String, dynamic> responseData = jsonDecode(jsonData);
        print(responseData);

        int status = responseData['status'];

        if (status == 1) {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => ThankYouPage(emailid, userid)));
        } else {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => ThankYouPage(email, userid)));

          // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ChatListnew("")));
          /* Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => ThankYouPage(
                        title: '',
                      )));*/
        }
      } else {
        setState(() {
          isLoading = false;
        });

        print(response.reasonPhrase);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error creating account 22: $e");

      print('$e');
    }
  }

  static bool? emailValidate(String? value) {
    String pattern =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp regExp = RegExp(pattern);
    if (value!.isEmpty) {
      return false;
    } else if (!regExp.hasMatch(value)) {
      return false;
    } else {
      return true;
    }
  }

  @override
  void initState() {
    super.initState();

    // Start the registration process when the widget is initialized
    checkRegistrationStatus();
  }

  void checkRegistrationStatus() async {
    await requestLocationPermission();
    await checkPermissions();

    await doRegistration(userid);
    await Future.delayed(Duration(seconds: 3));

    if (mounted && !isEmailVerified) {
      checkRegistrationStatus();
    }
  }

  Future<void> requestLocationPermission() async {
    loc.Location location = loc.Location();
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    var status = await Permission.location.request();

    if (status.isGranted) {
      print('Location permission granted');
    } else if (status.isDenied) {
      print('Location permission denied');
      // Optionally, you can show an alert to the user to enable permissions
      await openAppSettings();
    } else if (status.isPermanentlyDenied) {
      print('Location permission permanently denied');
      // Inform the user and guide them to the system settings
    }
  }

  Future<void> checkPermissions() async {
    final locationWhenInUseStatus = await Permission.locationWhenInUse.status;
    final locationAlwaysStatus = await Permission.locationAlways.status;

    print('Location When In Use: $locationWhenInUseStatus');
    print('Location Always: $locationAlwaysStatus');
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        loadUi(),
        isLoading ? Loader(loadingTxt: 'Please wait..') : Container()
      ],
    );
  }

  @override
  Widget loadUi() {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    if (isEmailVerified) {
      // If email is verified, navigate to the ChatList page
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => ChatListnew("")));
      });
    }
    return WillPopScope(
        onWillPop: () async {
          // Call your custom logic here if needed
          _onWillPop();
          // Always return true to allow the back action
          return true;
        },
        // Your other WillPopScope properties here

        child: ScaffoldMessenger(
            key: SnakBarKey,
            child: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      height: 170,
                      padding: EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: Color(0xffe5e5e5),
                        shape: BoxShape.circle,
                      ),
                      child: SvgPicture.asset(
                        height: 50,
                        width: 50,
                        'assets/icons/email.svg',
                        colorFilter: const ColorFilter.mode(
                            Color(0xff81cff1), BlendMode.srcIn),
                      ),
                    ),
                    //  SizedBox(height: screenHeight * 0.1),
                    Text(
                      "Verify Your Email",
                      style: GoogleFonts.poppins(
                        color: Color(0xff81cff1),
                        fontWeight: FontWeight.w500,
                        fontSize: 22,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    GestureDetector(
                      child: Text(
                        "Click here to update your email",
                        style: GoogleFonts.poppins(
                            color: Colors.black45,
                            fontWeight: FontWeight.w400,
                            fontSize: 15,
                            decoration: TextDecoration.underline),
                      ),
                      onTap: () {
                        showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return StatefulBuilder(
                                builder: (context, setState) {
                                  return AlertDialog(
                                    scrollable: true,
                                    backgroundColor: Color(0xffffffff),
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      'Enter your Email',
                                      style: GoogleFonts.poppins(
                                          fontSize: 15.0, color: Colors.black),
                                    ),
                                    content: SizedBox(
                                      width: MediaQuery.of(context).size.width,
                                      child: Form(
                                        child: Column(
                                          children: <Widget>[
                                            SizedBox(height: 10),
                                            Container(
                                              decoration: kBoxDecorationStyle,
                                              height: 55.0,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 5),
                                              margin: const EdgeInsets.fromLTRB(
                                                  8, 0, 8, 5),
                                              child: TextFormField(
                                                keyboardType:
                                                    TextInputType.text,
                                                cursorColor: Colors.blue,
                                                //  validator: ValidationData.custNameValidate!,
                                                style: GoogleFonts.poppins(
                                                    fontSize: 15.0,
                                                    color: Colors.black),
                                                controller: emailcontroller,

                                                decoration: InputDecoration(
                                                  border: InputBorder.none,
                                                  contentPadding:
                                                      const EdgeInsets.only(
                                                          top: 10.0, left: 15),
                                                  hintText: ' Email Address',
                                                  hintStyle: kHintTextStyle,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Visibility(
                                                visible: emailflag,
                                                child: Container(

                                                    // height: 55.0,

                                                    margin: const EdgeInsets
                                                        .fromLTRB(10, 0, 3, 5),
                                                    child: Row(
                                                      // mainAxisAlignment: MainAxisAlignment.center,
                                                      children: <Widget>[
                                                        Text(
                                                          ' Valid Email id is required',
                                                          style: GoogleFonts
                                                              .poppins(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w300,
                                                                  color: Colors
                                                                      .red),
                                                        ),
                                                      ],
                                                    ))),
                                            SizedBox(height: 20),
                                          ],
                                        ),
                                      ),
                                    ),
                                    actions: [
                                      ElevatedButton(
                                          child: Text("Submit"),
                                          onPressed: () {
                                            bool? res = emailValidate(
                                                emailcontroller.text);
                                            if (res == true) {
                                              setState(() {
                                                emailflag = false;
                                              });
                                              Navigator.of(context).pop();
                                              doRegistration_resend(
                                                  emailcontroller.text);
                                            } else {
                                              setState(() {
                                                emailflag = true;
                                              });
                                            }

                                            // your code
                                          }),
                                      ElevatedButton(
                                          child: Text("Cancel"),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            // your code
                                          })
                                    ],
                                  );
                                },
                              );
                            });
                      },
                    ),
                    SizedBox(height: screenHeight * 0.1),

                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.poppins(
                          color: Colors.black54,
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text:
                                'We have sent a verification link to this Email id : ',
                          ),
                          TextSpan(
                            text: '$email',
                            style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.blue),
                          ),
                          TextSpan(
                              text:
                                  '. Once verified page will redirect automatically.'),
                        ],
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.06),
                    /*  Flexible(
                  child: HomeButton(
                    title: 'Continue',
                    onTap: () {
                      //  doRegistration(userid);
                    },
                  ),
                ),*/
                  ],
                ),
              ),
            )));
  }
}
