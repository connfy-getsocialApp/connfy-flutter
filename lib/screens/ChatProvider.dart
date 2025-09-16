import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChatProvider extends ChangeNotifier {

  bool isAnswerLoading = false;

  List<Map<String, dynamic>> messages = [];



  void scrollToBottom(ScrollController scrollController) {
    if (scrollController.hasClients) {
      for (int i = 0; i < 12; i++) {
        Future.delayed(Duration(milliseconds: i * 50), () {
          scrollController.jumpTo(scrollController.position.maxScrollExtent);
        });
      }
    }
  }
}

