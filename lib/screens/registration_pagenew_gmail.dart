import 'dart:convert';
import 'dart:math';

import 'package:chatapp/screens/registration_pagenew.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart' as perm;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controller/Constant.dart';
import '../controller/loader.dart';
import '../helper/constants.dart';
import '../helper/shared_preference.dart';
import '../services/auth.dart';
import '../services/database.dart';
import '../widgets/button.dart';
import 'email_verification_page.dart';

class RegistrationPagenew_gmail extends StatefulWidget {
  final User user;
  const RegistrationPagenew_gmail({Key? key, required this.user})
      : super(key: key);

  @override
  State<RegistrationPagenew_gmail> createState() =>
      _RegistrationPageState(user);
}

class _RegistrationPageState extends State<RegistrationPagenew_gmail> {
  final User user;
  _RegistrationPageState(this.user);
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FocusNode emailcontrollerFocusNode = FocusNode();
  bool isLoading = false;
  DatabaseMethods databaseMethods = DatabaseMethods();
  AuthService authService = AuthService();
  HelperFunctions helperFunctions = HelperFunctions();
  GlobalKey<FormState> MyKey = GlobalKey();
  TextEditingController emailcontroller = TextEditingController();
  TextEditingController firstnamecontroller = TextEditingController();
  TextEditingController gendercontroller = TextEditingController();
  TextEditingController dobcontroller = TextEditingController();
  TextEditingController passwordcontroller = TextEditingController();
  bool loading = false;
  final bool _isLoading1 = false;
  bool checkbob_flg = false;
  bool gender_flg = false;
  bool dobflag = false;
  bool emailflag = false;
  bool nameflag = false;
  bool nameflag1 = false;
  bool rememberMe = false;
  bool rememberMevis = false;
  DateTime selectedDate = DateTime.now();
  String horoscopeimageurl = "";
  List<String> supplier_typelist = ["Male", 'Female', 'Non Binary'];

  String genderstr = "Gender";

