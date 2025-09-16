import 'package:chatapp/AppColorCodes.dart';
import 'package:chatapp/screens/socialmatch.dart';
import 'package:chatview/chatview.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../helper/constants.dart';
import '../model/theme.dart';
import '../services/database.dart';
import 'chatlistnew.dart';
import 'data.dart';

class Example extends StatelessWidget {
  final chatRoomId, uid, username, routeid, user_id, imageurl, senderid, token;

  Example(this.chatRoomId, this.uid, this.username, this.routeid, this.user_id, this.imageurl, this.senderid, this.token);


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Chat UI Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xffEE5366),
        colorScheme:
            ColorScheme.fromSwatch(accentColor: const Color(0xffEE5366)),
      ),
      home:  ChatScreen(chatRoomId, uid, username, routeid, user_id, imageurl, senderid, token),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final chatRoomId, uid, username, routeid, user_id, imageurl, senderid, token;

  ChatScreen(this.chatRoomId, this.uid, this.username, this.routeid, this.user_id, this.imageurl, this.senderid, this.token);


  @override
  State<ChatScreen> createState() => _ChatScreenState(this.chatRoomId, this.uid, this.username, this.routeid, this.user_id, this.imageurl, this.senderid, this.token);
}

class _ChatScreenState extends State<ChatScreen> {
  var chatRoomId, uid, username, routeid, user_id, imageurl, senderid, token;
  _ChatScreenState(this.chatRoomId, this.uid, this.username, this.routeid, this.user_id, this.imageurl, this.senderid, this.token);
  AppTheme theme = LightTheme();
  bool isDarkTheme = false;
  late  ChatController _chatController;
 // late ChatController _chatController = Get.put(ChatController(initialMessageList: [], scrollController: null, otherUsers: [], currentUser: null));
  late String chatId;
  late String currentUserId;

  void _showHideTypingIndicator() {
    _chatController.setTypingIndicator = !_chatController.showTypingIndicator;
  }

