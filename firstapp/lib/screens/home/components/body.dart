import 'package:flutter/material.dart';
import '../../../constants.dart';
import 'package:firstapp/screens/details/details_screen.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:firstapp/database/invoice_database.dart';
import 'package:firstapp/screens/login/login_model.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Body extends StatefulWidget {
  const Body({Key? key}) : super(key: key);

  @override
  _State createState() => _State();
}

var time = DateTime.now();
var date = DateTime(time.year - 1911, time.month);
String current = date.year.toString() + date.month.toString();

class _State extends State<Body> with SingleTickerProviderStateMixin {
  final CategoriesScroller categoriesScroller = const CategoriesScroller();
  ScrollController controller = ScrollController();
  bool closeTopContainer = false;
  double topContainer = 0;

  List<Widget> itemsData = [];

  Future<List<Widget>> getPostsData(String current) async {
    List<Widget> listItems = [];

    List<Header>? responseList = await HeaderHelper.instance.getHeader(current);

    for (int i = responseList.length - 1; i > -1; i--) {
      listItems.add(
        GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailsScreen(
                    tag: responseList[i].tag,
                    invDate: responseList[i].date,
                    seller: responseList[i].seller,
                    address: responseList[i].address,
                    invNum: responseList[i].invNum,
                    time: responseList[i].time,
                    amount: responseList[i].amount,
                  ),
                ),
              );
            },
            child: Container(
                height: 145,
                margin:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(20.0)),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withAlpha(100), blurRadius: 10.0),
                    ]),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text(
                                  responseList[i].invNum,
                                  style: const TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '   ' + responseList[i].date + '   ',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold),
                                ),
                                if (responseList[i].barcode == "Scan")
                                  Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: Colors.blueGrey,
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    child: const Text("??????",
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        )),
                                  ),
                              ]),
                          Text(
                            responseList[i].seller,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.black),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Text(
                            "\$" + responseList[i].amount,
                            style: const TextStyle(
                                fontSize: 25,
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                          )
                        ],
                      ),
                      Image.asset(
                        "assets/images/image_1.png",
                        height: 53,
                      )
                    ],
                  ),
                ))),
      );
    }

    itemsData = listItems;

    return listItems;
  }

  Future<void> _handleRefresh() async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    String barcode = pref.getString('barcode')!;
    String password = pref.getString('password')!;

    var now = DateTime.now();
    List<Header>? responseList2 = await HeaderHelper.instance.getAll();

    String tmpTag = responseList2[responseList2.length - 1].tag;
    String tmpDate = responseList2[responseList2.length - 1].date;
    final splitted = tmpDate.split('/');
    int tmpYear = int.parse(splitted[0]);
    int tmpMonth = int.parse(splitted[1]);

    int timestamp = DateTime.now().millisecondsSinceEpoch + 30;
    int exp = timestamp + 200;
    var formatter = DateFormat('yyyy/MM/dd');
    String responseString;
    String sdate;
    String edate;
    DateTime last;
    DateTime start;
    http.Response response;

    while (true) {
      start = DateTime(tmpYear, tmpMonth, 01);
      last = DateTime(tmpYear, tmpMonth + 1, 0);
      sdate = formatter.format(start);
      edate = formatter.format(last);
      response = await http.post(
          Uri.https("api.einvoice.nat.gov.tw", "PB2CAPIVAN/invServ/InvServ"),
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
      loginModelFromJson(responseString);
      if (start.year == now.year && start.month == now.month) {
        break;
      }
      tmpMonth += 1;
    }

    return;
  }

  void leftclick() {
    date = DateTime(date.year, date.month - 1);
    current = date.year.toString() + date.month.toString();
    setState(() {
      getPostsData(current);
    });
  }

  void rightclick() {
    date = DateTime(date.year, date.month + 1);
    current = date.year.toString() + date.month.toString();
    setState(() {
      getPostsData(current);
    });
  }

  @override
  void initState() {
    controller.addListener(() {
      double value = controller.offset / 119;

      setState(() {
        topContainer = value;
        closeTopContainer = controller.offset > 50;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double categoryHeight = size.height * 0.25;

    return SafeArea(
      child: Scaffold(
        body: FutureBuilder<List<Widget>>(
          future: getPostsData(current),
          builder: (BuildContext context, AsyncSnapshot? snapshot) {
            if (snapshot?.data?.isEmpty ?? true) {
              return SizedBox(
                height: size.height,
                child: Column(
                  children: <Widget>[
                    const SizedBox(
                      height: 10,
                    ),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 500),
                      opacity: closeTopContainer ? 0 : 1,
                      child: AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          width: size.width,
                          alignment: Alignment.topCenter,
                          height: closeTopContainer ? 0 : categoryHeight,
                          child: categoriesScroller),
                    ),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          TextButton(
                            child: const Icon(Icons.arrow_circle_left),
                            onPressed: leftclick,
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                                '  ' +
                                    date.year.toString() +
                                    '???' +
                                    ' ' +
                                    date.month.toString() +
                                    '???' +
                                    '  ',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                )),
                          ),
                          TextButton(
                            child: const Icon(Icons.arrow_circle_right),
                            onPressed: rightclick,
                          )
                        ]),
                    const SizedBox(height: 10),
                    Expanded(
                      child: LiquidPullToRefresh(
                          height: 90,
                          color: kSecondaryColor,
                          onRefresh: _handleRefresh,
                          child: const Text("\n\n????????????")),
                    ),
                  ],
                ),
              );
            }
            return SizedBox(
              height: size.height,
              child: Column(
                children: <Widget>[
                  const SizedBox(
                    height: 10,
                  ),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 350),
                    opacity: closeTopContainer ? 0 : 1,
                    child: AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        width: size.width,
                        alignment: Alignment.topCenter,
                        height: closeTopContainer ? 0 : categoryHeight,
                        child: categoriesScroller),
                  ),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        TextButton(
                          child: const Icon(Icons.arrow_circle_left),
                          onPressed: leftclick,
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                              '  ' +
                                  date.year.toString() +
                                  '???' +
                                  ' ' +
                                  date.month.toString() +
                                  '???' +
                                  '  ',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              )),
                        ),
                        TextButton(
                          child: const Icon(Icons.arrow_circle_right),
                          onPressed: rightclick,
                        )
                      ]),
                  const SizedBox(height: 18),
                  Expanded(
                      child: LiquidPullToRefresh(
                          height: 90,
                          color: kSecondaryColor,
                          onRefresh: _handleRefresh,
                          child: ListView.builder(
                              controller: controller,
                              itemCount: snapshot?.data.length,
                              physics: const BouncingScrollPhysics(),
                              itemBuilder: (context, index) {
                                double scale = 1.0;
                                if (topContainer > 0.5) {
                                  scale = index + 0.5 - topContainer;
                                  if (scale < 0) {
                                    scale = 0;
                                  } else if (scale > 1) {
                                    scale = 1;
                                  }
                                }
                                return Opacity(
                                  opacity: scale,
                                  child: Transform(
                                    transform: Matrix4.identity()
                                      ..scale(scale, scale),
                                    alignment: Alignment.bottomCenter,
                                    child: Align(
                                        heightFactor: 0.7,
                                        alignment: Alignment.topCenter,
                                        child: snapshot?.data[index]),
                                  ),
                                );
                              }))),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class CategoriesScroller extends StatelessWidget {
  const CategoriesScroller();

  @override
  Widget build(BuildContext context) {
    final double categoryHeight =
        MediaQuery.of(context).size.height * 0.30 - 85;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      scrollDirection: Axis.horizontal,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
        child: FittedBox(
          fit: BoxFit.fill,
          alignment: Alignment.topCenter,
          child: Row(
            children: <Widget>[
              Container(
                width: 150,
                margin: const EdgeInsets.only(right: 20),
                height: categoryHeight,
                decoration: const BoxDecoration(
                    color: kPrimaryColor,
                    borderRadius: BorderRadius.all(Radius.circular(20.0))),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const <Widget>[
                      Text(
                        "Most\nFavorites",
                        style: TextStyle(
                            fontSize: 25,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Text(
                        "20 Items",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: 150,
                margin: const EdgeInsets.only(right: 20),
                height: categoryHeight,
                decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(20.0))),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const <Widget>[
                      Text(
                        "Newest",
                        style: TextStyle(
                            fontSize: 25,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Text(
                        "20 Items",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: 150,
                margin: const EdgeInsets.only(right: 20),
                height: categoryHeight,
                decoration: const BoxDecoration(
                    color: kSecondaryColor,
                    borderRadius: BorderRadius.all(Radius.circular(20.0))),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const <Widget>[
                      Text(
                        "Super\nSaving",
                        style: TextStyle(
                            fontSize: 25,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Text(
                        "20 Items",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