  final Random _random =
      Random(); // Create a Random object for generating random numbers
  int _randomNumber = 0;
  void _onRememberMeChanged(bool? newValue) => setState(() {
        rememberMe = newValue!;

        print(rememberMe);

        if (rememberMe) {
          rememberMevis = false;
          // TODO: Here goes your functionality that remembers the user.
        } else {
          rememberMevis = true;
          // TODO: Forget the userIcon
        }
      });
  String? _validateDOB(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your Date of Birth';
    }
    // Add additional validation logic if needed
    return null;
  }

  static bool? emailValidate(String? value) {
    String pattern =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp regExp = RegExp(pattern);
    if (value!.isEmpty) {
      return false;
    } else if (!regExp.hasMatch(value)) {
      return false;
    } else {
      return true;
    }
  }

  @override
  void initState() {
    super.initState();
    retrive();
  }

  Future<void> _checkAndRequestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.locationAlways,
      Permission.locationWhenInUse,
    ].request();

    bool alwaysGranted =
        statuses[Permission.locationAlways] == PermissionStatus.granted;
    final whenInUseGranted =
        statuses[Permission.locationWhenInUse] == PermissionStatus.granted;

    if (!alwaysGranted) {
      _showPermissionDialog();
    } else {
      SignMeUP();
    }

    print('Location Always Granted: $alwaysGranted');
    print('Location When In Use Granted: $whenInUseGranted');
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                "Please grant location permission to enable all features of the app."),
            SizedBox(height: 10),
            Text("To enable background location access:",
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text("1. Click on 'Settings' below."),
            Text("2. Go to 'Permissions'."),
            Text("3. Enable 'Location' and set it to 'Allow all the time'."),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close the dialog
              await perm.Permission.locationAlways
                  .request(); // Request location permission again
              await perm.openAppSettings(); // Open the app settings
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    ).then((_) {
      // Check permissions again after the dialog is closed
      _checkAndRequestPermissions();
    });
  }

  static bool? nameValidate(String? value) {
    if (value!.isEmpty) {
      return false;
    } else {
      return true;
    }
  }

  static bool? nameValidate1(String? value) {
    String pattern = r'^[a-zA-Z0-9\s]*[a-zA-Z0-9][a-zA-Z0-9\s]*$';
    RegExp regex = RegExp(pattern);
    if (!regex.hasMatch(value!)) {
      return false;
    } else {
      return true;
    }
  }

  Future retrive() async {
    print(user.email!);
    emailcontroller.text = user.email!;
    firstnamecontroller.text = user.displayName!;
  }

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.signIn();
      if (googleSignInAccount != null) {
        final GoogleSignInAuthentication googleSignInAuthentication =
            await googleSignInAccount.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );
        final UserCredential authResult =
            await _auth.signInWithCredential(credential);
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

  Future<void> _selectDate(BuildContext context) async {
    DateTime now = DateTime.now();
    int currentYear = now.year;
    int month = now.month;
    int date = now.day;
    int yearMinus100 = currentYear - 100;

    final ThemeData theme = Theme.of(context);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(currentYear, month, date),
      initialDatePickerMode: DatePickerMode.day,
      firstDate: DateTime(yearMinus100),
      lastDate: DateTime(currentYear, month, date),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: Colors.blue,

              // Change this to your desired color
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        dobcontroller.text = DateFormat('dd/MM/yyyy').format(selectedDate);
      });
      emailcontrollerFocusNode.requestFocus();
    }
  }

  Future<void> loadharoscope(int genderstr, String dob) async {
    var headers = {'Content-Type': 'application/json'};
    var request = http.Request('POST',
        Uri.parse('https://admin.connfy.at/api/check_dob'));
    request.body = json.encode({"dob": dob, "gender": genderstr});
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();
    setState(() {
      isLoading = false;
    });
    if (response.statusCode == 200) {
      setState(() {
        isLoading = false;
      });
      var responseBody = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseBody);
      String imgurl = jsonResponse['horoscope_image_url'];
      print('Deleted user ID: $imgurl');
      setState(() {
        horoscopeimageurl = imgurl;
      });
    } else {
      print(response.reasonPhrase);
    }
  }

  Widget privacyPolicyLinkAndTermsOfService() {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.fromLTRB(0, 5, 5, 0),
      child: Center(
          child: Text.rich(TextSpan(
              text: 'I agreed your Terms of Service and Conditions. ',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.black26),
              children: <TextSpan>[
            TextSpan(
                text: '',
                style: GoogleFonts.poppins(
                  fontSize: 14, color: Colors.black26,
                  //  decoration: TextDecoration.underline,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    // code to open / launch terms of service link here
                  }),
          ]))),
    );
  }

  SignMeUP() async {
    {
      _randomNumber = 1000 + _random.nextInt(9000);
      String modemail = firstnamecontroller.text.trim();

      String result = modemail.replaceAll(" ", "") + _randomNumber.toString();

      await authService
          .signUpWithEmailAndPassword(
              "$result@gmail.com", firstnamecontroller.text + ("@123"))
          .then((val) {
        // print("${val.uid}");
        final time = DateTime.now().millisecondsSinceEpoch.toString();
        if (val != null) {
          int gender = 0;
          if (genderstr == 'Male') {
            gender = 1;
          } else if (genderstr == 'Female') {
            gender = 2;
          } else {
            gender = 3;
          }

          doRegistration(
            val.uid.toString(),
            firstnamecontroller.text,
            dobcontroller.text,
            gender,
            emailcontroller.text.toString(),
            "",
            val.uid.toString(),
          );
        }
      });
    }
  }


