import 'dart:async';
import 'dart:convert';
// import 'dart:developer' as developer;
import 'dart:io';

import 'package:chatapp/screens/chatlist.dart';
import 'package:chatapp/screens/socailevents.dart';
import 'package:chatapp/screens/socialmatch.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controller/loader.dart';
import '../helper/constants.dart';
import '../services/database.dart';
import 'chats.dart';
import 'myprofile.dart';

class SocilamatchListold extends StatefulWidget {
  final authcode;

  SocilamatchListold(this.authcode);

  _MyAppState createState() => _MyAppState(this.authcode);
}

class _MyAppState extends State<SocilamatchListold> {
  var authcode;
  _MyAppState(this.authcode);
  bool _isLoading = false;
  bool listvisible_flag = true;
  bool listvisible_flag1 = false;
  bool paynow_flag1 = false;
  List<dynamic> responseData = [];
  String username = "";
  String plantid = "";
  String erporderno = "";
  String consumerId = "";
  String outputDate_to1 = "";
  String requesttype = "";
  String? UserId = "";
  bool isLoading = false;
  QuerySnapshot? searchSnapshot;
  List<dynamic> activeUsersList = [];
  DatabaseMethods databaseMethods = DatabaseMethods();
  TextEditingController searchTextEditingController = TextEditingController();
  bool haveUserSearched = false;
  int toggleindex = 0;
  int wifi_sttus = -1;
  String statuslable = "";
  dynamic colorcodelable;
  List<String> supplier_typelist = ["NEW REQUESTS", 'OLD REQUESTS'];
  Timer? _timer;
  String _connectionStatus = 'Unknown';
  late ConnectivityResult result;
  StreamController<bool> _streamController = StreamController<bool>();
  late StreamSubscription<bool> _streamSubscription;
  final NetworkInfo _networkInfo = NetworkInfo();
  @override
  void initState() {
    activeUsersList = [];
    super.initState();
    retrive();
    _initConnectivity();
    startChecking();
  }

  Future retrive() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //Return String
    UserId = prefs.getString('UserId');
    // print(UserId);
    // _startTimer();

