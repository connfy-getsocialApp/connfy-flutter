import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfilePageForUser extends StatelessWidget {
  final String chatRoomId;
  final String uid;
  final String username;
  final String routeid;
  final String user_id;
  final String imageurl;
  final String token;
  final bool isCurrentUser;
  final VoidCallback? onBlock;
  final VoidCallback? onReport;

  const ProfilePageForUser(
      this.chatRoomId,
      this.uid,
      this.username,
      this.routeid,
      this.user_id,
      this.imageurl,
      this.token, {
        this.isCurrentUser = true,
        this.onBlock,
        this.onReport,
        Key? key,
      }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xff03A0E3),


        title: Text('User Profile' ,style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white),),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(imageurl),
            ),
            const SizedBox(height: 16),
            Text(username, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            // Add other profile info here

            if (!isCurrentUser) ...[
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40), // Reduced width by adding horizontal padding
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onReport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[800], // Changed from primary to backgroundColor
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child:  Text("REPORT",style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onBlock,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700], // Changed from primary to backgroundColor
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child:  Text("BLOCK",style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),),
                      ),
                    ),

                  ],
                ),
              ),

            ],
          ],
        ),
      ),
    );
  }
}