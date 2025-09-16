import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';
import 'package:geolocator/geolocator.dart';

import 'package:chatapp/screens/registration_pagenew_newgmail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart' as perm;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../controller/Constant.dart';
import '../controller/loader.dart';
import '../helper/constants.dart';
import '../helper/shared_preference.dart';
import '../main.dart';
import '../services/auth.dart';
import '../services/database.dart';
import '../widgets/button.dart';
import 'dummy_login.dart';
import 'email_verification_page.dart';

class RegistrationPagenew extends StatefulWidget {
  const RegistrationPagenew({super.key});

  @override
  State<RegistrationPagenew> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPagenew>
    with WidgetsBindingObserver {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();
  // Location location = new Location();
  bool isLoading = false;
  DatabaseMethods databaseMethods = DatabaseMethods();
  AuthService authService = AuthService();
  HelperFunctions helperFunctions = HelperFunctions();
  GlobalKey<FormState> MyKey = GlobalKey();
  TextEditingController emailcontroller = TextEditingController();
  TextEditingController firstnamecontroller = TextEditingController();
  TextEditingController gendercontroller = TextEditingController();
  TextEditingController dobcontroller = TextEditingController();
  TextEditingController passwordcontroller = TextEditingController();
  final FocusNode firstnameFocusNode = FocusNode();
  final FocusNode emailcontrollerFocusNode = FocusNode();
  bool loading = false;
  final bool _isLoading1 = false;
  bool locationperm = false;
  bool checkbob_flg = false;
  bool gender_flg = false;
  bool dobflag = false;
  bool emailflag = false;
  bool nameflag = false;
  bool nameflag1 = false;
  bool rememberMe = false;
  bool rememberMe1 = false;
  bool rememberMevis = false;
  bool rememberMevis1 = false;
  DateTime selectedDate = DateTime.now();
  String horoscopeimageurl = "";
  List<String> supplier_typelist = ["Male", 'Female', 'Non Binary'];
  loc.Location location = loc.Location();
  bool isBackgroundEnabled = false;
  final Random _random =
      Random(); // Create a Random object for generating random numbers
  int _randomNumber = 0;
  String token = "";
  final bool _isButtonDisabled = false;
  // late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;
  late FirebaseMessaging messaging;

  @override
  void initState() {
    super.initState();
    registerForNotifications();

    // requestLocationPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }


  Future<User?> signInWithFacebook() async {
    try {
      // Trigger the sign-in flow
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {
        // Get the Facebook Access Token
        final AccessToken facebookAccessToken = result.accessToken!;

        // Create a new credential
        final AuthCredential credential =
            FacebookAuthProvider.credential(facebookAccessToken.toString());

        // Sign in with the credential
        final UserCredential authResult =
            await FirebaseAuth.instance.signInWithCredential(credential);
        final User? user = authResult.user;

        // Check if the user is not null and has a valid ID token
        if (user != null) {
          assert(!user.isAnonymous);
          assert(await user.getIdToken() != null);

          final User currentUser = FirebaseAuth.instance.currentUser!;
          assert(user.uid == currentUser.uid);

          return user;
        }
      }
      return null;
    } catch (error) {
      // print("Error during Facebook sign-in: $error");
      return null;
    }
  }

  Future<void> registerForNotifications() async {
    await FirebaseMessaging.instance.requestPermission();
    messaging = FirebaseMessaging.instance;

    // Request permissions for iOS (does not affect Android)
    await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    /* if (Platform.isAndroid) {
      */ /*final fcmToken = await messaging.getToken();
      print(fcmToken);
      token = fcmToken!;*/ /*
      // Get FCM token for Android
      final fcmToken = await messaging.getToken();
      if (fcmToken != null) {
        token = fcmToken;
        print("FCM Token for Android: $token");
      }
    } else if (Platform.isIOS) {
      // For iOS, you may want to ensure that the APNS token is available
      String? apnsToken = await messaging.getAPNSToken();

      if (apnsToken != null) {
        print("APNS Token: $apnsToken");
        token = apnsToken!;
      }
      print("FCM Token for iOS: $token");
      // Get FCM token for iOS
      */ /*  final fcmToken = await messaging.getToken();
      if (fcmToken != null) {
        token = fcmToken;

      }*/ /*
    }*/

    if (Platform.isAndroid) {
      // Get FCM token for Android
      final fcmToken = await messaging.getToken();
      if (fcmToken != null) {
        token = fcmToken;
        // print("FCM Token for Android: $token");
      } else {
        // print("Failed to get FCM token for Android");
      }
    }
    if (Platform.isIOS) {
      final apnsToken = await messaging.getAPNSToken();
      print('APNS Token: $apnsToken');
        await Future.delayed(Duration(seconds: 1));

      if (apnsToken != null) {
        print("APNS Token: $apnsToken");
        await Future.delayed(const Duration(
            seconds: 2)); // Adding a delay before fetching FCM token
        final fcmToken = await messaging.getToken();
        print("FCM Token: $fcmToken");

        if (fcmToken != null) {
          token = fcmToken;
          print("FCM Token for iOS: $token");
        } else {
          print("Failed to get FCM token for iOS");
        }
      } else {
        print("Failed to get APNS token for iOS");
      }
    } else if (kIsWeb) {
      // Handle web-specific logic if necessary
    } else {
      // print("Unsupported platform");
    }

    // Use the token as needed
    // Get the token for the device

    // Subscribe to a topic
    await messaging.subscribeToTopic('flutter_notification');

    if (!kIsWeb) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'flutter_notification', // id
        'flutter_notification_title', // title
        importance: Importance.high,
        enableLights: true,
        enableVibration: true,
        showBadge: true,
        playSound: true,
      );

      flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

      const AndroidInitializationSettings android =
          AndroidInitializationSettings('@drawable/favicon_2');
      const DarwinInitializationSettings iOS = DarwinInitializationSettings();
      const InitializationSettings initSettings =
          InitializationSettings(android: android, iOS: iOS);

      final bool? initialized =
          await flutterLocalNotificationsPlugin?.initialize(
        initSettings,
        onDidReceiveNotificationResponse: notificationTapBackground,
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );

      if (initialized == null || !initialized) {
        // Handle the error of initialization
        // print("Error: flutterLocalNotificationsPlugin failed to initialize");
        return;
      }

      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Listen for foreground messages
    }
  }


