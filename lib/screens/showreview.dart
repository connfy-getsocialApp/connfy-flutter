import 'package:chatapp/screens/chatlistnew.dart';
import 'package:chatapp/screens/socailevents.dart';
import 'package:chatapp/screens/socialmatch.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ReviewScreen extends StatefulWidget {
  final url, route;
  const ReviewScreen(this.url, this.route);
  @override
  State<ReviewScreen> createState() => _WebViewScreenState(this.url, this.route);
}

class _WebViewScreenState extends State<ReviewScreen> {
  var url, route;
  _WebViewScreenState(this.url, this.route);
  late WebViewController controller;
  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Color(0xff03A0E3),
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
          ),
          onPressed: () {
            if (route == 1) {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => ChatListnew("1")));
            } else if (route == 2) {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => SocilamatchList("1")));
            } else if (route == 3) {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => EventsList()));
            }
          },
        ),
        title: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Social Reviews',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: WebViewWidget(
        controller: controller,
      ),
    );
  }
}
