import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:localstorage/localstorage.dart';
import 'package:provider/provider.dart';

import '../constants/NotificationService.dart';
import '../helper/constants.dart';
import '../main.dart';
import '../widgets/textfield.dart';
import 'NetworkService.dart';
import 'chats.dart';

class ProfilePage extends StatefulWidget {
  final chatRoomId, uid, username, routeid, user_id, imageurl, token;

  const ProfilePage(this.chatRoomId, this.uid, this.username, this.routeid,
      this.user_id, this.imageurl, this.token,
      {super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState(
      chatRoomId, uid, username, routeid, user_id, imageurl, token);
}

class _ProfilePageState extends State<ProfilePage> {
  var chatRoomId, uid, username, routeid, user_id, imageurl, token;
  _ProfilePageState(this.chatRoomId, this.uid, this.username, this.routeid,
      this.user_id, this.imageurl, this.token);
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final dobController = TextEditingController();
  final genderController = TextEditingController();
  final blockController = TextEditingController();
  final flatController = TextEditingController();
  final gstController = TextEditingController();
  final ageController = TextEditingController();
  String? maincharacter = "";
  String name = "";
  String mobileno = "";
  String? UserId = "";
  String? horoscopeImageUrl = "";
  String? strengths = "";
  String? weaknesses = "";
  bool isInitializing = true;
//  final LocalStorage storage = new LocalStorage('wifi');
  String config_wifi = "emty";
  final bool _isLoading = false;
  bool _refreshListCalled = false;
  Future<void> _initializeNetworkStatus() async {
    // Simulate a delay to fetch network status (if needed)
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      isInitializing = false;
    });
  }

  FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;
  late FirebaseMessaging messaging;
  Future<void> registerForNotifications() async {
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
        print("Error: flutterLocalNotificationsPlugin failed to initialize");
        return;
      }

      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        print('Handling a foreground message: ${message.messageId}');
        print('Notification Message: ${message.data}');

        final data = message.data;
        final title = data['title'] ?? '';
        final body = data['body'] ?? '';
        final imageUrl = data['image'] ?? '';

        if (data.isEmpty) {
          print('Received message data is null or empty');
          return; // Exit if data is null or empty
        } else {
          if (imageUrl.isNotEmpty) {
            navigatorKey.currentState?.popUntil((route) => route.isFirst);

            /*  if (_isDialogOpen) {
              Navigator.of(navigatorKey.currentState!.context, rootNavigator: true).pop();
              _isDialogOpen = false;
            }*/
            //  showNotificationDialog(title, body, imageUrl);
            //   await NotificationService().showNotificationWithImage(title, body, imageUrl);
          } else {
            //  NotificationService().showNotification(title: title, body: body);
          }
        }

