import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chatapp/screens/registration_pagenew.dart';
import 'package:chatapp/screens/socailevents.dart';
import 'package:chatapp/screens/socialmatch.dart';
import 'package:chatapp/screens/splash_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:localstorage/localstorage.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controller/loader.dart';
import '../helper/shared_preference.dart';
import '../main.dart';
import '../widgets/textfield.dart';
import 'NetworkService.dart';
import 'chatlistnew.dart';
import 'dummy_login.dart';

class MyProfilePage extends StatefulWidget {
  final routeid;
  final bool isReviewMode; // Add this line

  const MyProfilePage(this.routeid, {super.key,this.isReviewMode = false});

  @override
  State<MyProfilePage> createState() => _ProfilePageState(routeid);
}

class _ProfilePageState extends State<MyProfilePage> {
  var routeid;
  //final LocalStorage storage = new LocalStorage('wifi');
  _ProfilePageState(this.routeid);

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final dobController = TextEditingController();
  final genderController = TextEditingController();
  final blockController = TextEditingController();
  final flatController = TextEditingController();
  final gstController = TextEditingController();
  final ageController = TextEditingController();
  bool _refreshListCalled = false;
  String name = "";
  String mobileno = "";
  String? UserId = "";
  String? shop_id = "";

  String? horoscopeImageUrl = "";
  String? strengths = "";
  String? weaknesses = "";
  String? maincharacter = "";
  bool isInitializing = true;

  String config_wifi = "emty";
  dynamic shopidn = "";
  dynamic history_id = "";

