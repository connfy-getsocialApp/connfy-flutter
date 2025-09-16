// import 'package:chatapp/screens/chatbot/chatbot.dart';
// import 'package:chatapp/screens/search.dart';
// import 'package:chatapp/services/auth.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
//
// import '../helper/authenticate.dart';
// import '../helper/constants.dart';
// import '../helper/shared_preference.dart';
// import '../services/database.dart';
// import 'chats.dart';
//
// class ChatRoom extends StatefulWidget {
//   const ChatRoom({Key? key}) : super(key: key);
//
//   @override
//   _ChatRoomState createState() => _ChatRoomState();
// }
//
// class _ChatRoomState extends State<ChatRoom> {
//   Stream? chatRooms;
//   Widget chatRoomsList() {
//     return StreamBuilder(
//       stream: chatRooms,
//       builder: (context, AsyncSnapshot snapshot) {
//         return snapshot.hasData
//             ? ListView.builder(
//                 itemCount: snapshot.data!.docs.length,
//                 shrinkWrap: true,
//                 itemBuilder: (context, index) {
//                   print('lellll');
//                   print(snapshot.data!.docs.length);
//                   var doc = snapshot.data!.docs[index];
//                   var chatroomId = doc['chatroomId'].toString();
//                   var lastMessage = doc['message'];
//                   var lastMessageTime = doc['time'];
//                   var isRead = doc['read'];
//                   print('lastMessage::$lastMessage');
//                   return ChatRoomsTile(
//                     userName: chatroomId.replaceAll("_", "").replaceAll(Constants.myName, ""),
//                     chatRoomId: chatroomId,
//                     uid: "uid",
//                     lastMessage: lastMessage,
//                     lastMessageTime: lastMessageTime,
//                     isRead: isRead,
//                   );
//                 })
//             : Container(
//                 child: Text("lfkg;fg"),
//               );
//       },
//     );
//   }
//
//   @override
//   void initState() {
//     // TODO: implement initState
//     getUserInfogetChats();
//     super.initState();
//   }
//
//   getUserInfogetChats() async {
//     Constants.myName = (await HelperFunctions.getUserNameSharedPreference())!;
//     try {
//       DatabaseMethods().getUserChatsnew(Constants.myName).then((snapshots) {
//         setState(() {
//           chatRooms = snapshots;
//           print("we got the data + ${chatRooms} this is name  ${Constants.myName}");
//         });
//       });
//     } catch (e) {
//       print('error :$e');
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         title: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             Text(
//               "ChatRoom",
//               style: GoogleFonts.roboto(
//                 textStyle: const TextStyle(
//                   color: Color.fromARGB(255, 172, 235, 174),
//                   fontSize: 26,
//                   //fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           GestureDetector(
//             onTap: () {
//               AuthService().signOut();
//               Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Authenticate()));
//             },
//             child: Container(
//               padding: EdgeInsets.symmetric(horizontal: 16),
//               child: const Icon(
//                 Icons.exit_to_app,
//                 color: Colors.black,
//               ),
//             ),
//           )
//         ],
//       ),
//       body: Stack(children: [
//         Padding(
//           padding: const EdgeInsets.only(bottom: 80, right: 20),
//           child: GestureDetector(
//             onTap: () {
//               Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatScreen()));
//             },
//             child: Align(
//               alignment: Alignment.bottomRight,
//               child: Container(
//                 padding: const EdgeInsets.all(14),
//                 decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black),
//                 child: const Icon(
//                   Icons.android,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//           ),
//         ),
//         Container(
//           child: chatRoomsList(),
//         ),
//       ]),
//       floatingActionButton: FloatingActionButton(
//         backgroundColor: Colors.black,
//         child: const Icon(Icons.search),
//         onPressed: () {
//           Navigator.push(context, MaterialPageRoute(builder: (context) => const Search()));
//         },
//       ),
//     );
//   }
// }
//
// class ChatRoomsTile extends StatelessWidget {
//   final String userName;
//   final String chatRoomId;
//   final String uid;
//   final String? lastMessage;
//   final DateTime? lastMessageTime;
//   final bool? isRead;
//
//   ChatRoomsTile({
//     required this.userName,
//     required this.chatRoomId,
//     required this.uid,
//     this.lastMessage,
//     this.lastMessageTime,
//     this.isRead,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () {
//         Navigator.push(context, MaterialPageRoute(builder: (context) => Chat(chatRoomId, uid, userName, "", "", "", Constants.myName, "")));
//       },
//       child: Container(
//         margin: const EdgeInsets.all(8),
//         decoration: BoxDecoration(
//           color: const Color.fromARGB(255, 172, 235, 174),
//           borderRadius: BorderRadius.circular(24),
//         ),
//         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
//         child: Row(
//           children: [
//             Container(
//               height: 30,
//               width: 30,
//               decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10)),
//               child: const Center(
//                   child: Icon(
//                 Icons.account_circle_outlined,
//                 color: Colors.white,
//               )),
//             ),
//             const SizedBox(
//               width: 12,
//             ),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   userName.toUpperCase(),
//                   textAlign: TextAlign.start,
//                   style: const TextStyle(
//                     color: Colors.black,
//                     fontSize: 16,
//                   ),
//                 ),
//                 if (lastMessage != null && lastMessageTime != null && isRead != null)
//                   Text(
//                     lastMessage!,
//                     style: TextStyle(color: isRead! ? Colors.grey : Colors.black),
//                   ),
//               ],
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }
