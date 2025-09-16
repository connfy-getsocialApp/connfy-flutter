class loginphone {
  String? id;
  int? userTypeNo;
  String? userType;
  String? name;
  String? mail;
  String? phone;
  String? otp;
  int? status;
  String? message;

  loginphone({this.id, this.userTypeNo, this.userType, this.name, this.mail, this.phone, this.otp, this.status, this.message});

  loginphone.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userTypeNo = json['user_type_no'];
    userType = json['user_type'];
    name = json['name'];
    mail = json['mail'];
    phone = json['phone'];
    otp = json['otp'];
    status = json['status'];
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['user_type_no'] = this.userTypeNo;
    data['user_type'] = this.userType;
    data['name'] = this.name;
    data['mail'] = this.mail;
    data['phone'] = this.phone;
    data['otp'] = this.otp;
    data['status'] = this.status;
    data['message'] = this.message;
    return data;
  }
}