  Future<void> _checkAndRequestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.locationAlways,
      Permission.locationWhenInUse,
    ].request();

    bool alwaysGranted =
        statuses[Permission.locationAlways] == PermissionStatus.granted;
    final whenInUseGranted =
        statuses[Permission.locationWhenInUse] == PermissionStatus.granted;

    setState(() {
      isBackgroundEnabled = alwaysGranted;
    });

    if (!alwaysGranted) {
      // _showPermissionDialog();
      requestLocationPermission();
    } else {
      SignMeUP();
    }

    // print('Location Always Granted: $alwaysGranted');
    // print('Location When In Use Granted: $whenInUseGranted');
    // print('Location stateenable: $isBackgroundEnabled');
  }


  String genderstr = "Gender";
  void _onRememberMeChanged(bool? newValue) => setState(() {
        rememberMe = newValue!;

        // print(rememberMe);

        if (rememberMe) {
          rememberMevis = false;
          // TODO: Here goes your functionality that remembers the user.
        } else {
          rememberMevis = true;
          // TODO: Forget the userIcon
        }
      });
  void _onRememberMeChanged_email(bool? newValue) => setState(() {
        rememberMe1 = newValue!;

        // print(rememberMe1);

        if (rememberMe1) {
          rememberMevis1 = false;
          // TODO: Here goes your functionality that remembers the user.
        } else {
          rememberMevis1 = true;
          // TODO: Forget the userIcon
        }
      });
  String? _validateDOB(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your Date of Birth';
    }
    // Add additional validation logic if needed
    return null;
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

  static bool? nameValidate(String? value) {
    if (value!.isEmpty) {
      return false;
    } else {
      return true;
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      // Check if a user is already signed in
      final GoogleSignInAccount? googleSignInAccount = googleSignIn.currentUser;

      if (googleSignInAccount != null) {
        // print("Already signed in");
        // If already signed in, return the current user
        return _auth.currentUser;
      }

      // If not signed in, perform the sign-in process
      final GoogleSignInAccount? newGoogleSignInAccount =
          await googleSignIn.signIn();

      if (newGoogleSignInAccount != null) {
        final GoogleSignInAuthentication googleSignInAuthentication =
            await newGoogleSignInAccount.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );

        final UserCredential authResult =
            await _auth.signInWithCredential(credential);
        final User? user = authResult.user;

        // Ensure user is not anonymous and has a valid token
        if (user != null) {
          assert(!user.isAnonymous);
          assert(await user.getIdToken() != null);

          final User currentUser = _auth.currentUser!;
          assert(user.uid == currentUser.uid);

          return user;
        }
      }
      return null;
    } catch (error) {
      // print("Error during Google sign-in: $error");
      return null;
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      isLoading = true;
    });

    try {
      final user = await signInWithGoogle();
      if (user != null) {
        // Navigate to your desired screen after successful sign-in

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RegistrationPagenew_newgamil(user: user),
          ),
        );
      }
    } catch (error) {
      // Handle sign-in error
      // print("Error signing in with Google: $error");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime now = DateTime.now();
    int currentYear = now.year;
    int currentMonth = now.month;
    int currentDay = now.day;

    // Calculate the minimum and maximum selectable dates
    DateTime minSelectableDate =
        DateTime(currentYear - 100, currentMonth, currentDay);
    DateTime maxSelectableDate =
        DateTime(currentYear - 16, currentMonth, currentDay);

    final ThemeData theme = Theme.of(context);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: maxSelectableDate, // 16 years before today
      initialDatePickerMode: DatePickerMode.day,
      firstDate: minSelectableDate,
      lastDate: maxSelectableDate,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: Colors.blue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        dobcontroller.text = DateFormat('dd/MM/yyyy').format(selectedDate);
      });
      _calculateAge();
      emailcontrollerFocusNode.requestFocus();
    }
  }

  void _calculateAge() {
    String ageResult = "";
    String dobString = dobcontroller.text;
    var inputFormat = DateFormat("dd/MM/yyyy");
    DateTime dob;

    try {
      dob = inputFormat.parse(dobString);
    } catch (e) {
      setState(() {
        ageResult =
            'Invalid date format. Please enter date in dd/MM/yyyy format.';
        // print(ageResult);
      });
      return;
    }

    DateTime now = DateTime.now();
    Duration difference = now.difference(dob);
    int age = difference.inDays ~/ 365;

    setState(() {
      ageResult = 'Your age is $age years.';

      // print(ageResult);
    });
  }

  Future<void> loadharoscope(int genderstr, String dob) async {
    var headers = {'Content-Type': 'application/json'};
    var request = http.Request('POST',
        Uri.parse('https://admin.connfy.at/api/check_dob'));
    request.body = json.encode({"dob": dob, "gender": genderstr});
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();
    setState(() {
      isLoading = false;
    });
    if (response.statusCode == 200) {
      setState(() {
        isLoading = false;
      });
      var responseBody = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseBody);
      String imgurl = jsonResponse['horoscope_image_url'];
      // print('Deleted user ID: $imgurl');
      setState(() {
        horoscopeimageurl = imgurl;
      });
    } else {
      // print(response.reasonPhrase);
    }
  }

  Widget privacyPolicyLinkAndTermsOfService() {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.fromLTRB(0, 5, 5, 0),
      child: Center(
          child: Text.rich(TextSpan(
              text: 'By clicking the checkbox, I accept the ',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.black26),
              children: <TextSpan>[
            TextSpan(
                text: 'terms and conditions',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    _showWebView(context,
                        'https://drive.google.com/file/d/1huwHGuTe5YrquqTGN7kreC6AjcWCbWDk/view?usp=drive_link');
                  }),
            TextSpan(
                text:
                    ' of the connfy #getsocialApp and confirm that I have read and accepted the ',
                style: GoogleFonts.poppins(
                  fontSize: 14, color: Colors.black26,
                  //  decoration: TextDecoration.underline,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    // code to open / launch terms of service link here
                  }),
            TextSpan(
                text: 'privacy policy.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    _showWebView(context,
                        'https://drive.google.com/file/d/1LJlYOZZGwhGznakSUmRQBBqp1SxYLVwW/view?usp=drive_link');
                  }),
          ]))),
    );
  }

  Widget privacyPolicyLinkAndTermsOfService_email() {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.fromLTRB(0, 5, 5, 0),
      child: Center(
          child: Text.rich(TextSpan(
              text:
                  'By clicking the checkbox, I expressly agree that I give consent to receive push notifications for marketing and advertising purposes (promotions, event information, various campaigns) from third parties in accordance with the ',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.black26),
              children: <TextSpan>[
            TextSpan(
                text: 'privacy policy.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    _showWebView(context,
                        'https://drive.google.com/file/d/1LJlYOZZGwhGznakSUmRQBBqp1SxYLVwW/view?usp=drive_link');
                  }),
          ]))),
    );
  }

  void _showWebView(BuildContext context, String url) {
    WebViewController controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(url));
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: WebViewWidget(
              controller: controller,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child:
                  Text('Close', style: GoogleFonts.poppins(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  SignMeUP() async {
    if (isLoading) return; // Prevent multiple calls

    setState(() {
      isLoading = true;
    });
    if (Platform.isIOS) {
      final apnsToken = await messaging.getAPNSToken();
      if (apnsToken != null) {
        // print("APNS Token: $apnsToken");
        await Future.delayed(const Duration(
            seconds: 2)); // Adding a delay before fetching FCM token
        final fcmToken = await messaging.getToken();
        if (fcmToken != null) {
          token = fcmToken;
          // print("FCM Token for iOS: $token");
        } else {
          // print("Failed to get FCM token for iOS");
        }
      } else {
        print("Failed to get APNS token for iOS");
      }
    }

    _randomNumber = 1000 + _random.nextInt(9000);
    String modemail = firstnamecontroller.text.trim();

    String result = modemail.replaceAll(" ", "") + _randomNumber.toString();
    // print('firebase $result');
    await authService
        .signUpWithEmailAndPassword(
            '$result@gmail.com', firstnamecontroller.text + ("@123"))
        .then((val) {
      // print("${val.uid}");

      if (val != null) {
        int gender = 0;
        if (genderstr == 'Male') {
          gender = 1;
        } else if (genderstr == 'Female') {
          gender = 2;
        } else {
          gender = 3;
        }
        doRegistration(
            val.uid.toString(),
            firstnamecontroller.text,
            dobcontroller.text,
            gender,
            emailcontroller.text.toString(),
            "",
            val.uid.toString());
      }
    });
  }


// Method to show error messages
  void showError(String errorMessage) {
    // Display the error message in your UI, for example using a SnackBar
    showSnakBar(errorMessage);
  }

  doRegistration(String mobileDeviceId, String nickName, String dob, int gender,
      String email, String ssid, String chatId) async {
    var headers = {'Content-Type': 'application/json'};
    Map<String, dynamic> data = {
      "status": 0,
      "mobile_device_id": token,
      "ssid": ssid,
      "nick_name": nickName,
      "dob": dob,
      "gender": gender,
      "email": email,
      "chat_id": chatId,
      "social_media_login": 0
    };

    try {
      var request = http.Request('POST',
          Uri.parse('https://admin.connfy.at/api/create_user'));
      request.body = json.encode(data);
      // print(json.encode(data));
      // request.headers.addAll(headers);
      request.headers['Content-Type'] = 'application/json';
      // request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();
      // print(response.statusCode);

      if (response.statusCode == 200) {
        setState(() {
          isLoading = false;
        });
        String jsonData = await response.stream.bytesToString();
        Map<String, dynamic> responseData = jsonDecode(jsonData);
        // print(responseData);

        int status = responseData['status'];
        dynamic userId = responseData['user_id'].toString();
        String message = responseData['message'];
        // print(userId);
        Constants.myName = chatId;
        Constants.loginusername = firstnamecontroller.text;

        addItemsToLocalStorage(userId, firstnamecontroller.text);
        if (message == 'Nick name already exists') {
          showSnakBar(message);
        } else {
          final time = DateTime.now().millisecondsSinceEpoch.toString();
          Map<String, dynamic> userDataMap = {
            "userName": firstnamecontroller.text,
            "userEmail": emailcontroller.text,
            'isOnline': true,
            'read': '',
            'sent': time,
            'lastActive': DateTime.now(),
            'uid': chatId,
          };

          databaseMethods.addUserInfo(userDataMap);
          HelperFunctions.saveUserLoggedInSharedPreference(true);
          HelperFunctions.saveUserEmailSharedPreference(emailcontroller.text);
          HelperFunctions.saveUserNameSharedPreference(chatId);
          // SharedPreferences prefs = await SharedPreferences.getInstance();
          //   prefs?.setBool("isLoggedIn", true);
          // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ChatListnew(firstnamecontroller.text)));
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      ThankYouPage(emailcontroller.text, userId)));
        }
      } else {
        setState(() {
          isLoading = false;
        });

        // print('response.reasonPhrase');
        // print(response.reasonPhrase);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      // print("Error creating account 6: $e");
      //
      // print('$e');
    }
  }

  void parseResponseData(Map<String, dynamic> userData) {
    // Extract data from responseData and handle it as needed
    // For example:
    String userId = userData['user_id'];
    String status = userData['status'];

    //  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ChatList("")));
    // Access more fields as needed

    // print('User ID: $userId');
    // print('Status: $status');
    // Print or handle more fields as needed
  }

  Future<void> addItemsToLocalStorage(String UserId, String username) async {
    // print('loginuser $username');
    // print(UserId);
    SharedPreferences storage = await SharedPreferences.getInstance();

    storage.setString(
      'UserId',
      UserId,
    );
    storage.setString(
      'loginuser',
      username,
    );
    storage.setString(
      'uemail',
      emailcontroller.text,
    );

    /* final info = json.encode({'name': 'Darush', 'family': 'Roshanzami'});
    storage.setItem('info', info);*/
  }

  void ValidateFunction() {
    if (firstnamecontroller.text.isEmpty) {
      showSnakBar("First name is empty");
    } else if (dobcontroller.text.isEmpty) {
      showSnakBar("Last name is empty");
    } else if (gendercontroller.text.isEmpty) {
      showSnakBar("Email is Empty");
      return;
    } else if (!isValidEmail(emailcontroller.text)) {
      showSnakBar("Please Enter a valid email");
    } else {
      //  Register();
    }
  }

  void validateData() {
    // Improved logging for clarity
    print(
        'Flags - Name: $nameflag, DOB: $dobflag, Email: $emailflag, Gender: $gender_flg, Remember Me: $rememberMe');
    print('Background Enabled: $isBackgroundEnabled');

    // Validation logic
    if (!nameflag &&
        !dobflag &&
        !emailflag &&
        !gender_flg &&
        rememberMe &&
        rememberMe1) {
      if (Platform.isAndroid) {
        _checkAndRequestPermissions();
      } else if (Platform.isIOS) {
        requestLocationPermission();
      }
      // Uncomment and use if necessary
      // showAlertDialog(context, "Confirm Password", "Passwords are not same");
    } else {
      // Handle validation errors (e.g., show an error message to the user)
      showValidationError();
    }
  }
  
void showPermissionSettingsDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: const Text('Permission Required'),
      content: const Text(
          'Location permission is required for this feature. Please enable it in settings.'),
      actions: [
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: const Text('Open Settings'),
          onPressed: () async {
            Navigator.of(context).pop();
            await openAppSettings();
            // Check permission status again after returning from settings
            await Future.delayed(const Duration(seconds: 1));
            PermissionStatus status = await Permission.location.status;
            if (status.isGranted) {
              SignMeUP();
            }
          },
        ),
      ],
    ),
  );
}
//removed for ios specific case by refay
  // Future<void> requestLocationPermission() async {
  //   // Location location = Location();

  //   // Check if location services are enabled
  //   bool serviceEnabled = await location.serviceEnabled();
  //   if (!serviceEnabled) {
  //     serviceEnabled = await location.requestService();
  //     if (!serviceEnabled) {
  //       print('Location services are disabled.');
  //       return;
  //     }
  //   }

  //   // Request location permission
  //   PermissionStatus status = await Permission.location.request();

  //   if (status.isGranted) {
  //     print('Location permission granted');
  //     SignMeUP(); // Call your function here
  //   } else if (status.isDenied) {
  //     print('Location permission denied');
  //     await openAppSettings(); // Direct user to settings
  //   } else if (status.isPermanentlyDenied) {
  //     print('Location permission permanently denied');
  //     showPermissionDeniedDialog(); // Show a custom dialog
  //   } else if (status.isRestricted) {
  //     print('Location permission is restricted (iOS-specific case)');
  //   }
  // }
