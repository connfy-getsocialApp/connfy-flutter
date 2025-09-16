import 'dart:async';
import 'dart:convert';

import 'package:chatapp/screens/registration_pagenew.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:connectivity/connectivity.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../controller/loader.dart';
import '../helper/constants.dart';
import '../services/database.dart';
import 'chatlist.dart';
import 'chats.dart';

class ChatListold extends StatefulWidget {
  final authcode;

  ChatListold(this.authcode);

  _MyAppState createState() => _MyAppState(this.authcode);
}

class _MyAppState extends State<ChatListold> {
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
  @override
  void initState() {
    activeUsersList = [];
    super.initState();
    retrive();
  }

  Future retrive() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //Return String
    UserId = prefs.getString('UserId');
    print(UserId);
    _startTimer();

    databaseMethods.searchByName("").then((val) {
      setState(() {
        searchSnapshot = val;
        haveUserSearched = true;
        _isLoading = false;
      });
    });
  }

  void _startTimer() {
    const duration = Duration(seconds: 10);
    _timer = Timer.periodic(duration, (Timer timer) {
      _initConnectivity();

      // Call your method here
    });
  }

  createChatroomAndStartConversation(String uid, String username) {
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
      Navigator.push(context, MaterialPageRoute(builder: (context) => Chat(chatRoomId, uid, username, "1", "", "", Constants.myName, "")));
    } else {
      print("you cannot send message to yourself");
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

    print('User ID: $userId');
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
          Container(
            decoration: const BoxDecoration(color: Colors.transparent),
            // alignment: Alignment.center,
            height: 60,
            child: Container(
              width: 150.0,
              height: 60.0,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/confywhite.png'),
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
          PopupMenuButton(
            color: Colors.white,
            itemBuilder: (context) {
              return [
                const PopupMenuItem(
                  value: 'pro',
                  child: Text('My Profile'),
                ),
              ];
            },
            onSelected: (String value) {
              if (value == 'pro') {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => RegistrationPagenew()));
              }
              print('You Click on po up menu item');
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
            backgroundColor: Colors.blue,
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
                  color: Colors.white,

                  child: Column(
                    children: <Widget>[
                      const SizedBox(
                        height: 20,
                      ),

                      // Here, default theme colors are used for activeBgColor, activeFgColor, inactiveBgColor and inactiveFgColor

                      FutureBuilder(
                          future: _fetchListItems(UserId),
                          builder: (context, AsyncSnapshot snapshot) {
                            if (!snapshot.hasData) {
                              return Center(child: CircularProgressIndicator());
                            } else {
                              return Visibility(
                                visible: true,
                                child: Expanded(
                                  child: searchSnapshot != null && searchSnapshot!.docs.isNotEmpty
                                      ? ListView.builder(
                                          scrollDirection: Axis.vertical,
                                          itemCount: searchSnapshot!.docs.length,
                                          itemBuilder: (ctx, index) {
                                            DateTime dateTime = searchSnapshot!.docs[index]['lastActive'].toDate();
                                            return searchSnapshot!.docs[index]['uid'] == Constants.myName
                                                ? Container()
                                                : GestureDetector(
                                                    child: Container(
                                                      margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                                                      color: Colors.transparent,
                                                      child: Container(
                                                        margin: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
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
                                                                      padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
                                                                      height: 80,
                                                                      width: 80,
                                                                      child: Image.asset("assets/images/pisces.png"),
                                                                    ),
                                                                    Flexible(
                                                                      flex: 2,
                                                                      child: Padding(
                                                                        padding: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 5.0),
                                                                        child: Column(
                                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                                          children: <Widget>[
                                                                            Row(
                                                                              children: <Widget>[
                                                                                Container(
                                                                                    child: Text(
                                                                                  searchSnapshot!.docs[index]['userName'],
                                                                                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black87),
                                                                                )),
                                                                              ],
                                                                            ),
                                                                            Row(
                                                                              children: <Widget>[
                                                                                Container(
                                                                                  padding: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 5.0),
                                                                                  child: Text(
                                                                                    'Hi Dear, How are you?',
                                                                                    style: GoogleFonts.poppins(
                                                                                      fontSize: 14,
                                                                                      color: Colors.black26,
                                                                                      fontWeight: FontWeight.w500,
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                                const SizedBox(
                                                                                  width: 5,
                                                                                ),
                                                                                Container(
                                                                                  height: 5,
                                                                                  width: 5,
                                                                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                            const SizedBox(
                                                                              height: 2,
                                                                            ),
                                                                            Row(
                                                                              mainAxisAlignment: MainAxisAlignment.end,
                                                                              children: <Widget>[
                                                                                Text(
                                                                                  timeago.format(dateTime),
                                                                                  style: GoogleFonts.poppins(color: Colors.black26, fontWeight: FontWeight.w500, fontSize: 14),
                                                                                ),
                                                                                const SizedBox(
                                                                                  width: 5,
                                                                                ),
                                                                              ],
                                                                            ),
                                                                            const SizedBox(
                                                                              height: 2,
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                            Container(
                                                              padding: const EdgeInsets.fromLTRB(5, 2, 5, 2),
                                                              decoration: const BoxDecoration(
                                                                  color: Colors.white,
                                                                  borderRadius: BorderRadius.only(
                                                                      topLeft: Radius.circular(0), bottomRight: Radius.circular(0), bottomLeft: Radius.circular(0), topRight: Radius.circular(0))),
                                                              child: const Divider(
                                                                indent: 10.0,
                                                                endIndent: 10.0,
                                                                color: Color(0xffe5e5e5),
                                                                thickness: 0.8,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    onTap: () {
                                                      createChatroomAndStartConversation(searchSnapshot!.docs[index]['uid'], searchSnapshot!.docs[index]['userName']);
                                                    },
                                                  );
                                          },
                                        )
                                      : const Center(child: CircularProgressIndicator()),
                                ),
                              );
                            }
                          })
                    ],
                  ),
                )
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
                        "connfy WiFi",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.black54,
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
                mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                            const Icon(Icons.message_outlined, color: Colors.blue), // <-- Icon
                            const Text(
                              "Chats",
                              style: TextStyle(color: Colors.blue, fontSize: 12),
                            ), // <-- Text
                          ],
                        ),
                      ),
                    ),
                  ),
                  //  SizedBox(width: 30,),
                  Container(
                    child: Material(
                      color: const Color(0xfff5f5f5),
                      child: InkWell(
                        // splashColor: Colors.green,
                        onTap: () {
                          // Navigator.of(context).push(MaterialPageRoute(builder: (context) => ConfyList("2")));
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const Icon(Icons.chat_bubble_outline, color: Colors.grey), // <-- Icon
                            const Text(
                              "Social Match",
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ), // <-- Text
                          ],
                        ),
                      ),
                    ),
                  ),
                  // SizedBox(width: 30,),
                  Container(
                    child: Material(
                      color: const Color(0xfff5f5f5),
                      child: InkWell(
                        // splashColor: Colors.green,
                        onTap: () {
                          //   Navigator.of(context).push(MaterialPageRoute(builder: (context) => EventsList()));
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const Icon(
                              Icons.add_chart_sharp,
                              color: Colors.grey,
                            ), // <-- Icon
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

  Future<void> wificheck(String ssid) async {
    var headers = {'Content-Type': 'application/json'};
    var request = http.Request('POST', Uri.parse('https://admin.connfy.at/api/wifi_check'));
    request.body = json.encode({"ssid": ssid});
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      String jsonData = await response.stream.bytesToString();
      Map<String, dynamic> responseData = jsonDecode(jsonData);
      print(responseData);
      setState(() {
        wifi_sttus = responseData['status_match'];
      });

      if (wifi_sttus == 0) {
        //Return String

        print(UserId);
        var headers = {'Content-Type': 'application/json'};
        var request = http.Request('POST', Uri.parse('https://admin.connfy.at/api/update_status '));
        request.body = json.encode({"status": 0, "id": UserId});
        request.headers.addAll(headers);

        http.StreamedResponse response = await request.send();

        if (response.statusCode == 200) {
          print(await response.stream.bytesToString());
        } else {
          print(response.reasonPhrase);
        }
      } else {
        var headers = {'Content-Type': 'application/json'};
        var request = http.Request('POST', Uri.parse('https://admin.connfy.at/api/update_status '));
        request.body = json.encode({"status": 1, "id": UserId});
        request.headers.addAll(headers);

        http.StreamedResponse response = await request.send();

        if (response.statusCode == 200) {
          print(await response.stream.bytesToString());
        } else {
          print(response.reasonPhrase);
        }
      }

      String mobileDeviceId = responseData['data'];
      print(mobileDeviceId);
    } else {
      print(response.reasonPhrase);
    }
  }

  Future<void> _initConnectivity() async {
    try {
      // result = await Connectivity().checkConnectivity();
    } catch (e) {
      print(e.toString());
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
      final info = NetworkInfo();

      final wifiName = await info.getWifiName(); // "FooNetwork"
      final wifiBSSID = await info.getWifiBSSID(); //

      print("$wifiName>>>>>$wifiBSSID");
      wificheck(wifiBSSID!);
    }
    wificheck('dtttt'!);
  }

  _fetchListItems(dynamic userid) async {
    var headers = {'Content-Type': 'application/json'};
    var request = http.Request('POST', Uri.parse('https://admin.connfy.at/api/online_users'));
    request.body = json.encode({"user_id": userid});
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      String responseString = await response.stream.bytesToString();

      List<dynamic> jsonDataList = json.decode(responseString);
      // Access the first element in the list
      dynamic jsonData1 = jsonDataList[0];
      dynamic jsonData2 = jsonDataList[0];

      // Access the "Campaigns" key and its value (which is a list)
      activeUsersList = jsonData1['data'];
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