  bool isLoading = false;
  void showSnakBar(String message) {
    final snakbar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 4),
    );
    SnakBarKey.currentState?.showSnackBar(snakbar);
  }

  final SnakBarKey = GlobalKey<ScaffoldMessengerState>();

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

    if (widget.isReviewMode) {
      _initializeMockData();
    }else {
      _initializeNetworkStatus();
      registerForNotifications();
      retrive();
    }
  }

  Future<void> _initializeNetworkStatus() async {
    // Simulate a delay to fetch network status (if needed)
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      isInitializing = false;
    });
  }
  void _initializeMockData() {
    // debugPrint('MOCK :::');
    setState(() {
      horoscopeImageUrl = "https://cdn-icons-png.flaticon.com/512/3135/3135715.png";
      strengths = "Creative, Adaptable, Friendly";
      weaknesses = "Indecisive, Impulsive, Inconsistent";
      maincharacter = "The Social Butterfly";
      nameController.text = "Review User";
      dobController.text = "01/01/1990";
      emailController.text = "test@gmail.com";
      ageController.text = "33";
      genderController.text = "Male";
    });
  }

  savePost1(String name, String ssid) async {
    //  await storage.ready;
    localStorage.setItem("wifiname", "name");
    localStorage.setItem("SSID", "ggggg54");
  }

  Future<void> _updateUserStatus(int status) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    preferences.clear();
    //final LocalStorage storage = LocalStorage('wifi');
    localStorage.clear();
    var headers = {'Content-Type': 'application/json'};
    var request1 = http.Request(
        'POST',
        Uri.parse(
            'https://admin.connfy.at/api/update_status '));
    request1.body = json.encode({
      "status": 0,
      "id": UserId,
      "shop_id": shopidn,
      "history_id": history_id
    });
    request1.headers.addAll(headers);
    print(request1.body);

    http.StreamedResponse response1 = await request1.send();

    if (response1.statusCode == 200) {
      print('RESPONSE');
      print(await response1.stream.bytesToString());
      Provider.of<NetworkService>(context, listen: false).clearData();
      setState(() {
        isLoading = false;
      });
      HelperFunctions.saveUserLoggedInSharedPreference(false);
      HelperFunctions.clearSharedPreferences();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SplashScreen()),
      );
    } else {
      // print('RESPONSE2222');
      //          print(response1.reasonPhrase);
    }

    //await _fetchListItems(UserId);
    //  print(await response.stream.bytesToString());
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
          if (routeid == '1') {
            Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => ChatListnew("1")));
          } else {
            Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => SocilamatchList("2")));
          }
          // Navigator.of(context).push(MaterialPageRoute(builder: (context) => ChatList("")));
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
    return Scaffold(
      backgroundColor: const Color(0xFFe5e5e5),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.lightBlue,
          ),
          onPressed: () {
            if (routeid == '1') {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => ChatListnew("1",isReviewMode: widget.isReviewMode,)));
            } else if(routeid=='3'){
            Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => EventsList(isReviewMode: widget.isReviewMode,)));

            }else {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => SocilamatchList("2",reviewMode: widget.isReviewMode)));
            }
            // Navigator.of(context).push(MaterialPageRoute(builder: (context) => ChatList("")));
          },
        ),
        title:  Text(
          'My Profile${widget.isReviewMode ? " (Review Mode)" : ""}',
          style: const TextStyle(color: Color(0xff03A0E3)),
        ),
        backgroundColor: Colors.white,
      ), // Placeholder for buildAppBar()
      body:widget.isReviewMode
          ? _buildMockUI(): isInitializing
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
                print(isConnectedToConfiguredWifi);

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
                    // retrive();
                  });
                  //  return _buildConnectedUI(context);
                  return _buildDisconnectedUI();
                }
              },
            ),
    );
  }
  Widget _buildMockUI() {
    return ListView(
      children: [
        if (widget.isReviewMode)
          Container(
            padding: EdgeInsets.all(8),
            color: Colors.orange,
            child: Text(
              "REVIEW MODE - Showing mock profile data",
              style: TextStyle(color: Colors.white),
            ),
          ),
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
                child: SvgPicture.asset(
                  'assets/icons/user_solid.svg',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                maincharacter!,
                style: GoogleFonts.poppins(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
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
                  height: 1.2,
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
                  height: 1.2,
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
                    height: 1.2,
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
              AbsorbPointer(
                child: CustomTextField(
                  controller: nameController,
                  hintText: 'Name',
                  height: 60,
                  borderColor: const Color(0xffffffff),
                  prefixIcon: IconButton(
                    onPressed: null,
                    icon: SvgPicture.asset(
                      'assets/icons/user_solid.svg',
                      colorFilter: const ColorFilter.mode(
                          Color(0xff03A0E3), BlendMode.srcIn),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AbsorbPointer(
                child: CustomTextField(
                  controller: dobController,
                  height: 60,
                  hintText: '01/05/2024',
                  borderColor: const Color(0xffffffff),
                  prefixIcon: IconButton(
                    onPressed: null,
                    icon: SvgPicture.asset(
                      'assets/icons/calendar-fill.svg',
                      colorFilter: const ColorFilter.mode(
                          Color(0xff03A0E3), BlendMode.srcIn),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AbsorbPointer(
                child: CustomTextField(
                  controller: ageController,
                  hintText: '',
                  height: 60,
                  borderColor: const Color(0xffffffff),
                  prefixIcon: IconButton(
                    onPressed: null,
                    icon: SvgPicture.asset(
                      'assets/icons/age.svg',
                      colorFilter: const ColorFilter.mode(
                          Color(0xff03A0E3), BlendMode.srcIn),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AbsorbPointer(
                child: CustomTextField(
                  controller: genderController,
                  hintText: 'Male',
                  borderColor: const Color(0xffffffff),
                  prefixIcon: IconButton(
                    onPressed: null,
                    icon: SvgPicture.asset(
                      'assets/icons/gender.svg',
                      colorFilter: const ColorFilter.mode(
                          Color(0xff03A0E3), BlendMode.srcIn),
                    ),
                  ),
                  height: 60,
                ),
              ),
              const SizedBox(height: 12),
              AbsorbPointer(
                child: CustomTextField(
                  controller: emailController,
                  hintText: emailController.text,
                  borderColor: const Color(0xffffffff),
                  prefixIcon: IconButton(
                    onPressed: null,
                    icon: SvgPicture.asset(
                      'assets/icons/email.svg',
                      colorFilter: const ColorFilter.mode(
                          Color(0xff03A0E3), BlendMode.srcIn),
                    ),
                  ),
                  height: 60,
                ),
              ),
              const SizedBox(height: 12),
              AbsorbPointer(
                absorbing: widget.isReviewMode, // Ensure no clicks in Review Mode

                child: CustomTextField(
                  controller: gstController,
                  hintText: 'Delete(Disabled in Review Mode)',
                  borderColor: const Color(0xffffffff),
                  prefixIcon: IconButton(
                    onPressed: null,
                    icon: const Icon(
                      Icons.delete_forever,
                      color: Colors.grey, // use grey instead of red to indicate it's inactive
                    ),
                  ),
                  height: 60,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: (){
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => RegistrationPagenew()));

                },
                child: AbsorbPointer(
                  child: CustomTextField(
                    controller: gstController,
                    hintText: 'Logout',
                    borderColor: const Color(0xffffffff),
                    prefixIcon: IconButton(
                      onPressed: null,
                      icon: const Icon(
                        Icons.logout,
                        color: Color(0xff03A0E3),
                      ),
                    ),
                    height: 60,
                  ),
                ),
              ),

            ],
          ),
        ),
      ],
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
                    //height: 1.2, // Adjusted height for better spacing
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
              CustomTextField(
                controller: dobController,
                height: 60,
                hintText: '01/05/2024',
                borderColor: const Color(0xffffffff),
                prefixIcon: IconButton(
                  onPressed: () {},
                  icon: SvgPicture.asset(
                    'assets/icons/calendar-fill.svg',
                    colorFilter: const ColorFilter.mode(
                        Color(0xff03A0E3), BlendMode.srcIn),
                  ),
                ),
              ),
              const SizedBox(height: 12),
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
              CustomTextField(
                controller: emailController,
                hintText: emailController.text,
                borderColor: const Color(0xffffffff),
                prefixIcon: IconButton(
                  onPressed: () {},
                  icon: SvgPicture.asset(
                    'assets/icons/email.svg',
                    colorFilter: const ColorFilter.mode(
                        Color(0xff03A0E3), BlendMode.srcIn),
                  ),
                ),
                height: 60,
              ),

              const SizedBox(height: 12),
              GestureDetector(
                child: CustomTextField(
                  controller: gstController,
                  hintText: 'Delete',
                  borderColor: const Color(0xffffffff),
                  prefixIcon: IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.delete_forever,
                      color: Colors.redAccent,
                    ),
                  ),
                  height: 60,
                ),
                onTap: () {
                  HelperFunctions.saveUserLoggedInSharedPreference(false);
                  _onWillPop();
                },
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

  Future<bool> _onWillPop() async {
    return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Are you sure?'),
            content: const Text('Do you want to delete your data'),
            actions: <Widget>[
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(false), //<-- SEE HERE
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop(false);
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  //Return String
                  UserId = prefs.getString('UserId');
                  delete_user(UserId!);
                }, // <-- SEE HERE
                child: const Text('Yes'),
              )
            ],
          ),
        )) ??
        false;
  }

  @override
  void dispose() {

    super.dispose();
  }

  Future<void> retrive() async {
    // await storage.ready;
    String? name = localStorage.getItem('wifiname');
    String? ssid = localStorage.getItem('SSID');
    config_wifi = localStorage.getItem('wifiname') ?? '';
    shopidn = localStorage.getItem('shopid') ?? '';
    history_id = localStorage.getItem('history_id') ?? '';
    print("fsdfsf $history_id");
    print("shopidn $shopidn");

    SharedPreferences prefs = await SharedPreferences.getInstance();
    //Return String
    UserId = prefs.getString('UserId');

    var headers = {'Content-Type': 'application/json'};
    var request = http.Request('POST',
        Uri.parse('https://admin.connfy.at/api/my_profile'));
    request.body = json.encode({"user_id": UserId});
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      String jsonData = await response.stream.bytesToString();
      print(jsonData);

      Map<String, dynamic> parsedResponse = jsonDecode(jsonData);

      // Extract values
      int status = parsedResponse['status'];
      String message = parsedResponse['message'];
      Map<String, dynamic> data = parsedResponse['data'];

      // Extract values from the 'data' object
      int id = data['id'];
      //  String ssid = data['ssid'];
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
      if (mounted) {
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
      }
    } else {
      print(response.reasonPhrase);
    }
  }

  Future<void> delete_user(String? userid) async {
    var headers = {'Content-Type': 'application/json'};
    var request = http.Request('POST',
        Uri.parse('https://admin.connfy.at/api/delete_user'));
    request.body = json.encode({"user_id": userid});
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();
    var message;
    if (response.statusCode == 200) {
      //  print(await response.stream.bytesToString());
      var responseBody = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseBody);
      message = jsonResponse['message'];
      print('Deleted user ID: $message');

      if (message == 'User Deleted') {
        SharedPreferences preferences = await SharedPreferences.getInstance();
        preferences.clear();
        // final LocalStorage storage = LocalStorage('wifi');
        localStorage.clear();
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const RegistrationPagenew()));
      }
    } else {
      SharedPreferences preferences = await SharedPreferences.getInstance();
      preferences.clear();
      // final LocalStorage storage = LocalStorage('wifi');
      localStorage.clear();
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => const RegistrationPagenew()));
      print(response.reasonPhrase);
      showSnakBar(message);
    }
  }
}
