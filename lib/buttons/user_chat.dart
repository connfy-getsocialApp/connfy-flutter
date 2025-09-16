import 'package:chatapp/buttons/user_chat_container.dart';
import 'package:flutter/material.dart';


import 'package:provider/provider.dart';

import '../screens/ChatProvider.dart';

class UserChat extends StatefulWidget {
  final ScrollController scrollController;
  UserChat({super.key, required this.scrollController});

  @override
  State<UserChat> createState() => _UserChatState();
}

class _UserChatState extends State<UserChat> {
  bool isFetching = false;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Consumer<ChatProvider>(builder: (_, chatProvider, __) {
        // Ensure that messages are not duplicated in the ListView
        List messages =
            chatProvider.messages.toSet().toList(); // Remove duplicates

        return ListView.builder(
          controller: widget.scrollController,
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: messages.length, // Use the unique list
          itemBuilder: (context, index) {
            final message = messages[index];
           String question = "message[questionTitle]";
           String answer =' message[answerTitle]' ?? '';


              return UserChatContainer(
                question: question,
                answer: answer.isNotEmpty ? answer : 'typing...',
              );

          },
        );
      }),
    );
  }
}
