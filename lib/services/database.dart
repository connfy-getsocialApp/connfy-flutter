import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseMethods {
  Future<void> addUserInfo(userData) async {
    FirebaseFirestore.instance.collection("users").add(userData).catchError((e) {
      print(e.toString());
    });
  }

  Future<void> updateMessageReadStatus(String chatRoomId, String messageId) async {
    try {
      await FirebaseFirestore.instance.collection("chatRoom").doc(chatRoomId).collection("chats").doc(messageId).update({'read': true});
    } catch (e) {
      print('Error updating read status: ${e.toString()}');
    }
  }

  getUserInfo(String email) async {
    return FirebaseFirestore.instance.collection("users").where("userEmail", isEqualTo: email).get().catchError((e) {
      print(e.toString());
    });
  }

  searchByName(String searchField) {
    return FirebaseFirestore.instance.collection("users").get();
  }

  Future<bool>? addChatRoom(chatRoom, chatRoomId) {
    FirebaseFirestore.instance.collection("chatRoom").doc(chatRoomId).set(chatRoom).catchError((e) {
      print(e);
    });
  }

  Future<void> deleteMessage(String chatRoomId, String messageId) async {
    try {
      await FirebaseFirestore.instance.collection("chatRoom").doc(chatRoomId).collection("chats").doc(messageId).delete();
      print("Message deleted successfully");
    } catch (e) {
      print("Failed to delete message: $e");
    }
  }

  Stream<DocumentSnapshot> getMessageReadStatusStream(String chatRoomId, String messageId) {
    return FirebaseFirestore.instance.collection("chatRoom").doc(chatRoomId).collection("chats").doc(messageId).snapshots();
  }

  Future<void> deleteAllMessages(String chatRoomId) async {
    try {
      CollectionReference chatsRef = FirebaseFirestore.instance.collection("chatRoom").doc(chatRoomId).collection("chats");

      QuerySnapshot snapshot = await chatsRef.get();

      WriteBatch batch = FirebaseFirestore.instance.batch();

      for (QueryDocumentSnapshot doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      print("All messages deleted successfully for chatRoomId: $chatRoomId");
    } catch (e) {
      print("Failed to delete all messages for chatRoomId: $chatRoomId, error: $e");
    }
  }

  Future<void> deleteAllMessagesFromMultipleChatRooms(List<String> chatRoomIds) async {
    for (String chatRoomId in chatRoomIds) {
      await deleteAllMessages(chatRoomId);
    }
  }

  Future<bool?> getMessageReadStatus(String chatRoomId, String messageId) async {
    try {
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance.collection("chatRoom").doc(chatRoomId).collection("chats").doc(messageId).get();

      if (documentSnapshot.exists) {
        return documentSnapshot['read'];
      } else {
        print("Message not found");
        return null;
      }
    } catch (e) {
      print("Failed to get message read status: $e");
      return null;
    }
  }

  getChats(String chatRoomId) async {
    return FirebaseFirestore.instance.collection("chatRoom").doc(chatRoomId).collection("chats").orderBy('time').snapshots();
  }

  Future<void>? addMessage(String chatRoomId, chatMessageData) {
    FirebaseFirestore.instance.collection("chatRoom").doc(chatRoomId).collection("chats").add(chatMessageData).catchError((e) {
      print(e.toString());
    });
  }

  getUserChats(String itIsMyName) async {
    return await FirebaseFirestore.instance.collection("chatRoom").where('users', arrayContains: itIsMyName).snapshots();
  }

  getUserChatsnew(String itIsMyName) async {
    return await FirebaseFirestore.instance.collection("chatRoom").where('chats', arrayContains: itIsMyName).snapshots();
  }
}
