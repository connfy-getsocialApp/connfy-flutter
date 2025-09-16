import 'package:chatapp/screens/chatuiii.dart';
import 'package:chatapp/screens/registration_pagenew.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import 'chatlistnew.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    // Initialize separate Firebase app just for authentication
    await Firebase.initializeApp(
      name: 'connfy_getsocialApp',
      options: const FirebaseOptions(
        apiKey: "AIzaSyDaU-bzluZGUy24yyHczcIcuG5GU65HD6w",
        appId: "1:727175371211:android:dd0d680134949abbb7fe4e",
        messagingSenderId: "727175371211",
        projectId: "connfy-getsocialapp",
        iosBundleId: "com.slice.connfy", // match Xcode
        storageBucket: "connfy-getsocialapp.firebasestorage.app", // Add if using Storage

      
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      await FirebaseAuth.instanceFor(app: Firebase.app('connfy_getsocialApp'))
          .signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      context.read<ReviewModeProvider>().enableReviewMode();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChatListnew(
            "1", // authcode
            isReviewMode: true, // Enable mock data
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Login failed";
      if (e.code == 'user-not-found') {
        errorMessage = "No user found with this email";
      } else if (e.code == 'wrong-password') {
        errorMessage = "Incorrect password";
      } else if (e.code == 'invalid-email') {
        errorMessage = "Invalid email format";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 55),
                Container(
                  height: 100,
                  child: Center(
                    child: Image.asset('assets/images/appicon.png', width: 200),
                  ),
                ),
                const SizedBox(height: 75),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: _validatePassword,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text("Login"),
                  ),
                ),
                // const Padding(
                //   padding: EdgeInsets.only(top: 20),
                //   child: Text(
                //    "PREVIEW MODE – TEST CREDENTIALS ONLY\nSome features are disabled for App Store review purposes.",
                //     style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

