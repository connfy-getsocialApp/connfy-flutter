import 'dart:async';
import 'dart:convert';

import 'package:async/async.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chatapp/screens/showreview.dart';
import 'package:chatapp/screens/socailevents.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:localstorage/localstorage.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/NotificationService.dart';
import '../controller/loader.dart';
import '../helper/constants.dart';
import '../location/location_service.dart';
import '../main.dart';
import '../services/database.dart';
import 'NetworkService.dart';
import 'chatlistnew.dart';
import 'chats.dart';
import 'myprofile.dart';

class SocilamatchList extends StatefulWidget {
  final authcode;
  final bool reviewMode;  // Pass true for review/mock mode

  SocilamatchList(this.authcode, {this.reviewMode = false});

  _MyAppState createState() => _MyAppState(this.authcode);
}

class _MyAppState extends State<SocilamatchList> {
  var authcode;
  _MyAppState(this.authcode);
  bool _isLoading = false;
  bool listvisible_flag = true;
  bool listvisible_flag1 = false;
  bool isInitializing = true;
  String? previousWifiName;
  bool hasCalledUpdateHistory = false;
  bool _hasRefreshedList = false;
  bool _refreshListCalled = false;
  bool paynow_flag1 = false;
  bool _isStoredWifiNameMatched = false;
  List<dynamic> responseData = [];
  bool hasRefreshedList = false;
  bool isDisconnectedLoading = false;
  String username = "";
  String plantid = "";
  String erporderno = "";
  String consumerId = "";
  String outputDate_to1 = "";
  String requesttype = "";
  String? UserId = "";
  String? newhistoryid = "";
  String shopidn = "";
  String? wifiNamenew;
  bool isLoading = true;
  QuerySnapshot? searchSnapshot;
  List<dynamic> activeUsersList = [];
  bool hasCheckedNetwork = false;
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
  final AsyncMemoizer _memoizer = AsyncMemoizer();
  final NetworkInfo _networkInfo = NetworkInfo();
  Future<List>? _futureActiveUsersList;
  // final LocalStorage storage = LocalStorage('wifi');
  String config_wifi = "";
  dynamic shop_id;
  String googlerul = "";
  String connected_wifi = "";
  List<dynamic> _cachedList = [];
  StreamController<List<dynamic>> _dataController =
      StreamController<List<dynamic>>();

  Stream<List<dynamic>> get dataStream => _dataController.stream;
  Future<void>? _initLocalStorageFuture;
  List<Map<String, dynamic>> _mockSocialMatches = [];

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  String formatChatTime(String chatTime) {
    if (chatTime == null || chatTime == 'null') {
      return "";
    }

    DateTime messageDate = DateTime.parse(chatTime);
    DateTime now = DateTime.now();

    // Check if the message was sent today
    if (messageDate.year == now.year &&
        messageDate.month == now.month &&
        messageDate.day == now.day) {
      return DateFormat.jm().format(messageDate); // Show time (e.g., 2:30 PM)
    }

    // Check if the message was sent yesterday
    DateTime yesterday = now.subtract(const Duration(days: 1));
    if (messageDate.year == yesterday.year &&
        messageDate.month == yesterday.month &&
        messageDate.day == yesterday.day) {
      return 'Yesterday';
    }

    // Otherwise, show the date (e.g., Jan 1, 2023)
    return DateFormat.yMMMd().format(messageDate);
  }

  Future<void> _updateUserStatus(int status) async {
    var headers = {'Content-Type': 'application/json'};

    dynamic shopidn = localStorage.getItem('shopid') ?? '';
    dynamic history_id = localStorage.getItem('history_id') ?? '';
    String? chatRoomIdsJson = localStorage.getItem('chatroomids');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    UserId = prefs.getString('UserId');

    // Decode the JSON string to remove backslashes
    List<dynamic> channelIdsList = jsonDecode(chatRoomIdsJson ?? '[]');

    // Re-encode the list as a JSON array
    String channelIdsJson = jsonEncode(channelIdsList);

    var request1 = http.Request(
        'POST',
        Uri.parse(
            'https://admin.connfy.at/api/update_status_now'));
    request1.body = json.encode({
      "status": 0,
      "id": UserId,
      "shop_id": shopidn,
      "history_id": history_id,
      "channel_ids": channelIdsJson,
    });
    request1.headers.addAll(headers);

    http.StreamedResponse response1 = await request1.send();

    if (response1.statusCode == 200) {
      List<String> chatRoomIds = List<String>.from(channelIdsList);
      await Future.delayed(Duration(minutes: 10), () async {
        localStorage.removeItem('chatroomids');
        List<String> chatRoomIds = List<String>.from(channelIdsList);
        await dbMethods.deleteAllMessagesFromMultipleChatRooms(chatRoomIds);
      });

      // dbMethods.deleteAllMessagesFromMultipleChatRooms(chatRoomIds);

      // Pass the List<String> to the deleteAllMessagesFromMultipleChatRooms method
      // dbMethods.deleteAllMessagesFromMultipleChatRooms(chatRoomIds);
    } else {
      // print('RESPONSE2222');
      print(response1.reasonPhrase);
    }
  }

  FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;
  late FirebaseMessaging messaging;
  Future<void> registerForNotifications() async {
    messaging = FirebaseMessaging.instance;


    await messaging.subscribeToTopic('flutter_notification');


    if (!kIsWeb) {
      // Define the notification channel
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'flutter_notification', // channel ID
        'Flutter Notification', // channel name
        importance: Importance.high,
        enableLights: true,
        enableVibration: true,
        showBadge: true,
        playSound: true,
      );

      // Initialize flutter_local_notifications plugin
      flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

      // Configure initialization settings
      const AndroidInitializationSettings android =
          AndroidInitializationSettings('@drawable/favicon_2');
      const DarwinInitializationSettings iOSInitSettings =
          DarwinInitializationSettings();
      const InitializationSettings initSettings = InitializationSettings(
        android: android,
        iOS: iOSInitSettings,
      );

      // Initialize flutter_local_notifications plugin with the settings
      final bool? initialized =
          await flutterLocalNotificationsPlugin?.initialize(
        initSettings,
        onDidReceiveNotificationResponse: notificationTapBackground,
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );

      if (initialized == null || !initialized) {
        // Handle initialization error
        print("Error: flutterLocalNotificationsPlugin failed to initialize");
        return;
      }

      // Set foreground notification presentation options
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

        if (data == null || data.isEmpty) {
          print('Received message data is null or empty');
          return; // Exit if data is null or empty
        } else {
          if (imageUrl.isNotEmpty) {
            navigatorKey.currentState?.popUntil((route) => route.isFirst);

            if (_isDialogOpen) {
              Navigator.of(navigatorKey.currentState!.context,
                      rootNavigator: true)
                  .pop();
              _isDialogOpen = false;
            }
            showNotificationDialog(title, body, imageUrl);
            await NotificationService()
                .showNotificationWithImage(title, body, imageUrl);
          } else if (title.isNotEmpty) {
            if (title.toString().contains('Message from:')) {
            } else {
              NotificationService().showNotification(title: title, body: body);
            }
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

        if (data == null || data.isEmpty) {
          print('Received message data is null or empty');
          return; // Exit if data is null or empty
        } else {
          if (imageUrl.isNotEmpty) {
            // Show notification dialog if image URL is provided
            //  showNotificationDialog(title, body, imageUrl);
            await NotificationService()
                .showNotificationWithImage(title, body, imageUrl);
          } else if (title.isNotEmpty) {
            NotificationService().showNotification(title: title, body: body);
          }
        }

        // Show notification
      });
    }
  }

  Future<void> _launchUrl() async {
    if (!await launchUrl(Uri.parse(googlerul))) {
      throw Exception('Could not launch $googlerul');
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
      barrierDismissible: false,
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

  Future<void> _initializeNetworkStatus() async {
    // Simulate a delay to fetch network status (if needed)
    await Future.delayed(const Duration(milliseconds: 1000));
    setState(() {
      isInitializing = false;
    });
  }

  // Other varia
  @override
  void initState() {
    if (widget.reviewMode) {
      // debugPrint('DEBUG MODE:');
      _initializeMockData();
    }else {
      activeUsersList = [];
      _initLocalStorageFuture = initLocalStorage();
      super.initState();

      registerForNotifications();
      _initializeNetworkStatus();
      retrive();
    }
  }
  void _initializeMockData() {
    setState(() {
      _mockSocialMatches = [
        {
          'name': 'Social Match 1',
          'chat_id': 'mock_social_1',
          'id': '201',
          'horoscope_image_url': 'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
          'mobile_device_id': 'mock_device_social_1',
          'chat_message': 'Hi!',
          'chat_time': DateTime.now().toIso8601String(),
        },
        {
          'name': 'Social Match 2',
          'chat_id': 'mock_social_2',
          'id': '202',
          'horoscope_image_url': 'assets/images/default_avatar.png',
          'mobile_device_id': 'mock_device_social_2',
          'chat_message': 'How are you today?',
          'chat_time': DateTime.now().subtract(Duration(hours: 2)).toIso8601String(),
        },
      ];
      _cachedList = _mockSocialMatches;
      isLoading = false;
      // debugPrint('DEBUG MODE DATA:${_cachedList}');

    });
  }

  @override
  void dispose() {
    _dataController.close();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> retrieveWifiName() async {
    var headers = {'Content-Type': 'application/json'};
    var request = http.Request('POST',
        Uri.parse('https://admin.connfy.at/api/wifi_details'));
    request.body = json.encode({"wifi_name": connected_wifi});
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
            //    dynamic history_id = responseData['history_id'].toString();
            // print('history_id: $history_id');
            print('WiFi Name: $wifiName');

            setState(() {
              config_wifi = wifiName;
              shop_id = shopid;
              googlerul = url_;
            });

            /*  config_wifi = wifiName;
            shop_id = shopid;
            googlerul = url_;*/
            savePost1(wifiName, wifiName, shopid, url_);
            // Now you can use the WiFi name as needed
          } else {
            print('WiFi name not found or is null in the data');
          }
        } else {
          print('Data not found or is null in the response');
        }
      } else {
        print('Failed to retrieve WiFi name: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error occurred: $e');
    }
  }

  savePost1(String name, String ssid, dynamic shopid, String url) async {
    localStorage.setItem("wifiname", name);
    localStorage.setItem("SSID", ssid);
    localStorage.setItem("shopid", shopid.toString());
    localStorage.setItem("url", url);
  }

  Future<void> retrivewww() async {
    String? name = localStorage.getItem('wifiname');
    dynamic? shopid = localStorage.getItem('shopid');

    config_wifi = localStorage.getItem('wifiname') ?? 'errrr';
    googlerul = localStorage.getItem('url') ?? "";
  }


  Future<void> _refreshList() async {
    try {
      List<dynamic> newActiveUsersList =
          await _fetchListItemsnew(UserId, connected_wifi, shop_id);
      if (newActiveUsersList.isNotEmpty) {
        setState(() {
          activeUsersList = newActiveUsersList;
          activeUsersList.sort((a, b) {
            DateTime timeA = a['chat_time'] == null || a['chat_time'] == 'null'
                ? DateTime.fromMillisecondsSinceEpoch(0)
                : DateFormat("yyyy-MM-dd HH:mm:ss").parse(a['chat_time']);
            DateTime timeB = b['chat_time'] == null || b['chat_time'] == 'null'
                ? DateTime.fromMillisecondsSinceEpoch(0)
                : DateFormat("yyyy-MM-dd HH:mm:ss").parse(b['chat_time']);
            return timeB
                .compareTo(timeA); // Descending order, latest chats first
          });
          _dataController.add(newActiveUsersList);
        });
      }
    } catch (e) {
      print("Error in refreshing list: $e");
    }
  }

  Future<List<dynamic>> _fetchListItemsnew(
      dynamic userid, String config_wifi, dynamic shopid) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    UserId = prefs.getString('UserId');

    var headers = {'Content-Type': 'application/json'};
    var url =
        Uri.parse('https://admin.connfy.at/api/social_api');
    var body = json.encode({
      "status": 1,
      "user_id": UserId,
      "ssid": config_wifi,
    });

    const int maxRetries = 3;
    const Duration timeoutDuration = Duration(seconds: 3);
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        var request = http.Request('POST', url)
          ..body = body
          ..headers.addAll(headers);
        http.StreamedResponse response =
            await request.send().timeout(timeoutDuration);

        if (response.statusCode == 200) {
          String responseString = await response.stream.bytesToString();
          Map<String, dynamic> responseData = json.decode(responseString);

          if (responseData.containsKey('data')) {
            _cachedList = responseData['data'];

            var wifiDetails = responseData['wifi_details'];
            savePost1(wifiDetails['wifi_name'], wifiDetails['wifi_name'],
                wifiDetails['shop_id'], wifiDetails['google_url']);
            retrivewww();

            setState(() {
              config_wifi = wifiDetails['wifi_name'];
              isLoading = false;
            });

            return _cachedList;
          }
        }
      } catch (e) {
        print("Error: $e");
      }

      retryCount++;
      await Future.delayed(const Duration(seconds: 2));
    }

    setState(() {
      isLoading = false;
    });

    return Future.value([]);
  }

  // Update connection status

  Future retrive() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //Return String
    UserId = prefs.getString('UserId');
    print(UserId);
    print(_cachedList.length);
    var networkService = Provider.of<NetworkService>(context, listen: false);

    await networkService.initNetworkInfoOld();

    dynamic historyId = localStorage.getItem('history_id') ?? '';
    dynamic shopidn = localStorage.getItem('shopidn') ?? '';

  }

  showLoader(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  void hideLoader(BuildContext context) {
    Navigator.of(context).pop();
  }

  Future<void> callUpdate(String shopid) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? UserId = prefs.getString('UserId');
    dynamic historyId = localStorage.getItem('history_id') ?? '';

    // Check if historyId is already stored
    if (historyId == null || historyId.toString().isEmpty) {
      var headers = {'Content-Type': 'application/json'};
      var request = http.Request(
          'POST',
          Uri.parse(
              'https://admin.connfy.at/api/update_history'));
      request.body = json.encode({"user_id": UserId, "shop_id": shopid});
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseString = await response.stream.bytesToString();
        Map<String, dynamic> responseJson = json.decode(responseString);

        dynamic newHistoryId = responseJson['history_id'];
        if (newHistoryId != null && newHistoryId != 'null') {
          print('History ID: $newHistoryId');
          localStorage.setItem("history_id", newHistoryId.toString());
        }
      } else {
        print(response.reasonPhrase);
      }
    } else {
      print('History ID already exists: $historyId');
    }
  }

  Widget _buildConnectedUI(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      color: const Color(0xffffffff),
      child: Column(
        children: <Widget>[
          if (widget.reviewMode)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
               "Preview Mode – This is mock data for demonstration only. No real user content is shown.",
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),

          // const SizedBox(
          //   height: 20,
          // ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: widget.reviewMode ? () async {} : _refreshList,

              // onRefresh: _refreshList,
              child: ListView.builder(
                scrollDirection: Axis.vertical,
                itemCount: _cachedList.length,
                itemBuilder: (ctx, index) {
                  var user = _cachedList[index];
                  // debugPrint('MOCK DATA:${user}');

                  return user['chat_id'] == Constants.myName
                      ? Container()
                      : GestureDetector(
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(0, 0, 0, 1),
                            color: Colors.transparent,
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 0.0, horizontal: 0.0),
                              child: Column(
                                children: <Widget>[
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 0.0, horizontal: 0.0),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(0),
                                        bottomRight: Radius.circular(0),
                                        bottomLeft: Radius.circular(0),
                                        topRight: Radius.circular(0),
                                      ),
                                    ),
                                    child: Row(
                                      children: <Widget>[
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 0.0, vertical: 5.0),
                                          height: 80,
                                          width: 80,
                                          child: CachedNetworkImage(
                                            imageUrl:
                                                user['horoscope_image_url'],
                                            placeholder: (context, url) =>
                                                Image.asset(
                                                    'assets/images/photo.png',
                                                    fit: BoxFit.contain),
                                            errorWidget: (context, url,
                                                    error) =>
                                                Image.asset(
                                                    'assets/images/photo.png',
                                                    fit: BoxFit.contain),
                                            fit: BoxFit.contain,
                                            width: 80,
                                            height: 80,
                                          ),
                                        ),
                                        Expanded(
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      user['name'] ?? '',
                                                      style:
                                                          GoogleFonts.poppins(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              color: Colors
                                                                  .black87),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 5),
                                                    Row(
                                                      children: [
                                                        Flexible(
                                                          child: Text(
                                                            user['chat_message'] ==
                                                                        null ||
                                                                    user['chat_message'] ==
                                                                        'null'
                                                                ? ""
                                                                : user[
                                                                    'chat_message'],
                                                            style: GoogleFonts.poppins(
                                                                fontSize: 14,
                                                                color: Colors
                                                                    .black54,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w400),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            maxLines: 1,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                user['chat_time'] == null ||
                                                        user['chat_time'] ==
                                                            'null'
                                                    ? ""
                                                    : formatChatTime(
                                                        user['chat_time']),
                                                style: GoogleFonts.poppins(
                                                    color:
                                                        const Color(0xff03A0E3),
                                                    fontWeight: FontWeight.w400,
                                                    fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                  const Divider(
                                    color: Color(
                                      0xffd8d8d8,
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                          onTap: () {
                            if (widget.reviewMode) {
                              _navigateToMockChat(user);
                            } else {
                              createChatroomAndStartConversation(
                                user['chat_id'],
                                user['name'],
                                user['id'].toString(),
                                user['horoscope_image_url'].toString(),
                                user['mobile_device_id'].toString(),
                              );
                            }
                          }
                        );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
  void _navigateToMockChat(Map<String, dynamic> user) {
    String chatRoomId = "mock_social_${user['chat_id']}_${Constants.myName}";
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Chat(
          chatRoomId,
          user['chat_id'],
          user['name'],
          "2", // Using routeid 2 for social matches
          user['id'],
          user['horoscope_image_url'],
          Constants.myName,
          user['mobile_device_id'],
          isReviewMode: true,
        ),
      ),
    );
  }
  Widget _buildDisconnectedUI() {
    _updateUserStatus(0);
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
                fontSize: 15),
          ),
          Text(
            "Please check your Wi-Fi connection.",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                color: Colors.redAccent,
                fontWeight: FontWeight.w400,
                fontSize: 15),
          ),
        ],
      ),
    );
  }

  Future<void> wificheck(String ssid) async {
    if (ssid == null || ssid.isEmpty) {
      print('SSID is null or empty');
      return;
    }

    var headers = {'Content-Type': 'application/json'};
    var request = http.Request('POST',
        Uri.parse('https://admin.connfy.at/api/wifi_check'));
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

      print(wifi_sttus);

      if (wifi_sttus == 0) {
        //   _fetchListItems(UserId);
      } else {}

      String mobileDeviceId = responseData['data'];
      print(mobileDeviceId);
    } else {
      print(response.reasonPhrase);
    }
  }

  createChatroomAndStartConversation(String uid, String username, String userid,
      dynamic imageurl, String token) {
    print(uid);
    print(Constants.myName);
    if (uid != Constants.myName) {
      String chatRoomId = getChatRoomId(uid, Constants.myName);
      List<String> users = [Constants.myName, uid];
      Map<String, dynamic> chatRoomMap = {
        "chatroomId": chatRoomId,
        "users": users,
      };

      String? chatRoomIdsJson = localStorage.getItem('chatroomids');
      List<String> chatRoomIds = chatRoomIdsJson != null
          ? List<String>.from(jsonDecode(chatRoomIdsJson))
          : [];

      // Check if chatRoomId is not already in the list
      if (!chatRoomIds.contains(chatRoomId)) {
        // Add the new chatRoomId to the list
        chatRoomIds.add(chatRoomId);

        // Store the updated list back to localStorage
        localStorage.setItem('chatroomids', jsonEncode(chatRoomIds));
      }
      print(localStorage.getItem('chatroomids'));
      databaseMethods.addChatRoom(chatRoomMap, chatRoomId);
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => Chat(chatRoomId, uid, username, "2", userid,
                  imageurl, Constants.myName, token)));
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
          Image.asset(
            "assets/images/confywhite.png",
            fit: BoxFit.contain,
            height: 58,
          ),
          PopupMenuButton(
            color: const Color(0xff03A0E3),
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
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const MyProfilePage("2")));
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
      children: <Widget>[
        loadUi(),
        _isLoading ? Loader(loadingTxt: 'Please wait..') : Container()
      ],
    );
  }

  Widget getAppBottomViewnew(BuildContext context,{bool isReviewMode=false}) {
    return Container(
      padding: const EdgeInsets.only(left: 5, bottom: 10, top: 5),
      //height: 100, // Set a fixed height for the container
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Image.asset(
            "assets/images/confywhite.png",
            fit: BoxFit.contain,
            height: 58,
            color: Colors.white,
          ),
          Row(
            children: [
              PopupMenuButton(
                color: Colors.white,
                iconColor: Colors.white,
                itemBuilder: (context) {
                  return [
                    const PopupMenuItem(
                      value: 'pro',
                      child: Text(
                        'My Profile',
                        style: TextStyle(color: Color(0xff03A0E3)),
                      ),
                    ),
                  ];
                },
                onSelected: (String value) {
                  String? storedWifiName =
                      localStorage.getItem('wifiName') ?? '';
                  config_wifi = storedWifiName;
                  if (value == 'pro') {
                    // print('config_wifi');
                    // print(config_wifi);
                    // print(Provider.of<NetworkService>(context, listen: false)
                    //     .wifiName
                    //     .toString()
                    //     .replaceAll('"', ''));
                    // //  Navigator.of(context).push(MaterialPageRoute(builder: (context) => MyProfilePage("1")));
                    bool isConnectedToConfiguredWifi =
                        Provider.of<NetworkService>(context, listen: false)
                                .wifiName
                                .toString()
                                .replaceAll('"', '') ==
                            config_wifi;
                    if (isConnectedToConfiguredWifi == true||isReviewMode) {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) =>  MyProfilePage("2",isReviewMode: isReviewMode,)));
                    }
                  }
                  // print('You Click on popup menu item');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget loadUi() {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          home: Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                leading: Container(),
                backgroundColor: const Color(0xff03A0E3),
                bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(20.0),
                    child: getAppBottomViewnew(context,isReviewMode: widget.reviewMode)),
              ),
              body:widget.reviewMode
                  ? _buildConnectedUI(context) // Show mock data immediately in review mode
              :isInitializing
                  ? const Center(
                      child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xff03A0E3)),
                    ))
                  :
                  Consumer<NetworkService>(
                      builder: (context, networkService, child) {
                        String wifiName =
                            networkService.wifiName?.replaceAll('"', '') ?? '';
                        connected_wifi = wifiName;

                        return FutureBuilder<void>(
                          future: _initLocalStorageFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.done) {
                              String? storedWifiName =
                                  localStorage.getItem('wifiName') ?? '';
                              bool isStoredWifiNameMatched =
                                  storedWifiName.isNotEmpty &&
                                      storedWifiName == wifiName;

                              if (isStoredWifiNameMatched &&
                                  !_isStoredWifiNameMatched) {
                                _refreshList();
                                _isStoredWifiNameMatched = true;
                              } else if (!isStoredWifiNameMatched &&
                                  !_refreshListCalled) {
                                _refreshListCalled = true;
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {});
                              }

                              return _buildUI(context, isStoredWifiNameMatched);
                            } else {
                              return const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xff03A0E3)),
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),

              bottomNavigationBar: SafeArea(
                  child: Container(
                      color: const Color(0xfff5f5f5),
                      height: 80,
                      // padding: EdgeInsets.all(5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        //crossAxisAlignment: CrossAxisAlignment.s,
                        children: [
                          // ignore: deprecated_member_use
                          Container(
                            child: Material(
                              color: const Color(0xfff5f5f5),
                              child: InkWell(
                                //  splashColor: Colors.green,
                                onTap: () {
                                  Navigator.of(context).push(MaterialPageRoute(
                                      builder: (context) => ChatListnew("1",isReviewMode: widget.reviewMode)));
                                },
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    IconButton(
                                      iconSize: 24,
                                      color: Colors.grey,
                                      onPressed: () {
                                        Navigator.of(context).push(
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    ChatListnew("1",isReviewMode: widget.reviewMode)));
                                      },
                                      icon: SvgPicture.asset(
                                        'assets/icons/chat.svg',
                                        colorFilter: const ColorFilter.mode(
                                            Colors.grey, BlendMode.srcIn),
                                      ),
                                    ), // <-- Icon
                                    const Text(
                                      "Chats",
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 12),
                                    ), // <-- Text
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 20,
                          ),
                          Container(
                            child: Material(
                              color: const Color(0xfff5f5f5),
                              child: InkWell(
                                // splashColor: Colors.green,
                                onTap: () {
                                  Navigator.of(context).push(MaterialPageRoute(
                                      builder: (context) =>
                                          SocilamatchList("2",reviewMode: widget.reviewMode)));
                                },
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    IconButton(
                                      color: Color(0xff03A0E3),
                                      onPressed: () {
                                        Navigator.of(context).push(
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    SocilamatchList("2",reviewMode: widget.reviewMode)));
                                      },
                                      icon: SvgPicture.asset(
                                        'assets/icons/social-match.svg',
                                        colorFilter: const ColorFilter.mode(
                                            Color(0xff03A0E3), BlendMode.srcIn),
                                      ),
                                    ),
                                    const Text(
                                      "Social Match",
                                      style: TextStyle(
                                          color: Color(0xff03A0E3),
                                          fontSize: 12),
                                    ), // <-- Text
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 20,
                          ),
                          Container(
                            child: Material(
                              color: const Color(0xfff5f5f5),
                              child: InkWell(
                                // splashColor: Colors.green,
                                onTap: () {
                                  Navigator.of(context).push(MaterialPageRoute(
                                      builder: (context) => EventsList(isReviewMode: widget.reviewMode,)));
                                },
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    IconButton(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    EventsList(isReviewMode: widget.reviewMode)));
                                      },
                                      icon: SvgPicture.asset(
                                        'assets/icons/social-event.svg',
                                        colorFilter: const ColorFilter.mode(
                                            Colors.grey, BlendMode.srcIn),
                                      ),
                                    ),
                                    const Text(
                                      "Social Events",
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 12),
                                    ), // <-- Text
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 20,
                          ),
                          Container(
                            child: Material(
                              color: const Color(0xfff5f5f5),
                              child: InkWell(
                                // splashColor: Colors.green,
                                onTap: () {
                                  Navigator.of(context).push(MaterialPageRoute(
                                      builder: (context) => EventsList(isReviewMode: widget.reviewMode,)));
                                },
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Container(
                                      height: 47,
                                      width: 53,
                                      child: IconButton(
                                        onPressed: () {
                                          if (widget.reviewMode) {
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                    title: Text("Preview Mode"),
                                                content: Text(
                                                    "This feature is currently in preview mode for App Review.\n\n"
                                                    "In the full version, this opens Google Reviews when connected to admin WiFi."
                                                 ) ,
                                            
                                                // title: Text("Example Preview"),
                                                // content: Text("This is a preview. In the full version, this opens Google Reviews."),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context),
                                                    child: Text("OK"),
                                                  ),
                                                ],
                                              ),
                                            );
                                            // setState(() {
                                            //   googlerul="https://www.google.com/maps/place/ZAM+ZAM+COMMUNICATION/@13.0701901,80.2683662,17z/data=!3m1!4b1!4m6!3m5!1s0x3a52661b54bf4205:0x2a5512e2fba5dd0d!8m2!3d13.0701849!4d80.2709411!16s%2Fg%2F1pt_zcbww?entry=ttu&g_ep=EgoyMDI1MDUxMy4xIKXMDSoASAFQAw%3D%3D";
                                            // });
                                            _launchUrl();
                                          } else {
                                            bool isConnectedToConfiguredWifi =
                                                Provider
                                                    .of<NetworkService>(
                                                    context,
                                                    listen: false)
                                                    .wifiName
                                                    .toString()
                                                    .replaceAll('"', '') ==
                                                    config_wifi;
                                            if (isConnectedToConfiguredWifi ==
                                                true) {
                                              _launchUrl();
                                            }

                                            //          Navigator.of(context).push(MaterialPageRoute(
                                            // builder: (context) => ReviewScreen(
                                            //     "https://www.google.com/search?q=my+business&mat=CYnmlD3i_GwwEkwBezTaAax5KIUml55b5P-vVH-yOxpuBb_Vup80YYH4BwSeaPddvjtIb7UdzJC5wemuue4W-PSH7qRm6rpHRRh5-HeDg-ZfB6dKHdNVGggHBhoz3H860g&hl=en&authuser=0",
                                            //     1)));
                                          }
                                        },
                                        icon: SvgPicture.asset(
                                          'assets/icons/socialreview.svg',
                                          colorFilter: const ColorFilter.mode(
                                              Colors.grey, BlendMode.srcIn),
                                        ),
                                      ),
                                    ),
                                    const Text(
                                      "Social Review",
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 12),
                                    ), // <-- Text
                                  ],
                                ),
                              ),
                            ),
                          )
                        ],
                      ))))),
    );
  }

  Widget _buildUI(BuildContext context, bool isStoredWifiNameMatched) {
    if (widget.reviewMode) {
      return _buildConnectedUI(context);
    }
    return StreamBuilder(
      stream: dataStream, // Stream that listens for new data
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          // New data added, refresh the list
          _refreshList();
          return isStoredWifiNameMatched
              ? _buildConnectedUI(context)
              : _buildDisconnectedUI();
        }
        return isStoredWifiNameMatched
            ? _buildConnectedUI(context)
            : _buildDisconnectedUI();
      },
    );
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
    final colorClickableText = const Color(0xff03A0E3);
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
          //textDirection: TextDirection.rtl, //better to pass this from master widget if ltr and rtl both supported
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

class NetworkAwareAppBar extends StatefulWidget implements PreferredSizeWidget {
  @override
  _NetworkAwareAppBarState createState() => _NetworkAwareAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _NetworkAwareAppBarState extends State<NetworkAwareAppBar> {
  //final LocalStorage storage = LocalStorage('wifi');
  String config_wifi = "";

  @override
  void initState() {
    super.initState();

    retrieveWifiName();
  }

  Future<void> retrieveWifiName() async {
    print(Provider.of<NetworkService>(context)
        .wifiName
        .toString()
        .replaceAll('"', ''));
    var headers = {'Content-Type': 'application/json'};
    var request = http.Request('POST',
        Uri.parse('https://admin.connfy.at/api/wifi_details'));
    request.body = json.encode({
      "wifi_name": Provider.of<NetworkService>(context)
          .wifiName
          .toString()
          .replaceAll('"', '')
    });
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
            print('LOTRM Name: $wifiName');

            setState(() {
              config_wifi = wifiName;
            });

            /*  config_wifi = wifiName;
            shop_id = shopid;
            googlerul = url_;*/

            // Now you can use the WiFi name as needed
          } else {
            print('WiFi name not found or is null in the data');
          }
        } else {
          print('Data not found or is null in the response');
        }
      } else {
        print('Failed to retrieve WiFi name: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error occurred: $e');
    }
  }

  Future<void> _loadConfigWifi() async {
    //  await storage.ready;
    setState(() {
      config_wifi = localStorage.getItem('wifiname')!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return getAppBottomView(context);
  }

  Widget _buildTitle(BuildContext context) {
    if (config_wifi.isEmpty) {
      return const Text(
        "Loading...",
        style: TextStyle(color: Color(0xff03A0E3)),
      );
    } else {
      bool isConnectedToConfiguredWifi = Provider.of<NetworkService>(context)
              .wifiName
              .toString()
              .replaceAll('"', '') ==
          config_wifi;
      return Text(
        isConnectedToConfiguredWifi ? "Connected" : "Not Connected",
        style: TextStyle(
            color: isConnectedToConfiguredWifi ? Colors.green : Colors.red),
      );
    }
  }

  Widget getAppBottomView(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 5, bottom: 10, top: 5),
      //height: 100, // Set a fixed height for the container
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Image.asset(
            "assets/images/confywhite.png",
            fit: BoxFit.contain,
            height: 58,
            color: Colors.white,
          ),
          Row(
            children: [
              PopupMenuButton(
                color: Colors.white,
                iconColor: Colors.white,
                itemBuilder: (context) {
                  return [
                    const PopupMenuItem(
                      value: 'pro',
                      child: Text(
                        'My Profile',
                        style: TextStyle(color: Color(0xff03A0E3)),
                      ),
                    ),
                  ];
                },
                onSelected: (String value) {
                  if (value == 'pro') {
                    //  Navigator.of(context).push(MaterialPageRoute(builder: (context) => MyProfilePage("1")));
                    bool isConnectedToConfiguredWifi =
                        Provider.of<NetworkService>(context, listen: false)
                                .wifiName
                                .toString()
                                .replaceAll('"', '') ==
                            config_wifi;
                    if (isConnectedToConfiguredWifi == true) {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => const MyProfilePage("2")));
                    }
                  }
                  print('You Click on popup menu item');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
