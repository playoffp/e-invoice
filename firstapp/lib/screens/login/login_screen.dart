import 'package:firstapp/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:firstapp/screens/login/login_model.dart';
import 'package:http/http.dart' as http;
import '../../../constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:firstapp/database/invoice_database.dart';

const users = const {
  'dribbble@gmail.com': '12345',
  'hunter@gmail.com': 'hunter',
};
main() {
  WidgetsFlutterBinding.ensureInitialized();
}

class LoginScreen extends StatelessWidget {
  Duration get loginTime => Duration(milliseconds: 2550);

  Future<void> setDevice(barcode, password) async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    pref.setString('barcode', barcode);
    pref.setString('password', password);
  }

  Future<String?> _authUser(LoginData data) {
    debugPrint('Name: ${data.name}, Password: ${data.password}');
    print(data.password.runtimeType);
    return Future.delayed(loginTime).then((_) {
      setDevice(data.name, data.password);
      _createLogin(data.name, data.password);
      return null;
    });
  }

  Future<String?> _signupUser(SignupData data) {
    debugPrint('Signup Name: ${data.name}, Password: ${data.password}');
    return Future.delayed(loginTime).then((_) {
      return null;
    });
  }

  Future<String?> _recoverPassword(String name) {
    debugPrint('Name: $name');
    return Future.delayed(loginTime).then((_) {
      if (!users.containsKey(name)) {
        return 'User not exists';
      }
      return null;
    });
  }

  Future<LoginModel?> _createLogin(String barcode, String password) async {
    int timestamp = DateTime.now().millisecondsSinceEpoch + 20;
    int exp = timestamp + 200;
    var now = new DateTime.now();
    var formatter = new DateFormat('yyyy/MM/dd');
    List<Detail> tmp = [];
    List<Header> header = [];
    String responseString;
    String sdate;
    String edate;
    var last;
    var start;
    var response;

    for (int j = 5; j >= 0; j--) {
      start = new DateTime(now.year, now.month - j, 01);
      last = new DateTime(start.year, start.month + 1, 0);
      sdate = formatter.format(start);
      edate = formatter.format(last);
      response = await http.post(
          Uri.https("api.einvoice.nat.gov.tw", "/PB2CAPIVAN/invServ/InvServ"),
          body: {
            "version": "0.5",
            "cardType": "3J0002",
            "cardNo": barcode,
            "expTimeStamp": exp.toString(),
            "action": "carrierInvChk",
            "timeStamp": timestamp.toString(),
            "startDate": sdate,
            "endDate": edate,
            "onlyWinningInv": 'N',
            "uuid": '1000',
            "appID": 'EINV0202204156709',
            "cardEncrypt": password,
          });
      responseString = response.body;
      tmp = loginModelFromJson(responseString).details;
      header = [];

      for (int i = 0; i < tmp.length; i++) {
        header.add(Header(
            date: tmp[i].invDate.year.toString() +
                '/' +
                tmp[i].invDate.month.toString() +
                '/' +
                tmp[i].invDate.date.toString(),
            time: tmp[i].invoiceTime,
            seller: tmp[i].sellerName,
            address: tmp[i].sellerAddress,
            inv_num: tmp[i].invNum,
            barcode: tmp[i].cardNo,
            amount: tmp[i].amount));
        await HeaderHelper.instance.add(header[i]);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FlutterLogin(
      title: 'Cloud-rie',
      theme: LoginTheme(
        accentColor: kSecondaryColor,
        primaryColor: kPrimaryColor,
        cardTheme: CardTheme(
          color: Colors.grey.shade100,
          elevation: 5,
          margin: EdgeInsets.only(top: 15),
          shape: ContinuousRectangleBorder(
              borderRadius: BorderRadius.circular(70)),
        ),
      ),
      userType: LoginUserType.phone,
      userValidator: (str) {},
      logo: AssetImage('assets/images/image_1.png'),
      onLogin: _authUser,
      onSignup: _signupUser,
      onSubmitAnimationCompleted: () {
        Navigator.pop(context);
      },
      onRecoverPassword: _recoverPassword,
    );
  }
}