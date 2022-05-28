import 'package:flutter/material.dart';
import 'package:firstapp/constants.dart';
import 'package:firstapp/screens/home/home_screen.dart';
import 'package:firstapp/screens/profile/profile_screen.dart';
import 'package:firstapp/screens/scan/scan_screen.dart';
import 'package:firstapp/screens/analysis/analysis_screen.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      scaffoldBackgroundColor: kBackgroundColor,
      primarySwatch: Colors.blueGrey,
      primaryColor: kPrimaryColor,
      textTheme: const TextTheme(
        bodyText2: TextStyle(color: kTextColor),
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    ),
    home: const MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  GlobalKey<CurvedNavigationBarState> _NavKey = GlobalKey();
  // ignore: non_constant_identifier_names
  var PagesAll = [
    const HomeScreen(),
    const QRViewExample(),
    const AnalysisScreen(),
    const ProfileScreen()
  ];
  var myindex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      bottomNavigationBar: CurvedNavigationBar(
        height: 64,
        backgroundColor: Colors.transparent,
        key: _NavKey,
        items: [
          Icon((myindex == 0) ? Icons.cloud_upload : Icons.home,
              color: kBackgroundColor),
          Icon(
              (myindex == 1)
                  ? Icons.qr_code_2_outlined
                  : Icons.add_a_photo_rounded,
              color: kBackgroundColor),
          Icon((myindex == 2) ? Icons.insights_outlined : Icons.fastfood,
              color: kBackgroundColor),
          Icon((myindex == 3) ? Icons.person : Icons.perm_contact_cal_rounded,
              color: kBackgroundColor),
        ],
        onTap: (index) {
          setState(() {
            myindex = index;
          });
        },
        animationCurve: Curves.fastLinearToSlowEaseIn,
        color: kPrimaryColor,
      ),
      body: PagesAll[myindex],
    );
  }
}
