import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MockQueryDocumentSnapshot {
  final Map<String, dynamic> data;
  final String id;

  MockQueryDocumentSnapshot(this.data, {String? id})
      : id = id ?? 'mock_${DateTime.now().millisecondsSinceEpoch}';

  // Helper method to access data like a real DocumentSnapshot
  dynamic get(String field) => data[field];
}

class MockQuerySnapshot {
  final List<MockQueryDocumentSnapshot> docs;

  MockQuerySnapshot(this.docs);

  // Convert to a format that works with your existing code
  List<Map<String, dynamic>> toList() {
    return docs.map((doc) => doc.data).toList();
  }
}
class MockMessages extends StatelessWidget {
  final String message;
  final bool sendByMe;
  final Timestamp time;
  final String imageurl;
  final bool isRead;

  const MockMessages({
    Key? key,
    required this.message,
    required this.sendByMe,
    required this.time,
    required this.imageurl,
    required this.isRead,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String formattedTime = DateFormat('h:mm a').format(time.toDate());
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
      child: Row(
        mainAxisAlignment:
        sendByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!sendByMe)
            CircleAvatar(radius: 17, backgroundImage: NetworkImage(imageurl)),
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
            margin: EdgeInsets.only(left: sendByMe ? 30 : 8, right: sendByMe ? 8 : 30),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: sendByMe ? Colors.blue[50] : Colors.grey[200],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: sendByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(message, style: TextStyle(fontSize: 14)),
                SizedBox(height: 2),
                Text(formattedTime, style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          if (sendByMe)
            Icon(isRead ? Icons.done_all : Icons.done, size: 15, color: isRead ? Colors.blue : Colors.grey)
        ],
      ),
    );
  }
}