Future<void> requestLocationPermission() async {
  // First check if services are enabled
  bool serviceEnabled = await location.serviceEnabled();
  if (!serviceEnabled) {
    serviceEnabled = await location.requestService();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      return;
    }
  }

  // Request WhenInUse first (iOS best practice)
  var status = await Permission.locationWhenInUse.request();
  debugPrint('Current location permission status: $status');

  if (status.isGranted) {
    // Then request Always if needed
    if (isBackgroundEnabled) {
      var alwaysStatus = await Permission.locationAlways.request();
      if (alwaysStatus.isGranted) {
        print('Background location granted');
        SignMeUP();
      } else {
        print('Background location denied');
        SignMeUP(); // Still proceed with foreground location
      }
    } else {
      SignMeUP();
    }
  } else if (status.isPermanentlyDenied) {
    showPermissionSettingsDialog();
  } else {
    print('Location permission denied');
  }
}

void showPermissionDeniedDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: const Text('Location Permission Required'),
      content: const Text(
        'Location permission is required for app functionality. Please enable it in Settings.',
      ),
      actions: [
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: const Text('Open Settings'),
          onPressed: () {
            Navigator.of(context).pop();
            openAppSettings();
          },
        ),
      ],
    ),
  );
}

  void showValidationError() {
    // Implement user feedback for validation errors
    print('Validation error: Please fill out all required fields.');
  }

  // void showPermissionDeniedDialog() {
  //   // Show an alert dialog to guide the user to system settings
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) => AlertDialog(
  //       title: const Text('Permission Required'),
  //       content: const Text(
  //           'Location permission is permanently denied. Please enable it in the device settings.'),
  //       actions: [
  //         TextButton(
  //           onPressed: () {
  //             Navigator.of(context).pop();
  //             openAppSettings();
  //           },
  //           child: const Text('Open Settings'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Future Register() async {
    try {
      setState(() {
        loading = true;
      });
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailcontroller.text,
        password: passwordcontroller.text,
      );
      showSnakBar("Account Created Successfully");
      emailcontroller.clear();
      passwordcontroller.clear();
      setState(() {
        loading = false;
      });
    } catch (e) {
      print("Error creating account 1: $e");
      showSnakBar("Failed to create account: $e");
      print('$e');
    }
  }

  // Function to validate email using a regular expression
  bool isValidEmail(String email) {
    final emailRegExp = RegExp(r'^[\w-]+(\.[\w-]+)*@[\w-]+(\.[\w-]+)+$');
    return emailRegExp.hasMatch(email);
  }

  // snackbar function
  void showSnakBar(String message) {
    final snakbar = SnackBar(
      content: Text(message),
      backgroundColor: Colors.redAccent,
      duration: const Duration(seconds: 4),
    );
    SnakBarKey.currentState?.showSnackBar(snakbar);
  }

  final SnakBarKey = GlobalKey<ScaffoldMessengerState>();

  String _onDropDownChanged_stype(String val) {
    String prefix;
    if (val.isNotEmpty) {
      prefix = val;
    } else {
      prefix = "Gender";
    }

    return prefix;
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
    double deviseWidth = MediaQuery.of(context).size.width;
    return WillPopScope(
        onWillPop: () async {
          return false;
        },
        child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.blueGrey,
            ),
            home: DefaultTabController(
              length: 2,
              child: Container(
                child: ScaffoldMessenger(
                  key: SnakBarKey,
                      child: Scaffold(

                        backgroundColor: const Color(0xffffffff),
                        body: SingleChildScrollView(
                            child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              height: 55,
                            ),
                            Container(
                              decoration:
                                  const BoxDecoration(color: Colors.transparent),
                              // alignment: Alignment.center,
                              height: 100,
                              child: Container(
                                width: 200.0,
                                height: 130.0,
                                decoration: const BoxDecoration(
                                  image: DecorationImage(
                                    image: AssetImage('assets/images/appicon.png'),
                                    fit: BoxFit.fill,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 75,
                            ),
                            Container(
                              color: const Color(0xFFf0f0f0),
                              width: double.infinity,

                              //  padding: EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                              //  margin: EdgeInsets.symmetric(vertical: 165, horizontal: 20),

                              child: Container(
                                margin: const EdgeInsets.only(
                                    top: 0.0, left: 0, right: 0),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      color: const Color(0xFFe5e5e5),
                                      child: SizedBox(
                                          width: MediaQuery.of(context).size.width,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              const SizedBox(
                                                height: 60,
                                              ),
                                              const SizedBox(
                                                height: 30,
                                              ),

                                              // wellcome message

                                              //Textfiled

                                              Form(
                                                  key: MyKey,
                                                  child: Column(
                                                    children: [
                                                      Container(
                                                        decoration:
                                                            kBoxDecorationStyle,
                                                        height: 55.0,
                                                        padding: const EdgeInsets
                                                            .symmetric(
                                                            horizontal: 5),
                                                        margin: const EdgeInsets
                                                            .fromLTRB(8, 0, 8, 5),
                                                        child: TextFormField(
                                                          cursorColor: Colors.blue,
                                                          keyboardType:
                                                              TextInputType.text,
                                                          enableInteractiveSelection:
                                                              false,
                                                          //  validator: ValidationData.custNameValidate!,
                                                          style:
                                                              GoogleFonts.poppins(
                                                                  fontSize: 15.0,
                                                                  color:
                                                                      Colors.black),
                                                          controller:
                                                              firstnamecontroller,
                                                          focusNode:
                                                              firstnameFocusNode,
                                                          decoration:
                                                              InputDecoration(
                                                            border:
                                                                InputBorder.none,
                                                            contentPadding:
                                                                const EdgeInsets
                                                                    .only(
                                                                    top: 10.0,
                                                                    left: 15),
                                                            hintText: ' Nick Name',
                                                            hintStyle:
                                                                kHintTextStyle,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 3),
                                                      Visibility(
                                                          visible: nameflag,
                                                          child: Container(

                                                              // height: 55.0,

                                                              margin:
                                                                  const EdgeInsets
                                                                      .fromLTRB(
                                                                      10, 0, 3, 5),
                                                              child: Row(
                                                                // mainAxisAlignment: MainAxisAlignment.center,
                                                                children: <Widget>[
                                                                  Text(
                                                                    ' Name is required ',
                                                                    style: GoogleFonts.poppins(
                                                                        fontSize:
                                                                            12,
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .w300,
                                                                        color: Colors
                                                                            .red),
                                                                  ),
                                                                ],
                                                              ))),
                                                      Visibility(
                                                          visible: nameflag1,
                                                          child: Container(

                                                              // height: 55.0,

                                                              margin:
                                                                  const EdgeInsets
                                                                      .fromLTRB(
                                                                      10, 0, 3, 5),
                                                              child: Row(
                                                                // mainAxisAlignment: MainAxisAlignment.center,
                                                                children: <Widget>[
                                                                  Text(
                                                                    ' Name can only contain letters, numbers, and underscores',
                                                                    style: GoogleFonts.poppins(
                                                                        fontSize:
                                                                            12,
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .w300,
                                                                        color: Colors
                                                                            .red),
                                                                  ),
                                                                ],
                                                              ))),
                                                      const SizedBox(height: 5),
                                                      InkWell(
                                                          onTap: () {
                                                            _selectDate(context);
                                                          },
                                                          child: Container(
                                                              decoration:
                                                                  kBoxDecorationStyle,
                                                              height: 55.0,
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          5),
                                                              margin:
                                                                  const EdgeInsets
                                                                      .fromLTRB(
                                                                      8, 0, 8, 5),
                                                              child: Row(
                                                                children: <Widget>[
                                                                  Expanded(
                                                                    child:
                                                                        TextField(
                                                                      cursorColor:
                                                                          Colors
                                                                              .blue,
                                                                      style: GoogleFonts.poppins(
                                                                          fontSize:
                                                                              15.0,
                                                                          color: Colors
                                                                              .black),
                                                                      //  validator: ValidationData.custNameValidate!,
                                                                      controller:
                                                                          dobcontroller,
                                                                      decoration:
                                                                          InputDecoration(
                                                                        border:
                                                                            InputBorder
                                                                                .none,
                                                                        enabled:
                                                                            false,
                                                                        contentPadding: const EdgeInsets
                                                                            .only(
                                                                            top:
                                                                                10.0,
                                                                            left:
                                                                                15),
                                                                        hintText:
                                                                            ' Date of Birth',
                                                                        hintStyle:
                                                                            kHintTextStyle,
                                                                        // border: border,
                                                                        //errorBorder: border,
                                                                        // disabledBorder: border,
                                                                        // focusedBorder: border,
                                                                        //  focusedErrorBorder: border,
                                                                        suffixIcon:
                                                                            IconButton(
                                                                          onPressed:
                                                                              () {},
                                                                          icon: SvgPicture
                                                                              .asset(
                                                                            'assets/icons/calendar-fill.svg',
                                                                            colorFilter: const ColorFilter
                                                                                .mode(
                                                                                Color(0xff03A0E3),
                                                                                BlendMode.srcIn),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  Container()
                                                                ],
                                                              ))),
                                                      const SizedBox(height: 3),
                                                      Visibility(
                                                          visible: dobflag,
                                                          child: Container(

                                                              // height: 55.0,

                                                              margin:
                                                                  const EdgeInsets
                                                                      .fromLTRB(
                                                                      10, 0, 3, 5),
                                                              child: Row(
                                                                // mainAxisAlignment: MainAxisAlignment.center,
                                                                children: <Widget>[
                                                                  Text(
                                                                    ' Date of Birth is required',
                                                                    style: GoogleFonts.poppins(
                                                                        fontSize:
                                                                            12,
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .w300,
                                                                        color: Colors
                                                                            .red),
                                                                  ),
                                                                ],
                                                              ))),
                                                      const SizedBox(
                                                        height: 5,
                                                      ),
                                                      Container(
                                                          decoration:
                                                              kBoxDecorationStyle,
                                                          height: 55.0,
                                                          padding: const EdgeInsets
                                                              .symmetric(
                                                              horizontal: 5),
                                                          margin: const EdgeInsets
                                                              .fromLTRB(8, 0, 8, 5),
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .fromLTRB(
                                                                    8, 10, 8, 5),
                                                            child: DropdownButton<
                                                                    String>(
                                                                isExpanded: true,
                                                                isDense: true,
                                                                underline:
                                                                    const SizedBox(),
                                                                hint: Padding(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .fromLTRB(
                                                                            8,
                                                                            5,
                                                                            8,
                                                                            5),
                                                                    child: genderstr ==
                                                                            "Gender"
                                                                        ? Text(
                                                                            _onDropDownChanged_stype(
                                                                                genderstr),
                                                                            style:
                                                                                kHintTextStyle,
                                                                          )
                                                                        : Text(
                                                                            _onDropDownChanged_stype(
                                                                                genderstr),
                                                                            style: GoogleFonts
                                                                                .poppins(
                                                                              color:
                                                                                  Colors.black87,
                                                                              // fontWeight: FontWeight.w400,
                                                                            ),
                                                                          )),
                                                                icon: const Icon(
                                                                  Icons
                                                                      .arrow_drop_down,
                                                                  color: Colors
                                                                      .black45,
                                                                ),
                                                                iconSize: 30,
                                                                //  value: newversionid,
                                                                onChanged: (value) {
                                                                  setState(() {
                                                                    if (value!
                                                                        .isNotEmpty) {
                                                                      genderstr =
                                                                          value;
                                                                      int gender =
                                                                          -1;
                                                                      if (genderstr ==
                                                                          'Male') {
                                                                        gender = 1;
                                                                      } else if (genderstr ==
                                                                          'Female') {
                                                                        gender = 2;
                                                                      } else {
                                                                        gender = 3;
                                                                      }

                                                                      loadharoscope(
                                                                          gender,
                                                                          dobcontroller
                                                                              .text);
                                                                    }
                                                                  });
                                                                },

                                                                //
                                                                items:
                                                                    supplier_typelist
                                                                        .map(
                                                                            (value) {
                                                                  return DropdownMenuItem<
                                                                      String>(
                                                                    value: value
                                                                        .toString(),
                                                                    child: Text(
                                                                      value.isNotEmpty
                                                                          ? value
                                                                              .toString()
                                                                          : "",
                                                                      style: const TextStyle(
                                                                          fontSize:
                                                                              12),
                                                                    ),
                                                                  );
                                                                }).toList()),
                                                          )),
                                                      Visibility(
                                                          visible: gender_flg,
                                                          child: Container(

                                                              // height: 55.0,

                                                              margin:
                                                                  const EdgeInsets
                                                                      .fromLTRB(
                                                                      10, 0, 3, 5),
                                                              child: Row(
                                                                // mainAxisAlignment: MainAxisAlignment.center,
                                                                children: <Widget>[
                                                                  Text(
                                                                    'Select Gender',
                                                                    style: GoogleFonts.poppins(
                                                                        fontSize:
                                                                            12,
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .w300,
                                                                        color: Colors
                                                                            .red),
                                                                  ),
                                                                ],
                                                              ))),
                                                      const SizedBox(
                                                        height: 3,
                                                      ),
                                                      const SizedBox(
                                                        height: 5,
                                                      ),
                                                      Container(
                                                        decoration:
                                                            kBoxDecorationStyle,
                                                        height: 55.0,
                                                        padding: const EdgeInsets
                                                            .symmetric(
                                                            horizontal: 5),
                                                        margin: const EdgeInsets
                                                            .fromLTRB(8, 0, 8, 5),
                                                        child: TextFormField(
                                                          cursorColor: Colors.blue,
                                                          keyboardType:
                                                              TextInputType.text,

                                                          //  validator: ValidationData.custNameValidate!,
                                                          style:
                                                              GoogleFonts.poppins(
                                                                  fontSize: 15.0,
                                                                  color:
                                                                      Colors.black),
                                                          controller:
                                                              emailcontroller,
                                                          focusNode:
                                                              emailcontrollerFocusNode,
                                                          decoration:
                                                              InputDecoration(
                                                            border:
                                                                InputBorder.none,
                                                            contentPadding:
                                                                const EdgeInsets
                                                                    .only(
                                                                    top: 10.0,
                                                                    left: 15),
                                                            hintText:
                                                                ' Email Address',
                                                            hintStyle:
                                                                kHintTextStyle,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 3),
                                                      Visibility(
                                                          visible: emailflag,
                                                          child: Container(

                                                              // height: 55.0,

                                                              margin:
                                                                  const EdgeInsets
                                                                      .fromLTRB(
                                                                      10, 0, 3, 5),
                                                              child: Row(
                                                                // mainAxisAlignment: MainAxisAlignment.center,
                                                                children: <Widget>[
                                                                  Text(
                                                                    ' Valid Email id is required',
                                                                    style: GoogleFonts.poppins(
                                                                        fontSize:
                                                                            12,
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .w300,
                                                                        color: Colors
                                                                            .red),
                                                                  ),
                                                                ],
                                                              ))),
                                                      const SizedBox(
                                                        height: 5,
                                                      ),
                                                      Container(

                                                          // height: 55.0,

                                                          margin: const EdgeInsets
                                                              .fromLTRB(8, 0, 8, 8),
                                                          child: Row(
                                                            // mainAxisAlignment: MainAxisAlignment.center,
                                                            children: <Widget>[
                                                              Container(
                                                                  child: Checkbox(
                                                                value: rememberMe,
                                                                onChanged:
                                                                    _onRememberMeChanged,
                                                                activeColor:
                                                                    const Color(
                                                                        0xff03A0E3),
                                                              )),
                                                              Expanded(
                                                                child:
                                                                    privacyPolicyLinkAndTermsOfService(),
                                                              )
                                                            ],
                                                          )),
                                                      const SizedBox(
                                                        height: 3,
                                                      ),
                                                      rememberMevis == true
                                                          ? Visibility(
                                                              visible: true,
                                                              child: Container(

                                                                  // height: 55.0,

                                                                  margin:
                                                                      const EdgeInsets
                                                                          .fromLTRB(
                                                                          10,
                                                                          0,
                                                                          3,
                                                                          5),
                                                                  child: Row(
                                                                    // mainAxisAlignment: MainAxisAlignment.center,
                                                                    children: <Widget>[
                                                                      Text(
                                                                        'Please accept the terms and conditions.',
                                                                        style: GoogleFonts.poppins(
                                                                            fontSize:
                                                                                12,
                                                                            fontWeight:
                                                                                FontWeight
                                                                                    .w300,
                                                                            color: Colors
                                                                                .red),
                                                                      ),
                                                                    ],
                                                                  )))
                                                          : Container(),
                                                      const SizedBox(
                                                        height: 3,
                                                      ),
                                                      Container(

                                                          // height: 55.0,

                                                          margin: const EdgeInsets
                                                              .fromLTRB(8, 0, 8, 8),
                                                          child: Row(
                                                            // mainAxisAlignment: MainAxisAlignment.center,
                                                            children: <Widget>[
                                                              Container(
                                                                  child: Checkbox(
                                                                value: rememberMe1,
                                                                onChanged:
                                                                    _onRememberMeChanged_email,
                                                                activeColor:
                                                                    const Color(
                                                                        0xff03A0E3),
                                                              )),
                                                              Expanded(
                                                                child:
                                                                    privacyPolicyLinkAndTermsOfService_email(),
                                                              )
                                                            ],
                                                          )),
                                                      const SizedBox(
                                                        height: 3,
                                                      ),
                                                      rememberMevis1 == true
                                                          ? Visibility(
                                                              visible: true,
                                                              child: Container(

                                                                  // height: 55.0,

                                                                  margin:
                                                                      const EdgeInsets
                                                                          .fromLTRB(
                                                                          10,
                                                                          0,
                                                                          3,
                                                                          5),
                                                                  child: Row(
                                                                    // mainAxisAlignment: MainAxisAlignment.center,
                                                                    children: <Widget>[
                                                                      Text(
                                                                        'Please agree the consent form.',
                                                                        style: GoogleFonts.poppins(
                                                                            fontSize:
                                                                                12,
                                                                            fontWeight:
                                                                                FontWeight
                                                                                    .w300,
                                                                            color: Colors
                                                                                .red),
                                                                      ),
                                                                    ],
                                                                  )))
                                                          : Container(),
                                                      const SizedBox(
                                                        height: 10,
                                                      ),
                                                      MyButoon(
                                                        loading: loading,
                                                        onPressed: () {
                                                          bool? res = emailValidate(
                                                              emailcontroller.text
                                                                  .trim());
                                                          bool? res2 = nameValidate(
                                                              firstnamecontroller
                                                                  .text);

                                                          if (res == true) {
                                                            setState(() {
                                                              emailflag = false;
                                                            });
                                                          } else {
                                                            setState(() {
                                                              emailflag = true;
                                                            });
                                                          }

                                                          if (res2 == true) {
                                                            setState(() {
                                                              nameflag = false;
                                                            });

                                                            /*  bool? res3 = nameValidate1(firstnamecontroller.text!);
                                                            print(res3);

                                                            if (res3 == true) {
                                                              setState(() {
                                                                nameflag1 = false;
                                                              });
                                                            } else {
                                                              setState(() {
                                                                nameflag1 = true;
                                                              });
                                                            }*/
                                                          } else {
                                                            setState(() {
                                                              nameflag = true;
                                                            });
                                                          }

                                                          print('Rest $res');
                                                          if (dobcontroller
                                                              .text.isEmpty) {
                                                            setState(() {
                                                              dobflag = true;
                                                            });
                                                          } else {
                                                            setState(() {
                                                              dobflag = false;
                                                            });
                                                          }

                                                          /* if (firstnamecontroller.text.isEmpty) {
                                                            setState(() {
                                                              nameflag = true;
                                                            });
                                                          } else {
                                                            setState(() {
                                                              nameflag = false;
                                                            });
                                                          }*/
                                                          if (genderstr ==
                                                              'Gender') {
                                                            setState(() {
                                                              gender_flg = true;
                                                            });
                                                          } else {
                                                            setState(() {
                                                              gender_flg = false;
                                                            });
                                                          }
                                                          if (rememberMe) {
                                                            setState(() {
                                                              rememberMevis = false;
                                                            });
                                                          } else {
                                                            print(
                                                                "$rememberMevis-----$rememberMe");
                                                            setState(() {
                                                              rememberMevis = true;
                                                            });
                                                          }

                                                          if (rememberMe1) {
                                                            setState(() {
                                                              rememberMevis1 =
                                                                  false;
                                                            });
                                                          } else {
                                                            print(
                                                                "$rememberMevis1-----$rememberMe1");
                                                            setState(() {
                                                              rememberMevis1 = true;
                                                            });
                                                          }

                                                          validateData();
                                                          //  Navigator.of(context).push(MaterialPageRoute(builder: (context) => ChatList("")));

                                                          // ValidateFunction();
                                                        },
                                                        title: 'Submit',
                                                      ),
                                                      const SizedBox(
                                                        height: 15,
                                                      ),
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          // Container(
                                                          //   height: 1,
                                                          //   width:
                                                          //       deviseWidth * .40,
                                                          //   color: const Color(
                                                          //       0xffA2A2A2),
                                                          // ),
                                                          // const SizedBox(
                                                          //   width: 10,
                                                          // ),
                                                          // Text(
                                                          //   'OR',
                                                          //   style: TextStyle(
                                                          //     fontSize:
                                                          //         deviseWidth *
                                                          //             .040,
                                                          //   ),
                                                          // ),
                                                          // const SizedBox(
                                                          //   width: 10,
                                                          // ),
                                                          // Container(
                                                          //   height: 1,
                                                          //   width:
                                                          //       deviseWidth * .40,
                                                          //   color: const Color(
                                                          //       0xffA2A2A2),
                                                          // ),
                                                        ],
                                                      ),
                                                      const SizedBox(
                                                        height: 15,
                                                      ),
                                                      // Row(
                                                      //   mainAxisAlignment:
                                                      //       MainAxisAlignment
                                                      //           .spaceEvenly,
                                                      //   children: [
                                                      //     SizedBox.fromSize(
                                                      //       size:
                                                      //           const Size(56, 56),
                                                      //       child: ClipOval(
                                                      //         child: Material(
                                                      //           color: Colors.white,
                                                      //           child:
                                                      //               GestureDetector(
                                                      //             onTap: () {
                                                      //               // Handle tap event...
                                                      //               _signInWithGoogle();
                                                      //             },
                                                      //             child:
                                                      //                 const Column(
                                                      //               mainAxisAlignment:
                                                      //                   MainAxisAlignment
                                                      //                       .center,
                                                      //               children: <Widget>[
                                                      //                 Icon(
                                                      //                   FontAwesomeIcons
                                                      //                       .google,
                                                      //                   color: Colors
                                                      //                       .red,
                                                      //                 ), // <-- Icon
                                                      //                 // <-- Text
                                                      //               ],
                                                      //             ),
                                                      //           ),
                                                      //         ),
                                                      //       ),
                                                      //     ),
                                                      //     SizedBox.fromSize(
                                                      //       size:
                                                      //           const Size(56, 56),
                                                      //       child: ClipOval(
                                                      //         child: Material(
                                                      //           color:
                                                      //               Colors.white54,
                                                      //           child: InkWell(
                                                      //             //    splashColor: Colors.blue,
                                                      //             onTap: () {
                                                      //               showSnakBar(
                                                      //                   "Coming Soon !");
                                                      //               //  signInWithFacebook();
                                                      //             },
                                                      //             child:
                                                      //                 const Column(
                                                      //               mainAxisAlignment:
                                                      //                   MainAxisAlignment
                                                      //                       .center,
                                                      //               children: <Widget>[
                                                      //                 Icon(
                                                      //                   FontAwesomeIcons
                                                      //                       .facebookF,
                                                      //                   color: Color(
                                                      //                       0xff03A0E3),
                                                      //                 ), // <-- Icon
                                                      //                 // <-- Text
                                                      //               ],
                                                      //             ),
                                                      //           ),
                                                      //         ),
                                                      //       ),
                                                      //     )
                                                      //   ],
                                                      // ),
                                                      const SizedBox(
                                                        height: 15,
                                                      ),
                                                    ],
                                                  )),

                                              // Register
                                            ],
                                          )),
                                    ),

                                    horoscopeimageurl.isEmpty
                                        ? Positioned(
                                            width:
                                                MediaQuery.of(context).size.width,
                                            top: -75,
                                            child: Container(
                                              height: 120,
                                              width: 120,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                    width: 1, color: Colors.blue),
                                                image: const DecorationImage(
                                                  image: AssetImage(
                                                      'assets/images/newlogo.gif'),
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                            ),
                                          )
                                        : Positioned(
                                            width:
                                                MediaQuery.of(context).size.width,
                                            top: -75,
                                            child: Container(
                                              height: 120,
                                              width: 120,
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                              ),
                                              child: ClipOval(
                                                child: Image.network(
                                                  horoscopeimageurl,
                                                  fit: BoxFit.contain,
                                                  loadingBuilder:
                                                      (BuildContext context,
                                                          Widget child,
                                                          ImageChunkEvent?
                                                              loadingProgress) {
                                                    if (loadingProgress == null) {
                                                      return child;
                                                    } else {
                                                      return Center(
                                                        child:
                                                            CircularProgressIndicator(
                                                          valueColor:
                                                              const AlwaysStoppedAnimation<
                                                                      Color>(
                                                                  Color(
                                                                      0xff03A0E3)),
                                                          value: loadingProgress
                                                                      .expectedTotalBytes !=
                                                                  null
                                                              ? loadingProgress
                                                                      .cumulativeBytesLoaded /
                                                                  loadingProgress
                                                                      .expectedTotalBytes!
                                                              : null,
                                                        ),
                                                      );
                                                    }
                                                  },
                                                  errorBuilder:
                                                      (BuildContext context,
                                                          Object exception,
                                                          StackTrace? stackTrace) {
                                                    return const Icon(Icons.error);
                                                  },
                                                ),
                                              ),
                                            ),
                                          )

                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                          ],
                        )),
                      ),
                    ),
                  ),
            ),
              ),
            );
  }
}