    databaseMethods.searchByName("").then((val) {
      setState(() {
        searchSnapshot = val;
        haveUserSearched = true;
        _isLoading = false;
      });
    });
  }

  void startChecking() {
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
    }
    _timer = Timer.periodic(Duration(seconds: 30), (timer) {
      _initConnectivity();
    });
  }

  @override
  void dispose() {
    super.dispose();
    // Cancel the timer when the widget is disposed
    _timer?.cancel();
  }

  createChatroomAndStartConversation(String uid, String username, String userid, dynamic imageurl) {
    print(uid);
    print(Constants.myName);
    if (uid != Constants.myName) {
      String chatRoomId = getChatRoomId(uid, Constants.myName);
      List<String> users = [Constants.myName, uid];
      Map<String, dynamic> chatRoomMap = {
        "chatroomId": chatRoomId,
        "users": users,
      };
      databaseMethods.addChatRoom(chatRoomMap, chatRoomId);
      Navigator.push(context, MaterialPageRoute(builder: (context) => Chat(chatRoomId, uid, username, "2", userid, imageurl, Constants.myName, "")));
    } else {
      // print("you cannot send message to yourself");
    }
  }

  getChatRoomId(String a, String b) {
    if (a.substring(0, 1).codeUnitAt(0) > b.substring(0, 1).codeUnitAt(0)) {
      return "$b\_$a";
    } else {
      return "$a\_$b";
    }
  }

  void parseResponseData(Map<String, dynamic> userData) {
    // Extract data from responseData and handle it as needed
    // For example:
    String userId = userData['Messsage'];

    // Access more fields as needed

    // print('User ID: $userId');
  }

  List<bool> _selections = List.generate(2, (_) => false);
  var appBarHeight = AppBar().preferredSize.height;
  var _popupMenuItemIndex = 0;
  Color _changeColorAccordingToMenuItem = Colors.red;
  String _onDropDownChanged_stype(String val) {
    var prefix;
    if (val.length > 0) {
      prefix = val;
    } else {
      prefix = "Select Requests";
    }

    return prefix;
  }

  Widget getAppBottomView() {
    return Container(
      padding: const EdgeInsets.only(left: 5, bottom: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Image.asset(
            "assets/images/confywhite.png",
            fit: BoxFit.contain,
            height: 58,
          ),
          PopupMenuButton(
            color: Colors.blue,
            itemBuilder: (context) {
              return [
                const PopupMenuItem(
                  value: 'pro',
                  child: Text(
                    'My Profile',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ];
            },
            onSelected: (String value) {
              if (value == 'pro') {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => MyProfilePage("2")));
              }
              // print('You Click on po up menu item');
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[loadUi(), _isLoading ? Loader(loadingTxt: 'Please wait..') : Container()],
    );
  }

  @override
  Widget loadUi() {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Color(0xfff5f5f5),
            leading: Container(),
            bottom: PreferredSize(child: getAppBottomView(), preferredSize: const Size.fromHeight(50.0)),
          ),

          /*AppBar(
            backgroundColor: Color(0xffFA6B0C),
            leading: IconButton(
              tooltip: 'Leading Icon',
              icon: const Icon(Icons.home_filled, color: Colors.white),
              onPressed: () {

              },
            ),
            title: const Text(
              'Contentine',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),*/
          body: wifi_sttus == 1
              ? Container(
                  // padding: const EdgeInsets.all(3.0),
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                  color: Color(0xffe5e5e5),

                  child: Column(
                    children: <Widget>[
                      // Here, default theme colors are used for activeBgColor, activeFgColor, inactiveBgColor and inactiveFgColor

                      Visibility(
                        visible: true,
                        child: Expanded(
                          child: activeUsersList != null && activeUsersList.isNotEmpty
                              ? ListView.builder(
                                  scrollDirection: Axis.vertical,
                                  itemCount: activeUsersList.length,
                                  itemBuilder: (ctx, index) {
                                    // DateTime dateTime = searchSnapshot!.docs[index]['lastActive'].toDate();
                                    return activeUsersList[index]['chat_id'] == Constants.myName
                                        ? Container()
                                        : GestureDetector(
                                            child: Container(
                                                margin: const EdgeInsets.fromLTRB(0, 0, 0, 1),
                                                color: Colors.transparent,
                                                // height: 100,
                                                child: Container(
                                                  margin: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
                                                  //  height: MediaQuery.of(context).size.height / 4.2,
                                                  child: Column(
                                                    children: <Widget>[
                                                      Container(
                                                        margin: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
                                                        child: Container(
                                                          decoration: const BoxDecoration(
                                                              color: Colors.white,
                                                              borderRadius: BorderRadius.only(
                                                                  topLeft: Radius.circular(0), bottomRight: Radius.circular(0), bottomLeft: Radius.circular(0), topRight: Radius.circular(0))),
                                                          child: Row(
                                                            children: <Widget>[
                                                              Container(
                                                                padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
                                                                height: 85,
                                                                width: 85,
                                                                child: Image.network(activeUsersList[index]['horoscope_image_url']),
                                                              ),
                                                              Flexible(
                                                                flex: 2,
                                                                child: Padding(
                                                                  padding: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 0),
                                                                  child: Column(
                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                    // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                                    children: <Widget>[
                                                                      Row(
                                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                        children: <Widget>[
                                                                          Container(
                                                                              width: MediaQuery.of(context).size.width / 2,
                                                                              child: Text(
                                                                                activeUsersList[index]['name'] == null ? "" : activeUsersList[index]['name'],
                                                                                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
                                                                              )),
                                                                          Row(
                                                                            mainAxisAlignment: MainAxisAlignment.end,
                                                                            children: <Widget>[
                                                                              /*   Container(
                                                          height:10,
                                                       width: 10,
                                                       //   margin: EdgeInsets.all(100.0),
                                                          decoration: const BoxDecoration(
                                                              color: Colors.green,
                                                              shape: BoxShape.circle
                                                          ),),*/

                                                                              Text(
                                                                                "06:30 PM",
                                                                                style: GoogleFonts.poppins(color: Colors.black45, fontWeight: FontWeight.w400, fontSize: 14),
                                                                              ),
                                                                              const SizedBox(
                                                                                width: 5,
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ],
                                                                      ),
                                                                      Row(
                                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                        children: <Widget>[
                                                                          Container(
                                                                            padding: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 5.0),
                                                                            child: Text(
                                                                              'online',
                                                                              style: GoogleFonts.poppins(
                                                                                fontSize: 14,
                                                                                color: Colors.green,
                                                                                fontWeight: FontWeight.w300,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          const SizedBox(
                                                                            width: 5,
                                                                          ),
                                                                          /*Container(
                                                                            height: 10,
                                                                            width: 10,
                                                                            //   margin: EdgeInsets.all(100.0),
                                                                            decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                                                                          ),*/
                                                                        ],
                                                                      ),

                                                                      /*  Row(
                                                                        mainAxisAlignment: MainAxisAlignment.end,
                                                                        children: <Widget>[
                                                                          */ /*   Container(
                                                          height:10,
                                                       width: 10,
                                                       //   margin: EdgeInsets.all(100.0),
                                                          decoration: const BoxDecoration(
                                                              color: Colors.green,
                                                              shape: BoxShape.circle
                                                          ),),*/ /*

                                                                          Container(
                                                                            height: 10,
                                                                            width: 10,
                                                                            //   margin: EdgeInsets.all(100.0),
                                                                            decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                                                                          ),
                                                                          const SizedBox(
                                                                            width: 5,
                                                                          ),
                                                                        ],
                                                                      ),*/
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                )),
                                            onTap: () {
                                              createChatroomAndStartConversation(activeUsersList[index]['chat_id'], activeUsersList[index]['name'], activeUsersList[index]['id'].toString(),
                                                  activeUsersList[index]['horoscope_image_url'].toString());
                                            },
                                          );
                                  },
                                )
                              : const Center(child: CircularProgressIndicator()),
                        ),
                      )
                    ],
                  ),
                )
              : wifi_sttus == -1
                  ? Container()
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Container(
                            height: 200,
                            width: 200,
                            padding: const EdgeInsets.fromLTRB(35, 10, 35, 10),
                            /*decoration: BoxDecoration(
                color: themeColor,
                shape: BoxShape.circle,
              ),*/
                            child: Image.asset(
                              "assets/images/nowifi.png",
                              fit: BoxFit.contain,
                            ),
                          ),
                          // SizedBox(height: screenHeight * 0.1),
                          Text(
                            "Youre not connected to ",
                            style: GoogleFonts.poppins(
                              color: Colors.black45,
                              fontWeight: FontWeight.w500,
                              fontSize: 20,
                            ),
                          ),
                          //   SizedBox(height: screenHeight * 0.01),
                          /*  Text(
              "Kindly await approval from the  manager \n before proceeding further.",
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w400,
                fontSize: 17,
              ),
            ),*/

                          Text(
                            "Connfy WiFi",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                              fontSize: 20,
                            ),
                          ),
                          //  SizedBox(height: screenHeight * 0.06),
                          /* Flexible(
              child: HomeButton(
                title: 'Home',
                onTap: () {
                  Navigator.pushReplacement(
                      context, MaterialPageRoute(builder: (context) =>  Dashboard()));
                },
              ),
            ),*/
                        ],
                      ),
                    ),
          bottomNavigationBar: Container(
              color: const Color(0xfff5f5f5),
              height: 80,
              // padding: EdgeInsets.all(5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ignore: deprecated_member_use
                  Container(
                    child: Material(
                      color: const Color(0xfff5f5f5),
                      child: InkWell(
                        //  splashColor: Colors.green,
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (context) => ChatList("1")));
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            IconButton(
                              color: Colors.blue,
                              onPressed: () {
                                Navigator.of(context).push(MaterialPageRoute(builder: (context) => ChatList("1")));
                              },
                              icon: SvgPicture.asset(
                                'assets/icons/chat.svg',
                                colorFilter: ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                              ),
                            ),
                            const Text(
                              "Chats",
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ), // <-- Text
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 30,
                  ),
                  Container(
                    child: Material(
                      color: const Color(0xfff5f5f5),
                      child: InkWell(
                        // splashColor: Colors.green,
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (context) => SocilamatchList("2")));
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            IconButton(
                              color: Colors.blue,
                              onPressed: () {
                                Navigator.of(context).push(MaterialPageRoute(builder: (context) => SocilamatchList("2")));
                              },
                              icon: SvgPicture.asset(
                                'assets/icons/social-match.svg',
                                colorFilter: ColorFilter.mode(Colors.blue, BlendMode.srcIn),
                              ),
                            ),
                            const Text(
                              "Social Match",
                              style: TextStyle(color: Colors.blue, fontSize: 12),
                            ), // <-- Text
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 30,
                  ),
                  Container(
                    child: Material(
                      color: const Color(0xfff5f5f5),
                      child: InkWell(
                        // splashColor: Colors.green,
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (context) => EventsList()));
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            IconButton(
                              onPressed: () {
                                Navigator.of(context).push(MaterialPageRoute(builder: (context) => EventsList()));
                              },
                              icon: SvgPicture.asset(
                                'assets/icons/social-event.svg',
                                colorFilter: ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                              ),
                            ),
                            const Text(
                              "Social Events",
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ), // <-- Text
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ))),
    );
  }

  Future<void> _updateUserStatus(int status) async {
    var headers = {'Content-Type': 'application/json'};
    var request = http.Request('POST', Uri.parse('https://admin.connfy.at/api/update_status'));
    request.body = json.encode({"status": status, "id": UserId});
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      await _fetchListItems(UserId);
      // print(await response.stream.bytesToString());
    } else {
      // print(response.reasonPhrase);
    }
  }

  Future<void> wificheck(String ssid) async {
    if (ssid == null || ssid.isEmpty) {
      // print('SSID is null or empty');
      return;
    }

    var headers = {'Content-Type': 'application/json'};
    var request = http.Request('POST', Uri.parse('https://admin.connfy.at/api/wifi_check'));
    request.body = json.encode({"ssid": ssid});
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      String jsonData = await response.stream.bytesToString();
      Map<String, dynamic> responseData = jsonDecode(jsonData);
      // print(responseData);
      setState(() {
        wifi_sttus = responseData['status_match'];
      });

      // print(wifi_sttus);

      if (wifi_sttus == 0) {
        //   _fetchListItems(UserId);

        await _updateUserStatus(0);
      } else {
        await _updateUserStatus(1);
      }

      String mobileDeviceId = responseData['data'];
      // print(mobileDeviceId);
    } else {
      // print(response.reasonPhrase);
    }
  }

  Future<void> _initConnectivity() async {
    try {
      // result = await Connectivity().checkConnectivity();
    } catch (e) {
      // print(e.toString());
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _updateConnectionStatus(result);
    });

    // Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
    //   setState(() {
    //     _updateConnectionStatus(result);
    //   });
    // });
  }

  // Update connection status
  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    setState(() {
      switch (result) {
        case ConnectivityResult.wifi:
          _connectionStatus = 'WiFi';
          break;
        case ConnectivityResult.mobile:
          _connectionStatus = 'Mobile';
          break;
        case ConnectivityResult.none:
          _connectionStatus = 'None';
          break;
        default:
          _connectionStatus = 'Unknown';
          break;
      }
    });

    if (_connectionStatus == 'WiFi') {
      _initNetworkInfo();
    }
    if (_connectionStatus == 'Mobile') {
      _updateUserStatus(0);
    } else {
      setState(() {
        wifi_sttus = 0;
      });
    }
    //  wificheck('FTTH-5G'!);
  }

  Future<void> _initNetworkInfo() async {
    String? wifiName = "";
    String? wifiBSSID = "";
    String? wifiIPv4 = "";
    String? wifiIPv6 = "";
    String? wifiGatewayIP = "";
    String? wifiBroadcast = "";
    String? wifiSubmask = "";
    print("afkadj");
    //   Fluttertoast.showToast(msg: 'Wifi Name: $wifiName\n', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.CENTER, timeInSecForIosWeb: 1, textColor: Colors.white, fontSize: 16.0);
    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        // Request permissions as recommended by the plugin documentation:
        // https://github.com/fluttercommunity/plus_plugins/tree/main/packages/network_info_plus/network_info_plus
        if (await Permission.locationWhenInUse.request().isGranted) {
          wifiName = await _networkInfo.getWifiName();
        } else {
          wifiName = 'Unauthorized to get Wifi Name';
        }
      } else {
        wifiName = await _networkInfo.getWifiName();
      }
    } on PlatformException catch (e) {
      // developer.log('Failed to get Wifi Name', error: e);
      wifiName = 'Failed to get Wifi Name';
    }

    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        // Request permissions as recommended by the plugin documentation:
        // https://github.com/fluttercommunity/plus_plugins/tree/main/packages/network_info_plus/network_info_plus
        if (await Permission.locationWhenInUse.request().isGranted) {
          wifiBSSID = await _networkInfo.getWifiBSSID();
        } else {
          wifiBSSID = 'Unauthorized to get Wifi BSSID';
        }
      } else {
        wifiName = await _networkInfo.getWifiName();
      }
    } on PlatformException catch (e) {
      // developer.log('Failed to get Wifi BSSID', error: e);
      wifiBSSID = 'Failed to get Wifi BSSID';
    }

    try {
      wifiIPv4 = await _networkInfo.getWifiIP();
    } on PlatformException catch (e) {
      // developer.log('Failed to get Wifi IPv4', error: e);
      wifiIPv4 = 'Failed to get Wifi IPv4';
    }

    try {
      wifiIPv6 = await _networkInfo.getWifiIPv6();
    } on PlatformException catch (e) {
      // developer.log('Failed to get Wifi IPv6', error: e);
      wifiIPv6 = 'Failed to get Wifi IPv6';
    }

    try {
      wifiSubmask = await _networkInfo.getWifiSubmask();
    } on PlatformException catch (e) {
      // developer.log('Failed to get Wifi submask address', error: e);
      wifiSubmask = 'Failed to get Wifi submask address';
    }

    try {
      wifiBroadcast = await _networkInfo.getWifiBroadcast();
    } on PlatformException catch (e) {
      // developer.log('Failed to get Wifi broadcast', error: e);
      wifiBroadcast = 'Failed to get Wifi broadcast';
    }

    try {
      wifiGatewayIP = await _networkInfo.getWifiGatewayIP();
    } on PlatformException catch (e) {
      // developer.log('Failed to get Wifi gateway address', error: e);
      wifiGatewayIP = 'Failed to get Wifi gateway address';
    }
    String cleanedSsid = "";
    if (wifiName != null && wifiName.isNotEmpty) {
      cleanedSsid = wifiName!.replaceAll('"', '');
      await wificheck(cleanedSsid);
    } else {
      cleanedSsid = "";
      print('wifiName is null or empty');
    }
    //  await wificheck(wifiName!);

    //Fluttertoast.showToast(msg: 'Wifi Name: $cleanedSsid\n', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.CENTER, timeInSecForIosWeb: 1, textColor: Colors.white, fontSize: 16.0);
    setState(() {
      _connectionStatus = 'Wifi Name: $wifiName\n'
          'Wifi BSSID: $wifiBSSID\n'
          'Wifi IPv4: $wifiIPv4\n'
          'Wifi IPv6: $wifiIPv6\n'
          'Wifi Broadcast: $wifiBroadcast\n'
          'Wifi Gateway: $wifiGatewayIP\n'
          'Wifi Submask: $wifiSubmask\n';
    });
  }

  _fetchListItems(dynamic userid) async {
    var headers = {'Content-Type': 'application/json'};
    var request = http.Request('POST', Uri.parse('https://admin.connfy.at/api/social_match_users'));
    request.body = json.encode({"user_id": userid});
    request.headers.addAll(headers);
    print(json.encode({"user_id": userid}));

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      String responseString = await response.stream.bytesToString();
      Map<String, dynamic> responseData = json.decode(responseString);

      if (responseData.containsKey('data')) {
        setState(() {
          activeUsersList = responseData['data'];
        });
      } else {
        // Handle error if 'data' key is not found
        print("Error: 'data' key not found in the response");
      }
    } else {
      print(response.reasonPhrase);
    }
  }
}