  void receiveMessage() async {
    _chatController.addMessage(
      Message(
        id: DateTime.now().toString(),
        message: 'I will schedule the meeting.',
        createdAt: DateTime.now(),
        sentBy: '2',
      ),
    );
    await Future.delayed(const Duration(milliseconds: 500));
    _chatController.addReplySuggestions([
      const SuggestionItemData(text: 'Thanks.'),
      const SuggestionItemData(text: 'Thank you very much.'),
      const SuggestionItemData(text: 'Great.')
    ]);
  }
  Stream<QuerySnapshot>? chats;
  @override
  void initState() {
    super.initState();


    print('chatRoomId $chatRoomId');

    DatabaseMethods().getChats(widget.chatRoomId).then((val) {
      setState(() {
        chats = val;
      });

      // Use a delayed scroll to ensure the UI is fully built before scrolling

    });



    // Listener for scrolling

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body:SafeArea(
        child:
        StreamBuilder(
          stream: chats,
          builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasData) {
              List<Message> messages = snapshot.data!.docs.map((doc) {
                var data = doc.data() as Map<String, dynamic>;
                return Message(

                  messageType: MessageType.text, createdAt: DateTime.now(), message: data['message'], sentBy: data["sendBy"],
                );
              }).toList();


              _chatController =
                  ChatController(
                    initialMessageList: messages,
                    scrollController: ScrollController(),
                    currentUser: ChatUser(
                      id: senderid,
                      name: '',
                      profilePhoto: imageurl,
                    ),
                    otherUsers: [
                      ChatUser(
                        id: uid,
                        name: '',
                        profilePhoto: imageurl,
                      ),

                    ],
                  );
              return
                ChatView(
                  chatController: _chatController,

                  onSendTap: _onSendTap,
                  featureActiveConfig: const FeatureActiveConfig(
                    lastSeenAgoBuilderVisibility: true,
                    receiptsBuilderVisibility: true,


                    enableScrollToBottomButton: true,
                  ),
                  scrollToBottomButtonConfig: ScrollToBottomButtonConfig(
                    backgroundColor: theme.textFieldBackgroundColor,
                    border: Border.all(
                      color: isDarkTheme ? Colors.transparent : Colors.grey,
                    ),
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: theme.themeIconColor,
                      weight: 10,
                      size: 30,
                    ),
                  ),
                  chatViewState: ChatViewState.hasMessages,
                  chatViewStateConfig: ChatViewStateConfiguration(
                    loadingWidgetConfig: ChatViewStateWidgetConfiguration(
                      loadingIndicatorColor: theme.outgoingChatBubbleColor,
                    ),
                    onReloadButtonTap: () {},
                  ),
                  typeIndicatorConfig: TypeIndicatorConfiguration(
                    flashingCircleBrightColor: theme.flashingCircleBrightColor,
                    flashingCircleDarkColor: theme.flashingCircleDarkColor,
                  ),
                  appBar: ChatViewAppBar(
                    elevation: theme.elevation,
                    backGroundColor: theme.appBarColor,
                    profilePicture:imageurl,
                    backArrowColor: theme.backArrowColor,
                    onBackPress: (){
                      if (routeid == '1') {
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => ChatListnew("1")));
                      } else {
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => SocilamatchList("2")));
                      }
                    },
                    chatTitle: "Chat view",
                    chatTitleTextStyle: TextStyle(
                      color: theme.appBarTitleTextStyle,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 0.25,
                    ),
                    userStatus: "online",
                    userStatusTextStyle: const TextStyle(color: Colors.grey),

                  ),

                  sendMessageConfig: SendMessageConfiguration(
                    imagePickerIconsConfig: ImagePickerIconsConfiguration(
                      cameraIconColor: theme.cameraIconColor,
                      galleryIconColor: theme.galleryIconColor,
                    ),
                    replyMessageColor: theme.replyMessageColor,
                    defaultSendButtonColor: theme.sendButtonColor,
                    replyDialogColor: theme.replyDialogColor,
                    replyTitleColor: theme.replyTitleColor,
                    textFieldBackgroundColor: theme.textFieldBackgroundColor,
                    closeIconColor: theme.closeIconColor,
                    textFieldConfig: TextFieldConfiguration(
                      onMessageTyping: (status) {
                        /// Do with status
                        // debugPrint(status.toString());
                      },
                      compositionThresholdTime: const Duration(seconds: 1),
                      textStyle: TextStyle(color: theme.textFieldTextColor),
                    ),
                    micIconColor: theme.replyMicIconColor,
                    voiceRecordingConfiguration: VoiceRecordingConfiguration(
                      backgroundColor: theme.waveformBackgroundColor,
                      recorderIconColor: theme.recordIconColor,
                      waveStyle: WaveStyle(
                        showMiddleLine: false,
                        waveColor: theme.waveColor ?? Colors.white,
                        extendWaveform: true,
                      ),
                    ),
                  ),
                replyMessageBuilder: (context, state) {
                return Container(
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Colors.brown,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(14),
                    ),
                  ),
                  margin: const EdgeInsets.only(
                    bottom: 17,
                    right: 0.4,
                    left: 0.4,
                  ),
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 30),
                  child: Container(

                    ),);
                  },
                  chatBubbleConfig: ChatBubbleConfiguration(
                    outgoingChatBubbleConfig: ChatBubble(
                      linkPreviewConfig: LinkPreviewConfiguration(
                        backgroundColor: theme.linkPreviewOutgoingChatColor,
                        bodyStyle: theme.outgoingChatLinkBodyStyle,
                        titleStyle: theme.outgoingChatLinkTitleStyle,

                      ),
                      textStyle: const TextStyle(
                        color: Colors.black, // Set the desired text color for the current user's messages here
                      ),
                      receiptsWidgetConfig:
                      const ReceiptsWidgetConfig(showReceiptsIn: ShowReceiptsIn.all,
                      ),
                      color:  Colors.black12,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(0),
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                    ),
                    inComingChatBubbleConfig: ChatBubble(
                     color: Colors.blue.shade100,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(10),
                        topLeft: Radius.circular(0),
                        topRight: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ), // C
                      linkPreviewConfig: LinkPreviewConfiguration(
                        linkStyle: TextStyle(
                          color: theme.inComingChatBubbleTextColor,
                          decoration: TextDecoration.underline,
                        ),
                        backgroundColor: theme.linkPreviewIncomingChatColor,
                        bodyStyle: theme.incomingChatLinkBodyStyle,
                        titleStyle: theme.incomingChatLinkTitleStyle,
                      ),
                      textStyle: TextStyle(color: theme.inComingChatBubbleTextColor),
                      onMessageRead: (message) {
                        /// send your message reciepts to the other client
                        // debugPrint('Message Read');
                      },
                      senderNameTextStyle:
                      TextStyle(color: theme.inComingChatBubbleTextColor),
                     // color: theme.inComingChatBubbleColor,
                    ),
                  ),
                  replyPopupConfig: ReplyPopupConfiguration(
                    backgroundColor: theme.replyPopupColor,
                    buttonTextStyle: TextStyle(color: theme.replyPopupButtonColor),
                    topBorderColor: theme.replyPopupTopBorderColor,
                  ),
                  reactionPopupConfig: ReactionPopupConfiguration(
                    shadow: BoxShadow(
                      color: isDarkTheme ? Colors.black54 : Colors.grey.shade400,
                      blurRadius: 20,
                    ),
                    backgroundColor: theme.reactionPopupColor,
                  ),
                  messageConfig: MessageConfiguration(
                    messageReactionConfig: MessageReactionConfiguration(
                      backgroundColor: theme.messageReactionBackGroundColor,
                      borderColor: theme.messageReactionBackGroundColor,
                      reactedUserCountTextStyle:
                      TextStyle(color: theme.inComingChatBubbleTextColor),
                      reactionCountTextStyle:
                      TextStyle(color: theme.inComingChatBubbleTextColor),
                      reactionsBottomSheetConfig: ReactionsBottomSheetConfiguration(
                        backgroundColor: pSecondaryColor,
                        reactedUserTextStyle: TextStyle(
                          color: theme.inComingChatBubbleTextColor,
                        ),
                        reactionWidgetDecoration: BoxDecoration(
                          color: theme.inComingChatBubbleColor,
                          boxShadow: [
                            BoxShadow(
                              color: isDarkTheme ? Colors.black12 : Colors.grey.shade200,
                              offset: const Offset(0, 20),
                              blurRadius: 40,
                            )
                          ],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    imageMessageConfig: ImageMessageConfiguration(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                      shareIconConfig: ShareIconConfiguration(
                        defaultIconBackgroundColor: theme.shareIconBackgroundColor,
                        defaultIconColor: theme.shareIconColor,
                      ),
                    ),
                  ),
                  profileCircleConfig: const ProfileCircleConfiguration(
                    profileImageUrl: Data.profileImage,
                  ),
                  repliedMessageConfig: RepliedMessageConfiguration(
                    backgroundColor: theme.repliedMessageColor,
                    verticalBarColor: theme.verticalBarColor,
                    repliedMsgAutoScrollConfig: RepliedMsgAutoScrollConfig(
                      enableHighlightRepliedMsg: true,
                      highlightColor: Colors.pinkAccent.shade100,
                      highlightScale: 1.1,
                    ),
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.25,
                    ),
                    replyTitleTextStyle: TextStyle(color: theme.repliedTitleTextColor),
                  ),
                  swipeToReplyConfig: SwipeToReplyConfiguration(
                    replyIconColor: theme.swipeToReplyIconColor,
                  ),
                  replySuggestionsConfig: ReplySuggestionsConfig(
                    itemConfig: SuggestionItemConfig(
                      decoration: BoxDecoration(
                        color: theme.textFieldBackgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.outgoingChatBubbleColor ?? Colors.white,
                        ),
                      ),
                      textStyle: TextStyle(
                        color: isDarkTheme ? Colors.white : Colors.black,
                      ),
                    ),
                    onTap: (item) =>
                        _onSendTap(item.text, const ReplyMessage(), MessageType.text),
                  ),
                );
            } else {
              return Container();
            }
          },
        ),
      )

    );
  }

  void _onSendTap(
    String message,
    ReplyMessage replyMessage,
    MessageType messageType,
  ) {
    _chatController.addMessage(
      Message(
        id: DateTime.now().toString(),
        createdAt: DateTime.now(),
        message: message,
        sentBy: _chatController.currentUser.id,
        replyMessage: replyMessage,
        messageType: messageType,
      ),
    );
    Future.delayed(const Duration(milliseconds: 300), () {
      _chatController.initialMessageList.last.setStatus =
          MessageStatus.undelivered;
    });
    Future.delayed(const Duration(seconds: 1), () {
      _chatController.initialMessageList.last.setStatus = MessageStatus.read;
    });
  }

  void _onThemeIconTap() {
    setState(() {
      if (isDarkTheme) {
        theme = LightTheme();
        isDarkTheme = false;
      } else {
        theme = DarkTheme();
        isDarkTheme = true;
      }
    });
  }
}
