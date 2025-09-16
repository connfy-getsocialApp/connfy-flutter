import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SignInPage extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleSignInAccount = await googleSignIn.signIn();
      if (googleSignInAccount != null) {
        final GoogleSignInAuthentication googleSignInAuthentication = await googleSignInAccount.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );
        final UserCredential authResult = await _auth.signInWithCredential(credential);
        final User? user = authResult.user;

        assert(!user!.isAnonymous);
        assert(await user!.getIdToken() != null);

        final User currentUser = _auth.currentUser!;
        assert(user?.uid == currentUser.uid);

        return user;
      }
      return null;
    } catch (error) {
      print(error);
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign In'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            signInWithGoogle().then((user) {
              if (user != null) {
                // Navigate to your desired screen after successful sign-in
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomeScreen(user: user),
                  ),
                );
              }
            }).catchError((error) {
              // Handle sign-in error
              print("Error signing in with Google: $error");
            });
          },
          child: Text('Sign in with Google'),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final User user;

  const HomeScreen({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Welcome, ${user.displayName}!',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // Sign out user
                await FirebaseAuth.instance.signOut();
                // Navigate back to sign-in screen
                Navigator.pop(context);
              },
              child: Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}
