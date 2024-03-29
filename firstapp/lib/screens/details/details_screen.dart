import 'package:firstapp/constants.dart';
import 'package:flutter/material.dart';
import 'package:firstapp/database/details_database.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'dart:convert';

class DetailsScreen extends StatelessWidget {
  final String tag, invDate, invNum, seller, address, time, amount, w;
  const DetailsScreen({
    Key? key,
    required this.tag,
    required this.invDate,
    required this.seller,
    required this.address,
    required this.invNum,
    required this.time,
    required this.amount,
    required this.w,
  }) : super(key: key);

  Future<List<invoice_details>> getDetail() async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    String? barcode = pref.getString('barcode') ?? "";
    String? password = pref.getString('password') ?? "";

    List<invoice_details> responseList = [];

    responseList = await DetailHelper.instance.getDetail(tag, invNum);

    if (responseList.isEmpty) {
      int timestamp = DateTime.now().millisecondsSinceEpoch + 10000;
      int exp = timestamp + 700000;
      var rbody = {
        "version": "0.5",
        "cardType": "3J0002",
        "cardNo": barcode,
        "expTimeStamp": exp.toString().substring(0, 10),
        "action": "carrierInvDetail",
        "timeStamp": timestamp.toString().substring(0, 10),
        "invNum": invNum,
        "invDate": invDate,
        "uuid": '1000',
        "appID": 'EINV0202204156709',
        "cardEncrypt": password,
      };

      var client = http.Client();
      try {
        var response = await client.post(
          Uri.parse(
              "https://api.einvoice.nat.gov.tw/PB2CAPIVAN/invServ/InvServ"),
          headers: {
            "Content-Type": "application/x-www-form-urlencoded",
          },
          body: rbody,
        );

        if (response.statusCode == 200) {
          String responseString = response.body;
          var r = jsonDecode(responseString);
          List d = r['details'];
          for (var de in d) {
            await DetailHelper.instance.add(invoice_details(
                tag: tag.toString(),
                invNum: invNum.toString(),
                name: de['description'],
                date: invDate.toString(),
                quantity: de['quantity'],
                amount: de['amount'],
                type: 0));
            responseList.add(invoice_details(
                tag: tag.toString(),
                invNum: invNum.toString(),
                name: de['description'],
                date: invDate.toString(),
                quantity: de['quantity'],
                amount: de['amount'],
                type: 0));
          }
        } else {
          print(response.statusCode);
        }
      } catch (e) {
        debugPrint("$e");
      } finally {
        client.close();
      }
    }

    return responseList;
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
        backgroundColor:
            w == 'f' ? kPrimaryColor : const Color.fromARGB(255, 252, 243, 167),
        appBar: AppBar(
          backgroundColor: w == 'f'
              ? kPrimaryColor
              : const Color.fromARGB(255, 252, 243, 167),
          elevation: 0,
          leading: IconButton(
              icon: SvgPicture.asset("assets/icons/back_arrow.svg",
                  color: w == 'f' ? Colors.white : kTextColor),
              onPressed: () => Navigator.pop(context)),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              SizedBox(
                height: size.height,
                child: Stack(
                  children: <Widget>[
                    FutureBuilder(
                        future: getDetail(),
                        builder:
                            (BuildContext context, AsyncSnapshot snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.done) {
                            return Container(
                              margin: EdgeInsets.only(top: size.height * 0.30),
                              height: 700,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(24),
                                  topRight: Radius.circular(24),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(25),
                                child: Column(
                                  children: <Widget>[
                                    const SizedBox(height: 15),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: const [
                                        Text("品名"),
                                        Text(
                                            "                                                             數量"),
                                        Text("小計  ")
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    const Divider(),
                                    const SizedBox(height: 16),
                                    for (invoice_details value
                                        in snapshot.data ?? [])
                                      (CustomRow(
                                          name: value.name,
                                          quentity: value.quantity,
                                          price: value.amount)),
                                    Text("\n\n\n\n總計   \$" + amount)
                                  ],
                                ),
                              ),
                            );
                          } else {
                            return Center(
                                child: LoadingAnimationWidget.flickr(
                              rightDotColor: kSecondaryColor,
                              leftDotColor: Colors.white,
                              size: 50,
                            ));
                          }
                        }),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: kDefaultPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const SizedBox(height: 20),
                          Text(
                            invNum,
                            style: Theme.of(context)
                                .textTheme
                                .headline4
                                ?.copyWith(
                                    color: w == 'f'
                                        ? Colors.white
                                        : const Color.fromARGB(
                                            255, 71, 148, 74),
                                    fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 35),
                          Row(
                            children: [
                              Icon(Icons.store,
                                  color: w == 'f' ? Colors.white : kTextColor),
                              Text('  ' + seller,
                                  style: TextStyle(
                                      color: w == 'f'
                                          ? Colors.white
                                          : kTextColor)),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Icon(Icons.location_on,
                                  color: w == 'f' ? Colors.white : kTextColor),
                              Text('  ' + address,
                                  style: TextStyle(
                                      color: w == 'f'
                                          ? Colors.white
                                          : kTextColor)),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Icon(Icons.date_range,
                                  color: w == 'f' ? Colors.white : kTextColor),
                              Text('  ' + invDate,
                                  style: TextStyle(
                                      color: w == 'f'
                                          ? Colors.white
                                          : kTextColor)),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Icon(Icons.access_time,
                                  color: w == 'f' ? Colors.white : kTextColor),
                              Text('  ' + time,
                                  style: TextStyle(
                                      color: w == 'f'
                                          ? Colors.white
                                          : kTextColor)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (w == 'f')
                      Positioned(
                        top: 0,
                        right: 30,
                        child: Hero(
                          tag: invNum,
                          child: Container(
                            height: 70,
                            width: 70,
                            decoration: BoxDecoration(
                                image: const DecorationImage(
                                    image:
                                        AssetImage("assets/images/image_1.png"),
                                    fit: BoxFit.fill),
                                color: Colors.white,
                                shape: BoxShape.rectangle,
                                borderRadius: BorderRadius.circular(25)),
                          ),
                        ),
                      ),
                    if (w != 'f')
                      Positioned(
                          top: 0,
                          right: 25,
                          child: Hero(
                            tag: invNum,
                            child: Image.asset(
                              "assets/images/money.png",
                              height: 93,
                            ),
                          )),
                  ],
                ),
              ),
            ],
          ),
        ));
  }
}

class CustomRow extends StatelessWidget {
  final String name;
  final String quentity;
  final String price;

  const CustomRow(
      {Key? key,
      required this.name,
      required this.quentity,
      required this.price})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 6, // Change this property to align your content

            child: Text(
              name, // Name
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black,
                decoration: TextDecoration.none,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Expanded(
            flex: 1, // Change this property to align your content
            child: Text(
              "x" + quentity, // Name
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black,
                decoration: TextDecoration.none,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Expanded(
            flex: 1, // Change this property to align your content
            child: Text(
              price, // Name
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black,
                decoration: TextDecoration.none,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
