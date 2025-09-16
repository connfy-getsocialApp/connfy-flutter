import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  // final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundImage: NetworkImage(user!.photoURL!),
            ),
          ),
          Text(user.displayName!),
          Text(user.email!),
          const SizedBox(
            height: 20,
          ),
          GestureDetector(
            onTap: () {
              final provider =
                  //    Provider.of<GoogleSignInProvider>(context, listen: false);
                  //  provider.logout();
                  Navigator.pop(context);
            },
            child: Container(
              alignment: Alignment.center,
              height: 50,
              width: 100,
              color: Colors.grey,
              child: const Text(
                "LogOut",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