class CustomShape extends CustomClipper<Path> {
  @override
  getClip(Size size) {
    double height = size.height;
    double width = size.width;
    var path = Path();
    path.lineTo(0, height - 60);
    path.quadraticBezierTo(width / 2, height, width, height - 60);
    path.lineTo(width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper oldClipper) {
    return true;
  }
}

class ExpandableText extends StatefulWidget {
  const ExpandableText(
    this.text, {
    this.trimLines = 2,
  });

  final String text;
  final int trimLines;

  @override
  ExpandableTextState createState() => ExpandableTextState();
}

class ExpandableTextState extends State<ExpandableText> {
  bool _readMore = true;
  void _onTapLink() {
    setState(() => _readMore = !_readMore);
  }

  @override
  Widget build(BuildContext context) {
    final DefaultTextStyle defaultTextStyle = DefaultTextStyle.of(context);
    final colorClickableText = Colors.blue;
    final widgetColor = Colors.black;
    TextSpan link = TextSpan(
        text: _readMore ? "... read more" : " read less",
        style: TextStyle(
          color: colorClickableText,
        ),
        recognizer: TapGestureRecognizer()..onTap = _onTapLink);
    Widget result = LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        assert(constraints.hasBoundedWidth);
        final double maxWidth = constraints.maxWidth;
        // Create a TextSpan with data
        final text = TextSpan(
          text: widget.text,
        );
        // Layout and measure link
        TextPainter textPainter = TextPainter(
          text: link,
          textDirection: TextDirection.rtl, //better to pass this from master widget if ltr and rtl both supported
          maxLines: widget.trimLines,
          ellipsis: '...',
        );
        textPainter.layout(minWidth: constraints.minWidth, maxWidth: maxWidth);
        final linkSize = textPainter.size;
        // Layout and measure text
        textPainter.text = text;
        textPainter.layout(minWidth: constraints.minWidth, maxWidth: maxWidth);
        final textSize = textPainter.size;
        // Get the endIndex of data
        int? endIndex;
        final pos = textPainter.getPositionForOffset(Offset(
          textSize.width - linkSize.width,
          textSize.height,
        ));
        endIndex = textPainter.getOffsetBefore(pos.offset);
        var textSpan;
        if (textPainter.didExceedMaxLines) {
          textSpan = TextSpan(
            text: _readMore ? widget.text.substring(0, endIndex) : widget.text,
            style: TextStyle(
              color: widgetColor,
            ),
            children: <TextSpan>[link],
          );
        } else {
          textSpan = TextSpan(
            text: widget.text,
          );
        }
        return RichText(
          softWrap: true,
          overflow: TextOverflow.clip,
          text: textSpan,
        );
      },
    );
    return result;
  }
}
