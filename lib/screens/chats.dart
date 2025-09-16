import 'dart:async';
import 'dart:convert';

import 'package:chatapp/constant.dart';
import 'package:chatapp/helper/constants.dart';
import 'package:chatapp/screens/profile.dart';
import 'package:chatapp/screens/socialmatch.dart';
import 'package:chatapp/screens/user_profile.dart';
import 'package:chatapp/services/database.dart';
import 'package:chatapp/util/content_filter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:localstorage/localstorage.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../AppColorCodes.dart';
import '../controller/Constant.dart';
import '../main.dart';
import '../widgets/mock_helperchat.dart';
import 'ChatProvider.dart';
import 'NetworkService.dart';
import 'chatlistnew.dart';

class Chat extends StatefulWidget {
  final chatRoomId, uid, username, routeid, user_id, imageurl, senderid, token;
   final bool isReviewMode;
  const Chat(this.chatRoomId, this.uid, this.username, this.routeid,
      this.user_id, this.imageurl, this.senderid, this.token,
      {super.key,this.isReviewMode=false});

  @override
  _ChatState createState() => _ChatState(
      chatRoomId, uid, username, routeid, user_id, imageurl, senderid, token);
}

class _ChatState extends State<Chat> {
  var chatRoomId, uid, username, routeid, user_id, imageurl, senderid, token;
  _ChatState(this.chatRoomId, this.uid, this.username, this.routeid,
      this.user_id, this.imageurl, this.senderid, this.token);
  Stream<QuerySnapshot>? chats;
  Stream<QuerySnapshot>? mockChats;
  int wifi_sttus = -1;
  String statuslable = "";
  dynamic colorcodelable;
  List<String> supplier_typelist = ["NEW REQUESTS", 'OLD REQUESTS'];
  Timer? _timer;
  final String _connectionStatus = 'Unknown';
  String globalTime = "";
  late ConnectivityResult result;
  final StreamController<bool> _streamController = StreamController<bool>();
  late StreamSubscription<bool> _streamSubscription;
  final NetworkInfo _networkInfo = NetworkInfo();
  final bool _scrollingToBottom = false;
  TextEditingController messageEditingController = TextEditingController();
  String? UserId = "";
  String? loginuser = "";
  //final LocalStorage storage = new LocalStorage('wifi');
  String config_wifi = "emty";

