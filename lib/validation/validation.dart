class ValidationData {
  static String? firstNameValidate(String firstname) {
    String patttern = r'^[a-z A-Z,.\-]+$';
    RegExp regExp = new RegExp(patttern);
    if (firstname.length == 0) {
      return 'Name is required';
    } /*else if (!regExp.hasMatch(firstname)) {
      return 'Please enter valid first name';
    }*/
    return null;
  }

  static String? ageValidate(String? firstname) {
    int age = 1;
    print(firstname);

    if (firstname!.length == 0) {
      return 'DOB is required';
    } /*else if ((int.parse(firstname!))<age) {
      return 'Age should be 18+';
    }*/
    return null;
  }

  static String? custNameValidate(String? firstname) {
    String patttern = '[a-zA-Z]';
    RegExp regExp = new RegExp(patttern);
    if (firstname!.length == 0) {
      return 'Name is required';
    } else if (!regExp.hasMatch(firstname)) {
      return 'Please enter valid  name';
    }
    return null;
  }

  static String? dobvalidate(String? firstname) {
    String patttern = r'^[a-z A-Z,.\-]+$';
    RegExp regExp = new RegExp(patttern);
    if (firstname!.length == 0) {
      return 'DOB is required';
    } /*else if (!regExp.hasMatch(firstname)) {
      return 'Please enter valid first name';
    }*/
    return null;
  }

  static String? projNameValidate(String firstname) {
    String patttern = r'^[a-z A-Z,.\-]+$';
    RegExp regExp = new RegExp(patttern);
    if (firstname.length == 0) {
      return 'Please enter project name';
    } /*else if (!regExp.hasMatch(firstname)) {
      return 'Please enter valid first name';
    }*/
    return null;
  }

  static String? titleNameValidate(String lastname) {
    String patttern = r'^[a-z A-Z,.\-]+$';
    RegExp regExp = new RegExp(patttern);
    if (lastname.length == 0) {
      return 'Location is required';
    } else if (!regExp.hasMatch(lastname)) {
      return 'Please enter valid Location';
    }
    return null;
  }

  static String? passwordValidate(String passValue) {
    if (passValue.length == 0) {
      return 'Please enter password';
    } else if (passValue.length < 8) {
      return 'password must be 8 characters or more';
    }
    return null;
  }

  static String? emailValidate(String? value) {
    String pattern = r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp regExp = new RegExp(pattern);
    if (value!.length == 0) {
      return "Email is required";
    } else if (!regExp.hasMatch(value)) {
      return "Invalid Email";
    } else {
      return null;
    }
  }

  static String? mobileValidate(String? value) {
    String patttern = r'(^(?:[+0]9)?[0-9]{8,12}$)';
    RegExp regExp = new RegExp(patttern);
    if (value!.length == 0) {
      return 'Mobile no required';
    } else if (!regExp.hasMatch(value)) {
      return 'Mobile number must be valid';
    }
    return null;
  }
}