        // Show notification
      });

      // Listen for background messages
      FirebaseMessaging.onBackgroundMessage((RemoteMessage message) async {
        print('Handling a background message: ${message.messageId}');
        print('Notification Message: ${message.data}');

        final data = message.data;
        final title = data['title'] ?? '';
        final body = data['body'] ?? '';
        final imageUrl = data['image'] ?? '';

        if (data.isEmpty) {
          print('Received message data is null or empty');
          return; // Exit if data is null or empty
        } else {
          if (imageUrl.isNotEmpty) {
            // Show notification dialog if image URL is provided
            //  showNotificationDialog(title, body, imageUrl);
            await NotificationService()
                .showNotificationWithImage(title, body, imageUrl);
          }

          NotificationService().showNotification(title: title, body: body);
        }

        // Show notification
      });
    }
  }

  bool _isDialogOpen = false;

  void showNotificationDialog(String title, String body, String imageUrl) {
    // Close any existing dialog
    if (_isDialogOpen) {
      Navigator.of(navigatorKey.currentState!.context, rootNavigator: true)
          .pop();
      _isDialogOpen = false;
    }

    _isDialogOpen = true;

    showDialog<void>(
      context: navigatorKey.currentState!.context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: GoogleFonts.poppins(
                color: Colors.blue, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (imageUrl.isNotEmpty)
                FutureBuilder(
                  future: precacheImage(NetworkImage(imageUrl), context),
                  builder:
                      (BuildContext context, AsyncSnapshot<void> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 100,
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xff03A0E3)),
                          ),
                        ),
                      );
                    } else {
                      return Image.network(
                        imageUrl,
                        height: 200,
                        width: 200,
                        fit: BoxFit.contain,
                      );
                    }
                  },
                ),
              Text(body,
                  style:
                      GoogleFonts.poppins(color: Colors.black54, fontSize: 15)),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _isDialogOpen = false;
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    ).then((_) {
      _isDialogOpen = false;
    });
  }

  @override
  void initState() {
    super.initState();
    registerForNotifications();
    _initializeNetworkStatus();
    retrive();
  }

  AppBar buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      titleSpacing: 0,
      title: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile',
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black),
              ),
            ],
          ),
        ],
      ),
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios,
          color: Colors.lightBlue,
        ),
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => Chat(chatRoomId, uid, username, routeid,
                  user_id, imageurl, Constants.myName, token)));
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {},
        ),
      ],
    );
  }

  void _calculateAge() {
    String ageResult = "";
    String dobString = dobController.text;
    var inputFormat = DateFormat("dd/MM/yyyy");
    DateTime dob;

    try {
      dob = inputFormat.parse(dobString);
    } catch (e) {
      setState(() {
        ageResult =
            'Invalid date format. Please enter date in dd/MM/yyyy format.';
        print(ageResult);
      });
      return;
    }

    DateTime now = DateTime.now();
    Duration difference = now.difference(dob);
    int age = difference.inDays ~/ 365;

    setState(() {
      ageResult = 'Your age is $age years.';
      ageController.text = age.toString();
      print(ageResult);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFe5e5e5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        titleSpacing: 0,
        title: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profile',
                  style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue),
                ),
              ],
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.lightBlue,
          ),
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => Chat(chatRoomId, uid, username, routeid,
                    user_id, imageurl, Constants.myName, token)));
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.more_vert,
              color: Colors.white,
            ),
            onPressed: () {},
          ),
        ],
      ), // Placeholder for buildAppBar()
      body: isInitializing
          ? const Center(
              child: Center(
                  child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xff03A0E3)),
            )))
          : Consumer<NetworkService>(
              builder: (context, networkService, child) {
                String wifiName =
                    networkService.wifiName?.toString().replaceAll('"', '') ??
                        '';
                bool isConnectedToConfiguredWifi = wifiName == config_wifi;

                if (networkService.networkStatus == NetworkStatus.Online &&
                    isConnectedToConfiguredWifi) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {});
                  if (!_refreshListCalled) {
                    _refreshListCalled = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      retrive();
                    });
                  }

                  return _buildConnectedUI(context);
                } else {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    //   retrive();
                  });
                  //   return _buildConnectedUI(context);
                  return _buildDisconnectedUI();
                }
              },
            ),
    );
  }

  Widget _buildConnectedUI(BuildContext context) {
    return ListView(
      children: [
        Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(0),
            ),
            color: Color(0xFFffffff),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
                height: 120,
                width: 120,
                child: CachedNetworkImage(
                  imageUrl: horoscopeImageUrl!,
                  placeholder: (context, url) => Image.asset(
                      'assets/images/photo.png',
                      fit: BoxFit.contain),
                  errorWidget: (context, url, error) => Image.asset(
                      'assets/images/photo.png',
                      fit: BoxFit.contain),
                  fit: BoxFit.contain,
                  height: 120,
                  width: 120,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                maincharacter!,
                style: GoogleFonts.poppins(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  height: 1.2, // Adjusted height for better spacing
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Strengths',
                style: GoogleFonts.poppins(
                  color: Colors.green,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 1.2, // Adjusted height for better spacing
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 3, 15, 3),
                child: Text(
                  strengths!,
                  style: GoogleFonts.poppins(
                    color: Colors.black45, fontWeight: FontWeight.w600,
                    height: 1.2, // Adjusted height for better spacing
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Weaknesses',
                style: GoogleFonts.poppins(
                  color: Colors.redAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 1.2, // Adjusted height for better spacing
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 3, 15, 3),
                child: Text(
                  weaknesses!,
                  style: GoogleFonts.poppins(
                    color: Colors.black45, fontWeight: FontWeight.w600,
                    height: 1.2, // Adjusted height for better spacing
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              CustomTextField(
                controller: nameController,
                hintText: 'Name',
                height: 60,
                borderColor: const Color(0xffffffff),
                prefixIcon: IconButton(
                  onPressed: () {},
                  icon: SvgPicture.asset(
                    'assets/icons/user_solid.svg',
                    colorFilter: const ColorFilter.mode(
                        Color(0xff03A0E3), BlendMode.srcIn),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              /*  CustomTextField(
                controller: dobController,
                height: 60,
                hintText: '01/05/2024',
                borderColor: const Color(0xffffffff),
                prefixIcon: IconButton(
                  onPressed: () {},
                  icon: SvgPicture.asset(
                    'assets/icons/calendar-fill.svg',
                    colorFilter: const ColorFilter.mode(Color(0xff03A0E3), BlendMode.srcIn),
                  ),
                ),
              ),
              const SizedBox(height: 12),*/
              CustomTextField(
                controller: ageController,
                hintText: '',
                height: 60,
                borderColor: const Color(0xffffffff),
                prefixIcon: IconButton(
                  onPressed: () {},
                  icon: SvgPicture.asset(
                    'assets/icons/age.svg',
                    colorFilter: const ColorFilter.mode(
                        Color(0xff03A0E3), BlendMode.srcIn),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: genderController,
                hintText: 'Male',
                borderColor: const Color(0xffffffff),
                prefixIcon: IconButton(
                  onPressed: () {},
                  icon: SvgPicture.asset(
                    'assets/icons/gender.svg',
                    colorFilter: const ColorFilter.mode(
                        Color(0xff03A0E3), BlendMode.srcIn),
                  ),
                ),
                height: 60,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDisconnectedUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            height: 200,
            width: 200,
            padding: const EdgeInsets.fromLTRB(35, 10, 35, 10),
            child: Image.asset("assets/images/nowifi.png", fit: BoxFit.contain),
          ),
          Text(
            "Please #getsocial! You are not connected.",
            style: GoogleFonts.poppins(
                color: Colors.black45,
                fontWeight: FontWeight.w500,
                fontSize: 12),
          ),
          Text(
            "Please check your Wi-Fi connection.",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                color: Colors.redAccent,
                fontWeight: FontWeight.w400,
                fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> retrive() async {
    //await storage.ready;
    String? name = localStorage.getItem('wifiname');
    String? ssid = localStorage.getItem('SSID');
    config_wifi = localStorage.getItem('wifiname') ?? '';

    var headers = {'Content-Type': 'application/json'};
    var request = http.Request('POST',
        Uri.parse('https://admin.connfy.at/api/user_profile'));
    request.body = json.encode({"user_id": user_id});
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      String jsonData = await response.stream.bytesToString();

      Map<String, dynamic> parsedResponse = jsonDecode(jsonData);

      // Extract values
      int status = parsedResponse['status'];
      String message = parsedResponse['message'];
      Map<String, dynamic> data = parsedResponse['data'];

      // Extract values from the 'data' object
      int id = data['id'];
//      String ssid = data['ssid'];
      String nickName = data['nick_name'];
      String dob = data['dob'];
      String gender = data['gender'];
      String email = data['email'];
      String horoscopeName = data['horoscope_name'];

      int verificationStatus = data['verification_status'];
      String mainCharacteristics = data['main_characteristics'];

      String element = data['element'];
      String createdAt = data['created_at'];
      String updatedAt = data['updated_at'];

      setState(() {
        horoscopeImageUrl = data['horoscope_image_url'];
        strengths = data['strengths'];
        weaknesses = data['weaknesses'];
        nameController.text = nickName;
        dobController.text = dob;
        emailController.text = email;
        maincharacter = mainCharacteristics;
        _calculateAge();
        if (gender == '1') {
          genderController.text = 'Male';
        } else if (gender == '2') {
          genderController.text = 'Female';
        } else if (gender == '3') {
          genderController.text = 'Non Binary';
        }
      });
      // Print or use the extracted values
      print("Status: $status");
      print("Message: $message");
      print("ID: $id");
      //  print("SSID: $ssid");
      print("Nick Name: $nickName");
      print("DOB: $dob");
      print("Gender: $gender");
      print("Email: $email");
      print("Horoscope Name: $horoscopeName");
      print("Horoscope Image URL: $horoscopeImageUrl");
      print("Verification Status: $verificationStatus");
      print("Main Characteristics: $mainCharacteristics");
      print("Strengths: $strengths");
      print("Weaknesses: $weaknesses");
      print("Element: $element");
      print("Created At: $createdAt");
      print("Updated At: $updatedAt");
    } else {
      print(response.reasonPhrase);
    }
  }
}
