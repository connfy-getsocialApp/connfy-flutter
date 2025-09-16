import 'dart:async';
import 'dart:convert';

import 'package:chatapp/constant.dart';
import 'package:chatapp/helper/constants.dart';
import 'package:chatapp/screens/profile.dart';
import 'package:chatapp/screens/socialmatch.dart';
import 'package:chatapp/services/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:localstorage/localstorage.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../AppColorCodes.dart';
import '../controller/Constant.dart';
import '../main.dart';
import 'NetworkService.dart';
import 'chatlistnew.dart';

class Chatold extends StatefulWidget {
  final chatRoomId, uid, username, routeid, user_id, imageurl, senderid, token;

  const Chatold(this.chatRoomId, this.uid, this.username, this.routeid,
      this.user_id, this.imageurl, this.senderid, this.token,
      {super.key});

  @override
  _ChatState createState() => _ChatState(
      chatRoomId, uid, username, routeid, user_id, imageurl, senderid, token);
}

class _ChatState extends State<Chatold> {
  var chatRoomId, uid, username, routeid, user_id, imageurl, senderid, token;
  _ChatState(this.chatRoomId, this.uid, this.username, this.routeid,
      this.user_id, this.imageurl, this.senderid, this.token);
  Stream<QuerySnapshot>? chats;
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
  TextEditingController messageEditingController = TextEditingController();
  String? UserId = "";
  //final LocalStorage storage = new LocalStorage('wifi');
  String config_wifi = "emty";
  Widget chatMessages() {
    // print(chatRoomId + ">>>>" + uid + '>>>>' + Constants.myName);
    return Container(
      height: double.infinity,
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
      child: StreamBuilder(
        stream: chats,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasData) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // Scroll to the bottom of the list
              if (snapshot.data!.docs.isNotEmpty) {
                final controller = PrimaryScrollController.of(context);
                // Ensure that controller.position is not null before accessing maxScrollExtent
                controller.animateTo(
                  controller.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            });

            /*   WidgetsBinding.instance?.addPostFrameCallback((_) {
              // Scroll to the bottom of the list
              if (snapshot.data!.docs.isNotEmpty) {
                final controller = PrimaryScrollController.of(context);
                controller?.animateTo(controller.position!.maxScrollExtent!, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
              }
            });
*/
            /*  return ListView.builder(
              itemCount: snapshot.data?.docs.length,
              itemBuilder: (context, index) {
                String? messageId = snapshot.data?.docs[index].id.toString();

                return Messages(
                  message: snapshot.data?.docs[index]["message"],
                  sendByMe: Constants.myName == snapshot.data?.docs[index]["sendBy"],
                  time: snapshot.data?.docs[index]["time"],
                  imageurl: imageurl,
                  isRead: snapshot.data?.docs[index]["read"],
                  chatRoomId: chatRoomId,
                  messageID: messageId!,
                );
              },
            );*/

            return ListView.builder(
              itemCount: snapshot.data?.docs.length,
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

  void addMessage() {
    if (messageEditingController.text.isNotEmpty) {
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

      // Update read status for previous messages in the chat room (assuming this is necessary)
      getGlobalTime(messageEditingController.text);

      setState(() {
        messageEditingController.text = "";
      });
    }
  }

  /*addMessage() {
    if (messageEditingController.text.isNotEmpty) {
      Map<String, dynamic> chatMessageMap = {
        "sendBy": Constants.myName,
        "message": messageEditingController.text,
        'time': DateTime.now(),
        'read': false, // Assuming initial read status is false
        'chatRoomId': chatRoomId,
      };

      // Add message to the database
      DatabaseMethods().addMessage(chatRoomId, chatMessageMap);

      // Update read status for previous messages in the chat room (assuming this is necessary)
      addmessage_server(messageEditingController.text);
      setState(() {
        messageEditingController.text = "";
      });
    }
  }*/

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

      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Handling a foreground message: ${message.messageId}');
        print('Notification Message: ${message.data}');

        final data = message.data;
        final title = data['title'] ?? 'Notification Title';
        final body = data['body'] ?? 'Notification Body';
        final imageUrl = data['image'] ?? '';
        if (imageUrl.isNotEmpty) {
          //  showNotificationDialog(title, body, imageUrl);
        }
        //   showNotificationDialog(title, body, imageUrl);
        // NotificationService().showNotification(title: title, body: body);
      });
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

  @override
  void initState() {
    retrive();
    registerForNotifications();
    addchannel_server();
    // _initConnectivity();
    //  _startTimer();

    DatabaseMethods().getChats(widget.chatRoomId).then((val) {
      setState(() {
        chats = val;
      });
    });
    super.initState();
  }

  Future retrive() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //Return String
    UserId = prefs.getString('UserId');
    // await storage.ready;
    String? name = localStorage.getItem('wifiname');
    String? ssid = localStorage.getItem('SSID');
    config_wifi = localStorage.getItem('wifiname')!;
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

  AppBar buildAppBar() {
    bool isConnectedToConfiguredWifi = Provider.of<NetworkService>(context)
            .wifiName
            .toString()
            .replaceAll('"', '') ==
        config_wifi;
    return AppBar(
      backgroundColor: const Color(0xff03A0E3),
      titleSpacing: 0,
      title: Row(
        children: [
          GestureDetector(
            child: Stack(
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
            onTap: () {},
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
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios,
          color: Colors.white,
        ),
        onPressed: () {
          //  Navigator.of(context).push(MaterialPageRoute(builder: (context) => ChatList(uid)));
          if (routeid == '1') {
            Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => ChatListnew("1")));
          } else {
            Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => SocilamatchList("2")));
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
                          username, routeid, user_id, imageurl, token)));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: buildAppBar(),
      body: Consumer<NetworkService>(
        builder: (context, networkService, child) {
          if (networkService.networkStatus == NetworkStatus.Online) {
            if (networkService.toString().replaceAll('"', '') == config_wifi) {
              wifi_sttus = 1;
            } else {
              wifi_sttus = 0;
            }
            return (networkService.wifiName).toString().replaceAll('"', '') ==
                    config_wifi
                ? SafeArea(
                    child: Column(
                      children: [
                        Expanded(
                          child: chatMessages(),
                        ),

                        Container(
                          alignment: Alignment.bottomCenter,
                          width: MediaQuery.of(context).size.width,
                          //height: 100,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          child: Row(
                            children: [
                              Expanded(
                                  child: TextField(
                                controller: messageEditingController,
                                cursorColor: Colors.blue,
                                maxLines:
                                    null, // Allows the TextField to expand vertically
                                keyboardType: TextInputType
                                    .multiline, // Allows the user to enter multiple lines
                                textInputAction: TextInputAction.newline,
                                decoration: kTextFieldDecoration.copyWith(
                                    hintText: 'Message...'),
                              )),
                              IconButton(
                                  onPressed: () {
                                    //initiateSearch();
                                    addMessage();
                                  },
                                  icon: const Icon(Icons.send,
                                      color: Color(0xff03A0E3)))
                            ],
                          ),
                        ),
                        //chatMessages()
                      ],
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        /* Container(
                              padding: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 5.0),
                              child: Text(
                                'Connected Wifi: $_connectionStatus',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w300,
                                ),
                              )),*/
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
                          "Please #getsocial! You are not connected. ",
                          style: GoogleFonts.poppins(
                            color: Colors.black45,
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
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
                          "Please check your Wi-Fi connection.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w400,
                            fontSize: 15,
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
                  );
          } else {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  /* Container(
                              padding: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 5.0),
                              child: Text(
                                'Connected Wifi: $_connectionStatus',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w300,
                                ),
                              )),*/
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
                    "Please #getsocial! You are not connected. ",
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
                    "Please check your Wi-Fi connection.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w400,
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
            );
          }
        },
      ),

      //  bottomNavigationBar: chatTextField1(context),
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

    print('globaltime $globalTime');
    print('formattedDateffff $formattedDate');
    sendnotifcation(message, formattedDate);
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

  Future<void> sendnotifcation(String message, String time) async {
    var headers = {
      'Authorization':
          'key=AAAAGLDkAjg:APA91bFsO9qoCm-dYTaDicJ9cHDsg8ur4HY-dqx2tRzSJrh1X7Lxg0c0pZrBEfSSnRoOHdAMUMuRe59YnWkKXFMA3BOTw5QLAqhXzUe_MQ6Bsuu71RvxGkJ5l23obQBayyOyLRJzXYk1',
      'Content-Type': 'application/json'
    };
    var request =
        http.Request('POST', Uri.parse('https://fcm.googleapis.com/fcm/send'));
    request.body = json.encode({
      "to": token,
      "data": {
        "body": message,
        "title": "New Message",
        "image": "",
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
    required this.chatRoomId,
    required this.messageID,
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
      chatRoomId: chatRoomId,
      messageID: messageID,
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

  const _MessagesWidget({
    Key? key,
    required this.message,
    required this.sendByMe,
    required this.time,
    required this.imageurl,
    required this.isRead,
    required this.chatRoomId,
    required this.messageID,
  }) : super(key: key);

  @override
  _MessagesWidgetState createState() => _MessagesWidgetState();
}

class _MessagesWidgetState extends State<_MessagesWidget> {
  late bool _isRead;

  @override
  void initState() {
    super.initState();
    _isRead = widget.isRead;
    if (!widget.sendByMe && !_isRead) {
      _updateReadStatus();
    }
  }

  void _updateReadStatus() {
    DatabaseMethods()
        .updateMessageReadStatus(widget.chatRoomId, widget.messageID);
    setState(() {
      _isRead = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    DateTime dateTime = widget.time.toDate();
    String formattedTime = DateFormat('h:mm a').format(dateTime);

    return Padding(
      padding: const EdgeInsets.only(top: pDefaultPadding * 0.9, left: 5),
      child: Row(
        mainAxisAlignment:
            widget.sendByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!widget.sendByMe) ...[
            SizedBox(
              height: 35,
              width: 35,
              child: Image.network(widget.imageurl),
            )
          ],
          const SizedBox(
            width: pDefaultPadding / 2,
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width *
                  0.8, // 80% of screen width
            ),
            child: IntrinsicWidth(
              child: widget.sendByMe
                  ? Container(
                      margin: const EdgeInsets.only(top: 0, right: 5),
                      padding: const EdgeInsets.symmetric(
                          horizontal: pDefaultPadding * 0.5, vertical: 3),
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
                            padding: const EdgeInsets.fromLTRB(0, 10, 5, 0),
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
                                _isRead
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
                          )
                        ],
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: pDefaultPadding * 0.5, vertical: 5),
                      decoration: BoxDecoration(
                        color:
                            widget.sendByMe ? Colors.black26 : pSecondaryColor,
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
          )

          /* ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8, // 60% of screen width
            ),
            child: widget.sendByMe
                ? Container(
                    margin: const EdgeInsets.only(top: 0, right: 5),
                    padding: const EdgeInsets.symmetric(horizontal: pDefaultPadding * 0.5, vertical: 3),
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
                            style: GoogleFonts.poppins(color: Colors.black, fontSize: 13),
                            //  overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 10, 5, 0),
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
                              _isRead
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
                        )
                      ],
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: pDefaultPadding * 0.5, vertical: 5),
                    decoration: BoxDecoration(
                      color: widget.sendByMe ? Colors.black26 : pSecondaryColor,
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
                            style: GoogleFonts.poppins(color: Colors.black, fontSize: 13),
                            // overflow: TextOverflow.ellipsis,
                            // maxLines: 1,
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
          ),*/
        ],
      ),
    );

    /* Padding(
      padding: const EdgeInsets.only(top: pDefaultPadding * 0.9, left: 5),
      child: Row(
        mainAxisAlignment: widget.sendByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!widget.sendByMe) ...[
            Container(
              height: 35,
              width: 35,
              child: Image.network(widget.imageurl),
            )
          ],
          const SizedBox(
            width: pDefaultPadding / 2,
          ),
          widget.sendByMe
              ? Container(
                  // maxWidth: MediaQuery.of(context).size.width * 0.6,
                  margin: const EdgeInsets.only(top: 0, right: 5),
                  padding: const EdgeInsets.symmetric(horizontal: pDefaultPadding * 0.5, vertical: 3),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(0),
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        widget.message,
                        style: GoogleFonts.poppins(color: Colors.black, fontSize: 13),
                      ),
                      const SizedBox(width: 5),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 10, 5, 0),
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
                            _isRead
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
                      )
                    ],
                  ),
                )
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: pDefaultPadding * 0.5, vertical: 5),
                  decoration: BoxDecoration(
                    color: widget.sendByMe ? Colors.black26 : pSecondaryColor,
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
                          style: GoogleFonts.poppins(color: Colors.black, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
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
        ],
      ),
    );*/
  }
}

/*class Messages extends StatefulWidget {
  final String message;
  final bool sendByMe;
  final Timestamp time;
  final dynamic imageurl;
  final bool isRead;
  final String messageID;
  final String chatRoomId;

  Messages({
    required this.message,
    required this.sendByMe,
    required this.time,
    required this.imageurl,
    required this.isRead,
    required this.chatRoomId,
    required this.messageID,
  });

  @override
  _MessagesState createState() => _MessagesState(
        this.message,
        this.sendByMe,
        this.time,
        this.imageurl,
        this.isRead,
        this.chatRoomId,
        this.messageID,
      );
}

class _MessagesState extends State<Messages> {
  final String message;
  final bool sendByMe;
  final Timestamp time;
  final dynamic imageurl;
  final bool isRead;
  final String messageID;
  final String chatRoomId;
  _MessagesState(
    this.message,
    this.sendByMe,
    this.time,
    this.imageurl,
    this.isRead,
    this.chatRoomId,
    this.messageID,
  );
  @override
  void initState() {
    super.initState();
    updateReadStatus();
  }

  void updateReadStatus() {
    if (!sendByMe && !isRead) {
      DatabaseMethods().updateMessageReadStatus(chatRoomId, messageID);
    }
  }

  @override
  Widget build(BuildContext context) {
    print(isRead);
    DateTime dateTime = time.toDate();
    String formattedTime = DateFormat('h:mm a').format(dateTime);

    return Padding(
      padding: const EdgeInsets.only(top: pDefaultPadding * 0.9, left: 5),
      child: Row(
        mainAxisAlignment: sendByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!sendByMe) ...[
            Container(
              height: 35,
              width: 35,
              child: Image.network(imageurl),
            )
          ],
          const SizedBox(
            width: pDefaultPadding / 2,
          ),
          sendByMe
              ? Container(
                  margin: const EdgeInsets.only(top: 0, right: 5),
                  padding: const EdgeInsets.symmetric(horizontal: pDefaultPadding * 0.5, vertical: 3),
                  decoration: BoxDecoration(
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
                      Text(
                        message,
                        style: GoogleFonts.poppins(color: Colors.black, fontSize: 13),
                      //  maxLines: 1,
                      ),
                      */ /*  Container(
                        child: Text(
                          message,
                          style: GoogleFonts.poppins(color: Colors.black, fontSize: 13),
                        ),
                        width: MediaQuery.of(context).size.width / 2,
                      ),*/ /*
                      SizedBox(width: 5),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 10, 5, 0),
                        child: Row(
                          children: [
                            Text(
                              formattedTime,
                              style: GoogleFonts.poppins(
                                color: Colors.black45,
                                fontSize: 10,
                              ),
                            ),
                            SizedBox(width: 5),
                            // Display read/unread status icon
                            isRead == true
                                ? Icon(
                                    Icons.check_circle,
                                    color: Colors.blue,
                                    size: 15,
                                  )
                                : Icon(
                                    Icons.check_circle,
                                    color: Colors.grey,
                                    size: 15,
                                  ),
                          ],
                        ),
                      )
                    ],
                  ),
                )
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: pDefaultPadding * 0.5, vertical: 5),
                  decoration: BoxDecoration(
                    color: sendByMe ? Colors.black26 : pSecondaryColor,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(10),
                      topLeft: Radius.circular(0),
                      topRight: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                  ),
                  child: Row(
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              message,
                              style: GoogleFonts.poppins(color: Colors.black, fontSize: 13),
                              overflow: TextOverflow.ellipsis, // Or any other overflow property
                              maxLines: 1, // Or any other value for maximum lines
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: 5),
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
        ],
      ),
    );
  }
}*/

// for showing single message details
