import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Function to get the stream for a specific message's read status
  Stream<DocumentSnapshot> getMessageReadStatusStream(String chatRoomId, String messageId) {
    return _firestore.collection('chats').doc(chatRoomId).collection('messages').doc(messageId).snapshots();
  }
}