  void scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0, // Scroll to the top
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Widget chatMessages() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        // Scroll to the end of the ListView
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });

    return SafeArea(
      child: StreamBuilder(
        stream: chats,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasData) {
            // Automatically scroll to the end when new data is loaded
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients) {
                _scrollController
                    .jumpTo(_scrollController.position.maxScrollExtent);
              }
            });

            return ListView.builder(
              reverse: true,
              itemCount: snapshot.data?.docs.length,
              controller: _scrollController,
              itemBuilder: (context, index) {
                var messageData = snapshot.data?.docs[index];
                if (messageData == null) {
                  return const SizedBox.shrink();
                }

                String? messageId = messageData.id;
                String message = messageData["message"];
                bool sendByMe = Constants.myName == messageData["sendBy"];
                Timestamp time = messageData["time"];
                bool isRead = messageData["read"];
                bool isDelivered = messageData["delivered"];
                bool isSent = messageData["sent"];

                return Messages(
                  message: message,
                  sendByMe: sendByMe,
                  time: time,
                  imageurl: imageurl,
                  isRead: isRead,
                  isDelivered: isDelivered,
                  isSent: isSent,
                  chatRoomId: chatRoomId,
                  messageID: messageId,
                );
              },
            );
          } else {
            return Container();
          }
        },
      ),
    );
  }

  bool readstatus = false;
  void addMessage() {
    String messageToSend = messageEditingController.text;
    print(" BEFORE Message contains  content:${messageToSend}.");

    
    // ❌ If the message contains banned words, block sending
    if (!ContentFilter().isMessageAllowed(messageToSend)) {
      // You can show a toast/snackbar here if needed
      print("Message contains inappropriate content.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Your message contains inappropriate words."),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    messageToSend = ContentFilter().filterMessage(messageToSend);
      print(" AFTER Message contains  content:${messageToSend}.");

    if (messageToSend.isNotEmpty) {

    // if (messageEditingController.text.isNotEmpty) {
      Map<String, dynamic> chatMessageMap = {
        "sendBy": Constants.myName,
        "message": messageEditingController.text,
        'time': Timestamp.now(), // Using Firestore Timestamp
        'read': false, // Initial read status is false
        'delivered': false, // Initial delivered status is false
        'sent': true, // Message is initially sent
      };

      // Add message to the database
      DatabaseMethods().addMessage(chatRoomId, chatMessageMap);
      sendPushNotification(token, loginuser!, messageToSend);

      // sendPushNotification(token, loginuser!, messageEditingController.text);

      // Update read status for previous messages in the chat room (assuming this is necessary)
      getGlobalTime(messageToSend);

      setState(() {
        messageEditingController.text = "";
      });
    }
  }

  static Future<void> sendPushNotification(
      String mobileDeviceId, String title, String description) async {
    var headers = {
      'Authorization':
          'key=AAAAGLDkAjg:APA91bFsO9qoCm-dYTaDicJ9cHDsg8ur4HY-dqx2tRzSJrh1X7Lxg0c0pZrBEfSSnRoOHdAMUMuRe59YnWkKXFMA3BOTw5QLAqhXzUe_MQ6Bsuu71RvxGkJ5l23obQBayyOyLRJzXYk1',
      'Content-Type': 'application/json'
    };
    var request = http.Request(
        'POST',
        Uri.parse(
            'https://admin.connfy.at/api/send_notification'));
    request.body = json.encode({
      "title": "Message from:$title",
      "description": description,
      "mobile_device_id": mobileDeviceId
    });
    request.headers.addAll(headers);
    print(request.body);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      print(await response.stream.bytesToString());
    } else {
      print(response.reasonPhrase);
    }
  }

  Future<void> addchannel_server() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //Return String
    UserId = prefs.getString('UserId');
    print(UserId);
    var headers = {'Content-Type': 'application/json'};
    var request = http.Request(
        'POST',
        Uri.parse(
            'https://admin.connfy.at/api/channel_create'));
    request.body = json.encode({
      "user_id": UserId,
      "request_user_id": user_id,
      "channel_id": chatRoomId
    });
    print(json.encode({
      "user_id": UserId,
      "request_user_id": user_id,
      "channel_id": chatRoomId
    }));
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      print(await response.stream.bytesToString());
    } else {
      print(response.reasonPhrase);
    }
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
    }
  }

  void showNotificationDialog(String title, String body, String imageUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: MediaQuery.of(context).size.width *
                0.8, // Set a finite width for the content
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (imageUrl.isNotEmpty)
                  FutureBuilder(
                    future: precacheImage(NetworkImage(imageUrl), context),
                    builder:
                        (BuildContext context, AsyncSnapshot<void> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 100, // Placeholder height
                          child: Center(child: CircularProgressIndicator()),
                        );
                      } else {
                        return Image.network(
                          imageUrl,
                          height: 100, // Adjust height as needed
                          width: double.infinity,
                          fit: BoxFit.cover,
                        );
                      }
                    },
                  ),
                Text(body),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  late final ScrollController _scrollController = ScrollController();
  final bool _isScrolledUp = false;
  late final ScrollController scrollController;
  List<Map<String, dynamic>> mockMessages = [];

  static const _scrollValueThreshold = 0.8;
  @override
  void initState() {
    super.initState();

    retrive();
    if (widget.isReviewMode) {
      // Initialize mock data
      _initializeMockChats();
    } else {
    addchannel_server();
    print('chatRoomId $chatRoomId');
    scrollController = ScrollController(onAttach: (position) {
      var chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.scrollToBottom(scrollController);
    });
    DatabaseMethods().getChats(widget.chatRoomId).then((val) {
      setState(() {
        chats = val;
      });
      for (int i = 0; i < 12; i++) {
        Future.delayed(Duration(milliseconds: i * 50), () {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        });
      }

      // Use a delayed scroll to ensure the UI is fully built before scrolling
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 300), () {
          //scrollToBottom_();
        });
      });
    });
}
  }
  void _initializeMockChats() {
    mockMessages = [
      {
        "message": "Hello there! This is a test message",
        "sendBy": widget.uid,
        "time": Timestamp.now(),
        "read": true,
        "delivered": true,
        "sent": true,
        "id": "mock_1",
      },
      {
        "message": "Hi! How are you today?",
        "sendBy": Constants.myName,
        "time": Timestamp.now(),
        "read": true,
        "delivered": true,
        "sent": true,
        "id": "mock_2",
      },
      {
        "message": "Just testing the example functionality",
        "sendBy": widget.uid,
        "time": Timestamp.now(),
        "read": true,
        "delivered": true,
        "sent": true,
        "id": "mock_3",
      },
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
        scrollToBottom_();
      }
    });
  }
  final bool _isScrolling = false;

  void scrollToBottom_() {
    for (int i = 0; i < 12; i++) {
      Future.delayed(Duration(milliseconds: i * 50), () {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });
    }

    _scrollController.animateTo(_scrollController.position.maxScrollExtent,
        duration: const Duration(seconds: 1), curve: Curves.easeOut);
  }

  void scrollToBottom(ScrollController scrollController) {
    if (scrollController.hasClients) {
      for (int i = 0; i < 12; i++) {
        Future.delayed(Duration(milliseconds: i * 50), () {
          scrollController.jumpTo(scrollController.position.maxScrollExtent);
        });
      }
    } else {
      print("gdfgfgfg fgfhfhhh");
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _markMessagesAsRead() async {
    await Future.delayed(const Duration(seconds: 3));

    var snapshot = await FirebaseFirestore.instance
        .collection("chatRoom")
        .doc(widget.chatRoomId)
        .collection("chats")
        .where("read", isEqualTo: false)
        .get();

    for (var doc in snapshot.docs) {
      await updateMessageReadStatus(widget.chatRoomId, doc.id);
    }
    if (mounted && !readstatus) {
      _markMessagesAsRead();
    }
  }

  Future<void> updateMessageReadStatus(
      String chatRoomId, String messageId) async {
    try {
      await FirebaseFirestore.instance
          .collection("chatRoom")
          .doc(chatRoomId)
          .collection("chats")
          .doc(messageId)
          .update({'read': true});
    } catch (e) {
      print('Failed to update message read status: ${e.toString()}');
    }
  }

  Future retrive() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //Return String
    UserId = prefs.getString('UserId')??"";
    loginuser = prefs.getString('loginuser')??"";
    // await storage.ready;
    String? name = localStorage.getItem('wifiname')??"";
    String? ssid = localStorage.getItem('SSID')??"";
    config_wifi = localStorage.getItem('wifiname')??"";
    // _initNetworkInfo();

    // _timer = Timer.periodic(Duration(seconds: 10), (Timer t) => _initNetworkInfo());
  }

  Future<String?> getGlobalTime(String msg) async {
    try {
      // Make a GET request to the World Time API
      var response =
          await http.get(Uri.parse('https://worldtimeapi.org/api/ip'));

      // Check if the request was successful
      if (response.statusCode == 200) {
        // Parse the response JSON
        Map<String, dynamic> data = jsonDecode(response.body);

        // Extract the global time from the response
        globalTime = data['datetime'];
        addmessage_server(msg, globalTime);

        return globalTime;
      } else {
        addmessage_server(msg, "");
        print('Failed to fetch global time: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      addmessage_server(msg, "");
      print('Error fetching global time: $e');
      return null;
    }
  }

  AppBar buildAppBar(BuildContext context) {
    bool isConnectedToConfiguredWifi = Provider.of<NetworkService>(context)
            .wifiName
            .toString()
            .replaceAll('"', '') ==
        config_wifi;
    return AppBar(
      backgroundColor: const Color(0xff03A0E3),
      titleSpacing: 0,
      title: Builder(
        builder: (context) {
          return GestureDetector(
            onTap: () {
              print("Profile tapped user:$UserId"); // Debug print
              try {
                print('Before _handleProfileTap');
                _handleProfileTap(context);
                print('After _handleProfileTap');
              } catch (e, s) {
                print('Exception in onTap: $e\n$s');
              }
              },

            child: Row(
              children: [
                Stack(
                  children: [
                    Image.network(
                      imageurl,
                      fit: BoxFit.contain,
                      height: 45,
                    ),
                    isConnectedToConfiguredWifi == true
                        ? Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                  color: Color(0xff03A0E3), shape: BoxShape.circle),
                            ),
                          )
                        : Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                  color: Colors.red, shape: BoxShape.circle),
                            ),
                          )
                  ],
                ),
                const SizedBox(
                  width: pDefaultPadding * 0.7,
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width / 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      ),
                      const SizedBox(
                        height: 1,
                      ),
                      Opacity(
                          opacity: 0.9,
                          child: isConnectedToConfiguredWifi == true
                              ? const Text('online',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.white))
                              : const Text('Offline',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.red)))
                    ],
                  ),
                )
              ],
            ),
          );
        }
      ),
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios,
          color: Colors.white,
        ),
        onPressed: () {
          //  Navigator.of(context).push(MaterialPageRoute(builder: (context) => ChatList(uid)));
          if (routeid == '1') {
            Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => ChatListnew("1",isReviewMode: widget.isReviewMode,)));
          } else {
            Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => SocilamatchList("2",reviewMode: widget.isReviewMode)));
          }
        },
      ),
      actions: [
        PopupMenuButton(
            color: Colors.white,
            iconColor: Colors.white,
            // add icon, by default "3 dot" icon
            // icon: Icon(Icons.book)
            itemBuilder: (context) {
              return [
                const PopupMenuItem<int>(
                  value: 0,
                  child: Text("Profile", style: TextStyle(color: Colors.blue)),
                ),
              ];
            },
            onSelected: (value) {
              if (value == 0) {
                if (isConnectedToConfiguredWifi == true) {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => ProfilePage(chatRoomId, uid,
                          username, routeid, user_id, imageurl, token,)));
                }
              } else if (value == 1) {
                print("Settings menu is selected.");
              } else if (value == 2) {
                print("Logout menu is selected.");
              }
            }),
      ],
    );
  }

  void _handleProfileTap(BuildContext context) {

    bool isConnectedToConfiguredWifi = Provider.of<NetworkService>(context,listen: false)
        .wifiName
        .toString()
        .replaceAll('"', '') == config_wifi;
    // Check if mounted
    if (!mounted) {
      print("Widget not mounted");
      return;
    }
    if (widget.isReviewMode) {
      // This mock is for Apple App Store review purposes only.
      // Block and Report functionalities are non-functional in review mode
      // Mock profile view
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ProfilePageForUser(
            "mock_chat_id",
            uid,
            username,
            "1",
            "mock_user_id",
            imageurl,
            "mock_token",
            isCurrentUser: false,
            onBlock: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Block Functionality disabled in review mode. This feature is available in the live version.")),
              );
            },
            onReport: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Report Functionality disabled in review mode. This feature is available in the live version.")),
              );
            },
          ),
        ),
      );
    } else if (isConnectedToConfiguredWifi) {
      // Real profile view
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ProfilePageForUser(
            chatRoomId,
            uid,
            username,
            routeid,
            user_id,
            imageurl,
            token,
            isCurrentUser: false,
            onBlock: _handleBlockUser,
            onReport: _handleReportUser,
          ),
        ),
      ).then((_) {
        // This callback ensures we maintain state when returning
        if (mounted) setState(() {});
      });
    }
  }
  Future<void> _handleBlockUser() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Block User"),
        content: Text("Are you sure you want to block $username?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel", style: TextStyle(color: Colors.grey[600])),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Block", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await http.post(
          Uri.parse("https://admin.connfy.at/api/user_blocked"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"id": user_id}), // user_id from your context
        );

        if (response.statusCode == 200) {
          Fluttertoast.showToast(
              msg: "$username has been blocked",
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.CENTER,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.green,
              textColor: Colors.white,
              fontSize: 16);
          // Optionally navigate back
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else {
          Fluttertoast.showToast(
            msg: "Failed to block user. Try again.",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.CENTER,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0,
          );
        }
      } catch (e) {
        Fluttertoast.showToast(
          msg: "Error blocking user: $e",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );

      }
        // Navigate back to chat list
      // Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _handleReportUser() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Report User"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Please select a reason for reporting $username:"),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text("Inappropriate content"),
                  selected: false,
                  onSelected: (_) => Navigator.pop(context, "Inappropriate content"),
                ),
                ChoiceChip(
                  label: const Text("Harassment"),
                  selected: false,
                  onSelected: (_) => Navigator.pop(context, "Harassment"),
                ),
                ChoiceChip(
                  label: const Text("Spam"),
                  selected: false,
                  onSelected: (_) => Navigator.pop(context, "Spam"),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: Colors.grey[600])),
          ),
        ],
      ),
    );

      if (reason != null) {
        try {
          final response = await http.post(
            Uri.parse("https://admin.connfy.at/api/userreport"), // Your API endpoint
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "message": "This user $username sent $reason",
              "name": "mohammed", // Replace with actual reporter name if needed
            }),
          );

          if (response.statusCode == 200) {
            Fluttertoast.showToast(
              msg: "$username has been reported for $reason",
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.TOP,
              backgroundColor: Colors.green,
              textColor: Colors.white,
              fontSize: 16.0,
            );
          } else {
            Fluttertoast.showToast(
              msg: "Failed to report user. Try again.",
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.CENTER,
              backgroundColor: Colors.red,
              textColor: Colors.white,
              fontSize: 16.0,
            );
          }
        } catch (e) {
          Fluttertoast.showToast(
            msg: "Error reporting user: $e",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.CENTER,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0,
          );
        }
      }

  }
  bool _isNearBottom() {
    if (!_scrollController.hasClients) return false;
    const threshold = 200.0; // Set a threshold distance
    return _scrollController.position.extentAfter < threshold;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: buildAppBar(context),
      body: widget.isReviewMode
          ? _buildMockChatUI() :Consumer<ChatProvider>(builder: (_, chatProvider, __) {
        return Stack(
          children: [
            Consumer<NetworkService>(
              builder: (context, networkService, child) {
                if (networkService.networkStatus == NetworkStatus.Online) {
                  if (networkService.toString().replaceAll('"', '') ==
                      config_wifi) {
                    wifi_sttus = 1;
                  } else {
                    wifi_sttus = 0;
                  }
                  return (networkService.wifiName)
                              .toString()
                              .replaceAll('"', '') ==
                          config_wifi
                      ? SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Expanded(
                                child: StreamBuilder(
                                  stream: chats,
                                  builder: (BuildContext context,
                                      AsyncSnapshot<QuerySnapshot> snapshot) {
                                    if (snapshot.hasData) {
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                        if (!_isScrolledUp && _isNearBottom()) {
                                          //  scrollToBottom_();
                                        }
                                      });

                                      return

                                          SingleChildScrollView(
                                        controller: _scrollController,
                                        //  reverse: true,
                                        child: Column(
                                          children: snapshot.data!.docs
                                              .map((messageData) {
                                            var message =
                                                messageData["message"];
                                            bool sendByMe = Constants.myName ==
                                                messageData["sendBy"];
                                            Timestamp time =
                                                messageData["time"];
                                            bool isRead = messageData["read"];
                                            bool isDelivered =
                                                messageData["delivered"];
                                            bool isSent = messageData["sent"];
                                            WidgetsBinding.instance
                                                .addPostFrameCallback((_) {
                                              scrollToBottom_();
                                            });

                                            return Messages(
                                              message: ContentFilter().filterMessage(message), // << Filtered for UI

                                              // message: message,
                                              sendByMe: sendByMe,
                                              time: time,
                                              imageurl: imageurl,
                                              isRead: isRead,
                                              isDelivered: isDelivered,
                                              isSent: isSent,
                                              chatRoomId: chatRoomId,
                                              messageID: messageData.id,
                                            );
                                          }).toList(),
                                        ),
                                      );
                                    } else {
                                      return Container();
                                    }
                                  },
                                ),
                              ),
                              Container(
                                alignment: Alignment.bottomCenter,
                                width: MediaQuery.of(context).size.width,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        onTap: () {
                                          _scrollController.animateTo(
                                              _scrollController
                                                  .position.maxScrollExtent,
                                              duration:
                                                  const Duration(seconds: 2),
                                              curve: Curves.easeOut);
                                          // scrollToBottom(_scrollController);
                                        },
                                        controller: messageEditingController,
                                        cursorColor: Colors.blue,
                                        maxLines: null,
                                        keyboardType: TextInputType.multiline,
                                        textInputAction:
                                            TextInputAction.newline,
                                        decoration: kTextFieldDecoration
                                            .copyWith(hintText: 'Message...'),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        // scrollToBottom_();
                                        addMessage();
                                        scrollToBottom_();
                                        scrollToBottom(_scrollController);
                                        _scrollController.animateTo(
                                            _scrollController
                                                .position.maxScrollExtent,
                                            duration:
                                                const Duration(seconds: 2),
                                            curve: Curves.easeOut);
                                        // chatProvider.scrollToBottom(scrollController);
                                        // scrollToBottom_();
                                      },
                                      icon: const Icon(Icons.send,
                                          color: Color(0xff03A0E3)),
                                    ),
                                    /* IconButton(
                              onPressed: scrollToTop,  // Call the scroll to top function
                              icon: const Icon(Icons.arrow_upward, color: Color(0xff03A0E3)),
                            ),*/
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      : _buildNoWifiUI();
                } else {
                  return _buildNoWifiUI();
                }
              },
            ),
            if (_isScrolledUp)
              Positioned(
                bottom: 110,
                left: MediaQuery.of(context).size.width / 2 - 28,
                child: FloatingActionButton(
                  backgroundColor: Colors.white,
                  //elevation: 16.0,
                  onPressed: () {
                    scrollToBottom(_scrollController);
                  },
                  shape: const CircleBorder(),
                  child: const Icon(
                    Icons.keyboard_arrow_down_outlined,
                    color: Colors.blue,
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
  Widget _buildMockChatUI() {
    return SafeArea(
      child: Column(
        children: [
          // Add a banner to indicate review mode
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.orange,
            child: const Text(
            "Example Preview – This is a sample chat view",
              style: TextStyle(color: Colors.white),
            ),
          ),
          Expanded(
            child: ListView.builder(
                controller: _scrollController,
                reverse: true,
                itemCount: mockMessages.length,
                itemBuilder: (context, index) {
                  final messageData = mockMessages[index];
                  return MockMessages(
                    message: ContentFilter().filterMessage(messageData["message"] ?? ""),

                    // message: messageData["message"] ?? "",
                    sendByMe: Constants.myName == (messageData["sendBy"] ?? ""),
                    time: messageData["time"] ?? Timestamp.now(),
                    imageurl: messageData["imageurl"] ??
                        "https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_960_720.png",
                    isRead: messageData["read"] ?? true,
                  );
                }
            ),
          ),          // Disabled input field in review mode
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: const AbsorbPointer(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Chat disabled in preview mode',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildNoWifiUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            height: 200,
            width: 200,
            padding: const EdgeInsets.fromLTRB(35, 10, 35, 10),
            child: Image.asset(
              "assets/images/nowifi.png",
              fit: BoxFit.contain,
            ),
          ),
          Text(
            "Please #getsocial! You are not connected.",
            style: GoogleFonts.poppins(
              color: Colors.black45,
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
          Text(
            "Please check your Wi-Fi connection.",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.redAccent,
              fontWeight: FontWeight.w400,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
  String formatDate(String timestamp) {
    // Extract the date and time components
    List<String> dateTimeParts = timestamp.split('T');
    String datePart = dateTimeParts[0];
    String timePart = dateTimeParts[1].split('.')[0];

    // Parse the date
    DateTime dateTime = DateTime.parse('$datePart $timePart');

    // Extract and parse the timezone offset
    String offsetString = timestamp.substring(timestamp.length - 6);
    int hours = int.parse(offsetString.substring(0, 3));
    int minutes = int.parse(offsetString.substring(3));
    Duration offset = Duration(hours: hours, minutes: minutes);

    // Adjust the time according to the timezone offset
    dateTime = dateTime.subtract(offset);

    var formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    String formatted = formatter.format(dateTime);
    return formatted;
  }

  Future<void> addmessage_server(String message, String globalTime) async {
    String formattedDate = "";
    if (globalTime.isEmpty) {
      formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    } else {
      DateTime dateTime = DateTime.parse(globalTime).toLocal();

      var formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
      formattedDate = formatter.format(dateTime);
    }
    // print('globaltime $globalTime');
    // print('formattedDate $formattedDate');
    /*   String cetTime = convertLocalToCET(formattedDate);
    print('Final Converted CET Time: $cetTime');

    print('formattedDateffff $formattedDate');*/
    //  sendNotification(message, formattedDate);
    var headers = {'Content-Type': 'application/json'};
    var request = http.Request('POST',
        Uri.parse('https://admin.connfy.at/api/chat_msg'));
    request.body = json.encode({
      "sender_id": senderid,
      "receiver_id": uid,
      "channel_id": chatRoomId,
      "message": message,
      "time": formattedDate
    });
    //print(json.encode({"sender_id": senderid, "receiver_id": uid, "channel_id": chatRoomId, "message": message, "time": formattedDate}));
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      print(await response.stream.bytesToString());
    } else {
      print(response.reasonPhrase);
    }
  }


  Future<void> sendNotification(String message, String time) async {
    var headers = {
      'Authorization':
          'key=AAAAGLDkAjg:APA91bFsO9qoCm-dYTaDicJ9cHDsg8ur4HY-dqx2tRzSJrh1X7Lxg0c0pZrBEfSSnRoOHdAMUMuRe59YnWkKXFMA3BOTw5QLAqhXzUe_MQ6Bsuu71RvxGkJ5l23obQBayyOyLRJzXYk1', // Replace with your actual FCM server key
      'Content-Type': 'application/json'
    };

    var request =
        http.Request('POST', Uri.parse('https://fcm.googleapis.com/fcm/send'));
    request.body = json.encode({
      "to": token, // Replace 'token' with the actual FCM token of the recipient
      "notification": {
        "title": "New Message",
        "body": message,
        "image": "" // If you have an image URL, include it here
      },
      "data": {
        "key_1": "value_1", // Custom data if needed
        "key_2": time
      }
    });

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      print(await response.stream.bytesToString());
    } else {
      print(response.reasonPhrase);
    }
  }
}

Container chatTextField1(BuildContext context) {
  return Container(
      //  height: MediaQuery.of(context).size.height,
      // width: MediaQuery.of(context).size.width,
      // decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomLeft, colors: [Colors.blue.shade100, Colors.grey.shade100])),
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding,
        vertical: kDefaultPadding / 2,
      ),
      child: SafeArea(
        child: Row(
          children: [
            const Icon(Icons.mic, color: Colors.blue),
            const SizedBox(width: kDefaultPadding),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding * 0.75,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.sentiment_satisfied_alt_outlined,
                      color: Theme.of(context)
                          .textTheme
                          .bodyLarge!
                          .color!
                          .withOpacity(0.64),
                    ),
                    const SizedBox(width: kDefaultPadding / 4),
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          hintText: "Type message",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.attach_file,
                      color: Theme.of(context)
                          .textTheme
                          .bodyLarge!
                          .color!
                          .withOpacity(0.64),
                    ),
                    const SizedBox(width: kDefaultPadding / 4),
                    Icon(
                      Icons.camera_alt_outlined,
                      color: Theme.of(context)
                          .textTheme
                          .bodyLarge!
                          .color!
                          .withOpacity(0.64),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ));
}

class MessageTile extends StatelessWidget {
  final String message;
  final bool sendByMe;

  const MessageTile({super.key, required this.message, required this.sendByMe});

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.only(
            top: 8,
            bottom: 8,
            left: sendByMe ? 0 : 24,
            right: sendByMe ? 24 : 0),
        alignment: sendByMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: sendByMe
              ? const EdgeInsets.only(left: 30)
              : const EdgeInsets.only(right: 30),
          padding:
              const EdgeInsets.only(top: 8, bottom: 8, left: 20, right: 20),
          decoration: BoxDecoration(
              borderRadius: sendByMe
                  ? const BorderRadius.only(
                      bottomLeft: Radius.circular(0),
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                      bottomRight: Radius.circular(10))
                  : const BorderRadius.all(Radius.circular(20)),
              color: sendByMe ? Colors.black12 : Colors.white),
          child: Text(message,
              textAlign: TextAlign.start,
              style: GoogleFonts.roboto(
                textStyle: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  //fontWeight: FontWeight.bold,
                ),
              )),
        ));
  }
}

class Messages extends StatelessWidget {
  final String message;
  final bool sendByMe;
  final Timestamp time;
  final dynamic imageurl;
  final bool isRead;
  final String messageID;
  final String chatRoomId;
  final bool isDelivered;
  final bool isSent;

  const Messages({
    Key? key,
    required this.message,
    required this.sendByMe,
    required this.time,
    required this.imageurl,
    required this.isRead,
    required this.messageID,
    required this.chatRoomId,
    required this.isDelivered,
    required this.isSent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _MessagesWidget(
      message: message,
      sendByMe: sendByMe,
      time: time,
      imageurl: imageurl,
      isRead: isRead,
      messageID: messageID,
      chatRoomId: chatRoomId,
      isDelivered: isDelivered,
      isSent: isSent,
    );
  }
}

class _MessagesWidget extends StatefulWidget {
  final String message;
  final bool sendByMe;
  final Timestamp time;
  final dynamic imageurl;
  final bool isRead;
  final String messageID;
  final String chatRoomId;
  final bool isDelivered;
  final bool isSent;

  const _MessagesWidget({
    Key? key,
    required this.message,
    required this.sendByMe,
    required this.time,
    required this.imageurl,
    required this.isRead,
    required this.messageID,
    required this.chatRoomId,
    required this.isDelivered,
    required this.isSent,
  }) : super(key: key);

  @override
  _MessagesWidgetState createState() => _MessagesWidgetState();
}

class _MessagesWidgetState extends State<_MessagesWidget> {
  late bool _isRead;
  late Stream<DocumentSnapshot> readStatusStream;

  @override
  void initState() {
    super.initState();
    _isRead = widget.isRead;
    readStatusStream = DatabaseMethods()
        .getMessageReadStatusStream(widget.chatRoomId, widget.messageID);
  }

  @override
  Widget build(BuildContext context) {
    DateTime dateTime = widget.time.toDate();
    String formattedTime = DateFormat('h:mm a').format(dateTime);

    return StreamBuilder<DocumentSnapshot>(
      stream: readStatusStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container();
        } else if (snapshot.hasError) {
          return Container();
        } else if (!snapshot.hasData || !snapshot.data!.exists) {
          return Container();
        } else {
          // Check if the message has been read
          bool isReadInDatabase = snapshot.data!['read'] ?? false;

          return VisibilityDetector(
            key: Key(widget.messageID),
            onVisibilityChanged: (visibilityInfo) {
              // Only mark the message as read if:
              // - The message is not sent by the current user
              // - It hasn't been marked as read yet
              // - At least 50% of the message is visible
              if (!widget.sendByMe &&
                  !_isRead &&
                  visibilityInfo.visibleFraction > 0.5) {
                DatabaseMethods().updateMessageReadStatus(
                    widget.chatRoomId, widget.messageID);
                setState(() {
                  _isRead = true;
                });
              }
            },
            child: Padding(
              padding:
                  const EdgeInsets.only(top: pDefaultPadding * 0.9, left: 5),
              child: Row(
                mainAxisAlignment: widget.sendByMe
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                children: [
                  if (!widget.sendByMe) ...[
                    SizedBox(
                      height: 35,
                      width: 35,
                      child: Image.network(widget.imageurl),
                    ),
                  ],
                  const SizedBox(width: pDefaultPadding / 2),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8,
                    ),
                    child: IntrinsicWidth(
                      child: widget.sendByMe
                          ? Container(
                              margin: const EdgeInsets.only(top: 0, right: 5),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: pDefaultPadding * 0.5,
                                  vertical: 3),
                              decoration: const BoxDecoration(
                                color: Colors.black12,
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(0),
                                  topLeft: Radius.circular(10),
                                  topRight: Radius.circular(10),
                                  bottomRight: Radius.circular(10),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      widget.message,
                                      style: GoogleFonts.poppins(
                                          color: Colors.black, fontSize: 13),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(0, 10, 5, 0),
                                    child: Row(
                                      children: [
                                        Text(
                                          formattedTime,
                                          style: GoogleFonts.poppins(
                                            color: Colors.black45,
                                            fontSize: 10,
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        _isRead || isReadInDatabase
                                            ? const Icon(
                                                Icons.check_circle,
                                                color: Colors.blue,
                                                size: 15,
                                              )
                                            : const Icon(
                                                Icons.check_circle,
                                                color: Colors.grey,
                                                size: 15,
                                              ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: pDefaultPadding * 0.5,
                                  vertical: 5),
                              decoration: BoxDecoration(
                                color: widget.sendByMe
                                    ? Colors.black26
                                    : pSecondaryColor,
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(10),
                                  topLeft: Radius.circular(0),
                                  topRight: Radius.circular(10),
                                  bottomRight: Radius.circular(10),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      widget.message,
                                      style: GoogleFonts.poppins(
                                          color: Colors.black, fontSize: 13),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    formattedTime,
                                    style: GoogleFonts.poppins(
                                      color: Colors.black45,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}