// Method to show error messages
  void showError(String errorMessage) {
    // Display the error message in your UI, for example using a SnackBar
    showSnakBar(errorMessage);
  }

  doRegistration(String mobileDeviceId, String nickName, String dob, int gender,
      String email, String ssid, String chatId) async {
    setState(() {
      isLoading = true;
    });
    var headers = {'Content-Type': 'application/json'};
    Map<String, dynamic> data = {
      "status": 0,
      "mobile_device_id": mobileDeviceId,
      "ssid": ssid,
      "nick_name": nickName,
      "dob": dob,
      "gender": gender,
      "email": email,
      "chat_id": chatId,
      "social_media_login": 0
    };

    try {
      var request = http.Request('POST',
          Uri.parse('https://admin.connfy.at/api/create_user'));
      request.body = json.encode(data);
      print(json.encode(data));

      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        setState(() {
          isLoading = false;
        });
        String jsonData = await response.stream.bytesToString();
        Map<String, dynamic> responseData = jsonDecode(jsonData);
        print(responseData);

        int status = responseData['status'];
        dynamic userId = responseData['user_id'].toString();
        String message = responseData['message'];
        print(message);
        Constants.myName = chatId;
        addItemsToLocalStorage(userId);
        if (message == 'Nick name already exists') {
          showSnakBar(message);
        } else {
          final time = DateTime.now().millisecondsSinceEpoch.toString();
          Map<String, dynamic> userDataMap = {
            "userName": firstnamecontroller.text,
            "userEmail": emailcontroller.text,
            'isOnline': true,
            'read': '',
            'sent': time,
            'lastActive': DateTime.now(),
            'uid': chatId,
          };
          databaseMethods.addUserInfo(userDataMap);
          HelperFunctions.saveUserLoggedInSharedPreference(true);
          HelperFunctions.saveUserEmailSharedPreference(emailcontroller.text);
          HelperFunctions.saveUserNameSharedPreference(chatId);
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      ThankYouPage(emailcontroller.text, userId)));

          //  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ChatListnew(firstnamecontroller.text)));
        }
      } else {
        setState(() {
          isLoading = false;
        });

        print(response.reasonPhrase);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error creating account 2: $e");

      print('$e');
    }
  }

  void parseResponseData(Map<String, dynamic> userData) {
    // Extract data from responseData and handle it as needed
    // For example:
    String userId = userData['user_id'];
    String status = userData['status'];

    //  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ChatList("")));
    // Access more fields as needed

    print('User ID: $userId');
    print('Status: $status');
    // Print or handle more fields as needed
  }

  Future<void> addItemsToLocalStorage(String UserId) async {
    print(UserId);
    SharedPreferences storage = await SharedPreferences.getInstance();

    storage.setString('UserId', UserId);

    /* final info = json.encode({'name': 'Darush', 'family': 'Roshanzami'});
    storage.setItem('info', info);*/
  }

  void ValidateFunction() {
    if (firstnamecontroller.text.isEmpty) {
      showSnakBar("First name is empty");
    } else if (dobcontroller.text.isEmpty) {
      showSnakBar("Last name is empty");
    } else if (gendercontroller.text.isEmpty) {
      showSnakBar("Email is Empty");
      return;
    } else if (!isValidEmail(emailcontroller.text)) {
      showSnakBar("Please Enter a valid email");
    } else {
      //  Register();
    }
  }

  validateData() {
    print(
        "${nameflag}dfhh${dobflag}dfhh${emailflag}dfhh${gender_flg}dfhh$rememberMe");
    if (nameflag == false &&
        dobflag == false &&
        emailflag == false &&
        gender_flg == false &&
        rememberMe == true) {
      _checkAndRequestPermissions();

      // showAlertDialog(context, "Confirm Password","Passwords are not same");
    } else {
      // validation error
    }
  }

  Future Register() async {
    try {
      setState(() {
        loading = true;
      });
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: firstnamecontroller.text.trim() + emailcontroller.text,
        password: passwordcontroller.text,
      );
      showSnakBar("Account Created Successfully");
      emailcontroller.clear();
      passwordcontroller.clear();
      setState(() {
        loading = false;
      });
    } catch (e) {
      print("Error creating account 3: $e");
      showSnakBar("Failed to create account: $e");
      print('$e');
    }
  }

  // Function to validate email using a regular expression
  bool isValidEmail(String email) {
    final emailRegExp = RegExp(r'^[\w-]+(\.[\w-]+)*@[\w-]+(\.[\w-]+)+$');
    return emailRegExp.hasMatch(email);
  }

  // snackbar function
  void showSnakBar(String message) {
    final snakbar = SnackBar(
      content: Text(message),
      backgroundColor: Colors.redAccent,
      duration: const Duration(seconds: 4),
    );
    SnakBarKey.currentState?.showSnackBar(snakbar);
  }

  final SnakBarKey = GlobalKey<ScaffoldMessengerState>();

  String _onDropDownChanged_stype(String val) {
    String prefix;
    if (val.isNotEmpty) {
      prefix = val;
    } else {
      prefix = "Gender";
    }

    return prefix;
  }

  Future<void> signOut(BuildContext context) async {
    try {
      await googleSignIn.signOut();
      await _auth.signOut();

      // Navigate to RegistrationPagenew and replace all previous routes
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const RegistrationPagenew(),
        ),
      );

      // You can also perform any additional sign-out related tasks here,
      // such as clearing user data from your app's state.
    } catch (error) {
      print("Error signing out: $error");
      // Handle sign-out errors, if any.
    }
  }

  Future<bool> _onWillPop() async {
    return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Are you sure to Logout from Gmail?'),
            // content: const Text('Do you want to delete your data'),
            actions: <Widget>[
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(false), //<-- SEE HERE
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () async {
                  signOut(context);
                }, // <-- SEE HERE
                child: const Text('Yes'),
              )
            ],
          ),
        )) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        loadUi(),
        isLoading ? Loader(loadingTxt: 'Please wait..') : Container()
      ],
    );
  }

  @override
  Widget loadUi() {
    double deviseWidth = MediaQuery.of(context).size.width;
    return WillPopScope(
        onWillPop: () async {
          // Call your custom logic here if needed
          _onWillPop();
          // Always return true to allow the back action
          return true;
        },
        // Your other WillPopScope properties here

        child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.blueGrey,
            ),
            home: SafeArea(
              child: ScaffoldMessenger(
                key: SnakBarKey,
                child: Scaffold(
                  backgroundColor: const Color(0xffffffff),
                  body: Container(
                    child: SingleChildScrollView(
                        child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          height: 25,
                        ),
                        Container(
                          decoration:
                              const BoxDecoration(color: Colors.transparent),
                          // alignment: Alignment.center,
                          height: 100,
                          child: Container(
                            width: 200.0,
                            height: 130.0,
                            decoration: const BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage('assets/images/appicon.png'),
                                fit: BoxFit.fill,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 75,
                        ),
                        Card(
                          color: const Color(0xFFf0f0f0),
                          // width: double.infinity,

                          //  padding: EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                          //  margin: EdgeInsets.symmetric(vertical: 165, horizontal: 20),

                          child: Container(
                            margin: const EdgeInsets.only(
                                top: 0.0, left: 0, right: 0),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  color: const Color(0xFFe5e5e5),
                                  child: SizedBox(
                                      width: MediaQuery.of(context).size.width,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          const SizedBox(
                                            height: 60,
                                          ),
                                          const SizedBox(
                                            height: 30,
                                          ),

                                          // wellcome message

                                          //Textfiled

                                          Form(
                                              key: MyKey,
                                              child: Column(
                                                children: [
                                                  Container(
                                                    decoration:
                                                        kBoxDecorationStyle,
                                                    height: 55.0,
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 5),
                                                    margin: const EdgeInsets
                                                        .fromLTRB(8, 0, 8, 5),
                                                    child: TextFormField(
                                                      keyboardType:
                                                          TextInputType.text,
                                                      cursorColor: Colors.blue,
                                                      enableInteractiveSelection:
                                                          false,
                                                      //  validator: ValidationData.custNameValidate!,
                                                      style:
                                                          GoogleFonts.poppins(
                                                              fontSize: 15.0,
                                                              color:
                                                                  Colors.black),
                                                      controller:
                                                          firstnamecontroller,
                                                      decoration:
                                                          InputDecoration(
                                                        border:
                                                            InputBorder.none,
                                                        contentPadding:
                                                            const EdgeInsets
                                                                .only(
                                                                top: 10.0,
                                                                left: 15),
                                                        hintText: ' Nick Name',
                                                        hintStyle:
                                                            kHintTextStyle,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Visibility(
                                                      visible: nameflag,
                                                      child: Container(

                                                          // height: 55.0,

                                                          margin:
                                                              const EdgeInsets
                                                                  .fromLTRB(
                                                                  10, 0, 3, 5),
                                                          child: Row(
                                                            // mainAxisAlignment: MainAxisAlignment.center,
                                                            children: <Widget>[
                                                              Text(
                                                                ' Name is required ',
                                                                style: GoogleFonts.poppins(
                                                                    fontSize:
                                                                        12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w300,
                                                                    color: Colors
                                                                        .red),
                                                              ),
                                                            ],
                                                          ))),
                                                  Visibility(
                                                      visible: nameflag1,
                                                      child: Container(

                                                          // height: 55.0,

                                                          margin:
                                                              const EdgeInsets
                                                                  .fromLTRB(
                                                                  10, 0, 3, 5),
                                                          child: Row(
                                                            // mainAxisAlignment: MainAxisAlignment.center,
                                                            children: <Widget>[
                                                              Text(
                                                                ' Name can only contain letters, numbers, and underscores',
                                                                style: GoogleFonts.poppins(
                                                                    fontSize:
                                                                        12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w300,
                                                                    color: Colors
                                                                        .red),
                                                              ),
                                                            ],
                                                          ))),
                                                  const SizedBox(height: 5),
                                                  InkWell(
                                                      onTap: () {
                                                        _selectDate(context);
                                                      },
                                                      child: Container(
                                                          decoration:
                                                              kBoxDecorationStyle,
                                                          height: 55.0,
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      5),
                                                          margin:
                                                              const EdgeInsets
                                                                  .fromLTRB(
                                                                  8, 0, 8, 5),
                                                          child: Row(
                                                            children: <Widget>[
                                                              Expanded(
                                                                child:
                                                                    TextField(
                                                                  cursorColor:
                                                                      Colors
                                                                          .blue,
                                                                  //   controller: _textController,
                                                                  style: GoogleFonts.poppins(
                                                                      fontSize:
                                                                          15.0,
                                                                      color: Colors
                                                                          .black),
                                                                  //  validator: ValidationData.custNameValidate!,
                                                                  controller:
                                                                      dobcontroller,
                                                                  decoration:
                                                                      InputDecoration(
                                                                    border:
                                                                        InputBorder
                                                                            .none,
                                                                    enabled:
                                                                        false,
                                                                    contentPadding: const EdgeInsets
                                                                        .only(
                                                                        top:
                                                                            10.0,
                                                                        left:
                                                                            15),
                                                                    hintText:
                                                                        ' Date of Birth',
                                                                    hintStyle:
                                                                        kHintTextStyle,
                                                                    // border: border,
                                                                    //errorBorder: border,
                                                                    // disabledBorder: border,
                                                                    // focusedBorder: border,
                                                                    //  focusedErrorBorder: border,
                                                                    suffixIcon:
                                                                        IconButton(
                                                                      onPressed:
                                                                          () {},
                                                                      icon: SvgPicture
                                                                          .asset(
                                                                        'assets/icons/calendar-fill.svg',
                                                                        colorFilter: const ColorFilter
                                                                            .mode(
                                                                            Colors.blue,
                                                                            BlendMode.srcIn),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              Container()
                                                            ],
                                                          ))),
                                                  const SizedBox(height: 3),
                                                  Visibility(
                                                      visible: dobflag,
                                                      child: Container(

                                                          // height: 55.0,

                                                          margin:
                                                              const EdgeInsets
                                                                  .fromLTRB(
                                                                  10, 0, 3, 5),
                                                          child: Row(
                                                            // mainAxisAlignment: MainAxisAlignment.center,
                                                            children: <Widget>[
                                                              Text(
                                                                ' Date of Birth is required',
                                                                style: GoogleFonts.poppins(
                                                                    fontSize:
                                                                        12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w300,
                                                                    color: Colors
                                                                        .red),
                                                              ),
                                                            ],
                                                          ))),
                                                  const SizedBox(
                                                    height: 5,
                                                  ),
                                                  Container(
                                                      decoration:
                                                          kBoxDecorationStyle,
                                                      height: 55.0,
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 5),
                                                      margin: const EdgeInsets
                                                          .fromLTRB(8, 0, 8, 5),
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .fromLTRB(
                                                                8, 10, 8, 5),
                                                        child: DropdownButton<
                                                                String>(
                                                            isExpanded: true,
                                                            isDense: true,
                                                            underline:
                                                                const SizedBox(),
                                                            hint: Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .fromLTRB(
                                                                        8,
                                                                        5,
                                                                        8,
                                                                        5),
                                                                child: genderstr ==
                                                                        "Gender"
                                                                    ? Text(
                                                                        _onDropDownChanged_stype(
                                                                            genderstr),
                                                                        style:
                                                                            kHintTextStyle,
                                                                      )
                                                                    : Text(
                                                                        _onDropDownChanged_stype(
                                                                            genderstr),
                                                                        style: GoogleFonts
                                                                            .poppins(
                                                                          color:
                                                                              Colors.black87,
                                                                          // fontWeight: FontWeight.w400,
                                                                        ),
                                                                      )),
                                                            icon: const Icon(
                                                              Icons
                                                                  .arrow_drop_down,
                                                              color: Colors
                                                                  .black45,
                                                            ),
                                                            iconSize: 30,
                                                            //  value: newversionid,
                                                            onChanged: (value) {
                                                              setState(() {
                                                                if (value!
                                                                    .isNotEmpty) {
                                                                  genderstr =
                                                                      value;
                                                                  int gender =
                                                                      -1;
                                                                  if (genderstr ==
                                                                      'Male') {
                                                                    gender = 1;
                                                                  } else if (genderstr ==
                                                                      'Female') {
                                                                    gender = 2;
                                                                  } else {
                                                                    gender = 3;
                                                                  }

                                                                  loadharoscope(
                                                                      gender,
                                                                      dobcontroller
                                                                          .text);
                                                                }
                                                              });
                                                            },

                                                            //
                                                            items:
                                                                supplier_typelist
                                                                    .map(
                                                                        (value) {
                                                              return DropdownMenuItem<
                                                                  String>(
                                                                value: value
                                                                    .toString(),
                                                                child: Text(
                                                                  value.isNotEmpty
                                                                      ? value
                                                                          .toString()
                                                                      : "",
                                                                  style: const TextStyle(
                                                                      fontSize:
                                                                          12),
                                                                ),
                                                              );
                                                            }).toList()),
                                                      )),
                                                  Visibility(
                                                      visible: gender_flg,
                                                      child: Container(

                                                          // height: 55.0,

                                                          margin:
                                                              const EdgeInsets
                                                                  .fromLTRB(
                                                                  10, 0, 3, 5),
                                                          child: Row(
                                                            // mainAxisAlignment: MainAxisAlignment.center,
                                                            children: <Widget>[
                                                              Text(
                                                                'Select Gender',
                                                                style: GoogleFonts.poppins(
                                                                    fontSize:
                                                                        12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w300,
                                                                    color: Colors
                                                                        .red),
                                                              ),
                                                            ],
                                                          ))),
                                                  const SizedBox(
                                                    height: 3,
                                                  ),
                                                  const SizedBox(
                                                    height: 5,
                                                  ),
                                                  Container(
                                                    decoration:
                                                        kBoxDecorationStyle,
                                                    height: 55.0,
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 5),
                                                    margin: const EdgeInsets
                                                        .fromLTRB(8, 0, 8, 5),
                                                    child: TextFormField(
                                                      keyboardType:
                                                          TextInputType.text,
                                                      cursorColor: Colors.blue,
                                                      enableInteractiveSelection:
                                                          false,
                                                      //  validator: ValidationData.custNameValidate!,
                                                      style:
                                                          GoogleFonts.poppins(
                                                              fontSize: 15.0,
                                                              color:
                                                                  Colors.black),
                                                      controller:
                                                          emailcontroller,
                                                      focusNode:
                                                          emailcontrollerFocusNode,
                                                      enabled: false,
                                                      decoration:
                                                          InputDecoration(
                                                        border:
                                                            InputBorder.none,
                                                        contentPadding:
                                                            const EdgeInsets
                                                                .only(
                                                                top: 10.0,
                                                                left: 15),
                                                        hintText:
                                                            ' Email Address',
                                                        hintStyle:
                                                            kHintTextStyle,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Visibility(
                                                      visible: emailflag,
                                                      child: Container(

                                                          // height: 55.0,

                                                          margin:
                                                              const EdgeInsets
                                                                  .fromLTRB(
                                                                  10, 0, 3, 5),
                                                          child: Row(
                                                            // mainAxisAlignment: MainAxisAlignment.center,
                                                            children: <Widget>[
                                                              Text(
                                                                ' Valid Email id is required',
                                                                style: GoogleFonts.poppins(
                                                                    fontSize:
                                                                        12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w300,
                                                                    color: Colors
                                                                        .red),
                                                              ),
                                                            ],
                                                          ))),
                                                  const SizedBox(
                                                    height: 5,
                                                  ),
                                                  Container(

                                                      // height: 55.0,

                                                      margin: const EdgeInsets
                                                          .fromLTRB(8, 0, 8, 8),
                                                      child: Row(
                                                        // mainAxisAlignment: MainAxisAlignment.center,
                                                        children: <Widget>[
                                                          Container(
                                                              child: Checkbox(
                                                            value: rememberMe,
                                                            onChanged:
                                                                _onRememberMeChanged,
                                                            activeColor:
                                                                Colors.blue,
                                                          )),
                                                          Expanded(
                                                            child:
                                                                privacyPolicyLinkAndTermsOfService(),
                                                          )
                                                        ],
                                                      )),
                                                  const SizedBox(
                                                    height: 3,
                                                  ),
                                                  rememberMevis == true
                                                      ? Visibility(
                                                          visible: true,
                                                          child: Container(

                                                              // height: 55.0,

                                                              margin:
                                                                  const EdgeInsets
                                                                      .fromLTRB(
                                                                      10,
                                                                      0,
                                                                      3,
                                                                      5),
                                                              child: Row(
                                                                // mainAxisAlignment: MainAxisAlignment.center,
                                                                children: <Widget>[
                                                                  Text(
                                                                    'Please accept the terms and condtions.',
                                                                    style: GoogleFonts.poppins(
                                                                        fontSize:
                                                                            12,
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .w300,
                                                                        color: Colors
                                                                            .red),
                                                                  ),
                                                                ],
                                                              )))
                                                      : Container(),
                                                  const SizedBox(
                                                    height: 10,
                                                  ),
                                                  MyButoon(
                                                    loading: loading,
                                                    onPressed: () {
                                                      bool? res = emailValidate(
                                                          emailcontroller.text);
                                                      bool? res2 = nameValidate(
                                                          firstnamecontroller
                                                              .text);

                                                      if (res == true) {
                                                        setState(() {
                                                          emailflag = false;
                                                        });
                                                      } else {
                                                        setState(() {
                                                          emailflag = true;
                                                        });
                                                      }

                                                      if (res2 == true) {
                                                        setState(() {
                                                          nameflag = false;
                                                        });

                                                        /*  bool? res3 = nameValidate1(firstnamecontroller.text!);
                                                        print(res3);

                                                        if (res3 == true) {
                                                          setState(() {
                                                            nameflag1 = false;
                                                          });
                                                        } else {
                                                          setState(() {
                                                            nameflag1 = true;
                                                          });
                                                        }*/
                                                      } else {
                                                        setState(() {
                                                          nameflag = true;
                                                        });
                                                      }

                                                      print('Rest $res');
                                                      if (dobcontroller
                                                          .text.isEmpty) {
                                                        setState(() {
                                                          dobflag = true;
                                                        });
                                                      } else {
                                                        setState(() {
                                                          dobflag = false;
                                                        });
                                                      }

                                                      /* if (firstnamecontroller.text.isEmpty) {
                                                        setState(() {
                                                          nameflag = true;
                                                        });
                                                      } else {
                                                        setState(() {
                                                          nameflag = false;
                                                        });
                                                      }*/
                                                      if (genderstr ==
                                                          'Gender') {
                                                        setState(() {
                                                          gender_flg = true;
                                                        });
                                                      } else {
                                                        setState(() {
                                                          gender_flg = false;
                                                        });
                                                      }
                                                      if (rememberMe) {
                                                        setState(() {
                                                          rememberMevis = false;
                                                        });
                                                      } else {
                                                        print(
                                                            "$rememberMevis-----$rememberMe");
                                                        setState(() {
                                                          rememberMevis = true;
                                                        });
                                                      }

                                                      validateData();
                                                      //  Navigator.of(context).push(MaterialPageRoute(builder: (context) => ChatList("")));

                                                      // ValidateFunction();
                                                    },
                                                    title: 'Submit',
                                                  ),
                                                  const SizedBox(
                                                    height: 15,
                                                  ),
                                                ],
                                              )),

                                          // Register
                                        ],
                                      )),
                                ),

                                //Circle Avatar
                                horoscopeimageurl.isEmpty
                                    ? Positioned(
                                        width:
                                            MediaQuery.of(context).size.width,
                                        top: -75,
                                        child: Container(
                                          height: 120,
                                          width: 120,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                width: 1, color: Colors.blue),
                                            image: const DecorationImage(
                                              image: AssetImage(
                                                'assets/images/newlogo.gif',
                                              ),
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                          /*  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Image.asset('assets/images/newlogo.gif'),

                                  )*/
                                        ),
                                      )
                                    : Positioned(
                                        width:
                                            MediaQuery.of(context).size.width,
                                        top: -75,
                                        child: Container(
                                          height: 120,
                                          width: 120,
                                          decoration: BoxDecoration(
                                            //  shape: BoxShape.circle,

                                            image: DecorationImage(
                                              image: NetworkImage(
                                                  horoscopeimageurl),
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                          /*  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Image.asset('assets/images/newlogo.gif'),

                                  )*/
                                        ),
                                      ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                      ],
                    )),
                  ),
                ),
              ),
            )));
  }
}
