import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter/material.dart';
import 'package:pepcorns/pep.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'package:flutter/services.dart';

bool isAuth = false;
final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
final usersRef = Firestore.instance.collection('Peps');

List ranD = [
  "https://http.dog/200.jpg",
  "https://http.dog/404.jpg",
  "https://http.dog/201.jpg",
  "https://http.dog/202.jpg",
  "https://http.dog/203.jpg",
  "https://http.dog/305.jpg",
  "https://http.dog/412.jpg",
  "https://http.dog/200.jpg",
  "https://http.dog/301.jpg",
  "https://http.dog/421.jpg",
  "https://http.dog/423.jpg",
  "https://http.dog/498.jpg",
  "https://http.dog/500.jpg",
  "https://http.dog/598.jpg",
  "https://http.dog/999.jpg",
  "https://http.dog/530.jpg",
  "https://http.dog/524.jpg",
];

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pepcorns Project',
      theme: ThemeData.dark(),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController eC = TextEditingController();
  TextEditingController pC = TextEditingController();
  bool signup = false;
  bool isLoading = false;
  String _errorMessage = "";
  final _formKey = new GlobalKey<FormState>();

  bool iploader = false;
  String ip = "Tap to find IPv4 Address";

  bool adloader = false;
  String address = "Tap to find current location";

  bool open = false;

  int x = 0;

  getlocation() async {
    setState(() {
      adloader = true;
    });
    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    List<Placemark> placemarks = await Geolocator()
        .placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark placemark = placemarks[0];
    String completeAddress =
        '${placemark.subThoroughfare} ${placemark.thoroughfare}, ${placemark.subLocality} ${placemark.locality}, ${placemark.subAdministrativeArea}, ${placemark.administrativeArea} ${placemark.postalCode}, ${placemark.country}';

    setState(() {
      address =
          "${placemark.subLocality},${placemark.locality}\n(${position.latitude},${position.longitude})";

      adloader = false;
    });
  }

  Future printIps() async {
    setState(() {
      iploader = true;
    });

    for (var interface in await NetworkInterface.list()) {
      print('== Interface: ${interface.name} ==');
      for (var addr in interface.addresses) {
        setState(() {
          if (addr.type.name == "IPv4") {
            print(
                '${addr.address} ${addr.host} ${addr.isLoopback} ${addr.rawAddress} ${addr.type.name}');

            ip = "IPv4 Address: " + '${addr.address}';
          }
        });

        print(ip);
      }
    }

    setState(() {
      iploader = false;
    });
  }

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

    pageController = PageController();
    pageIndex = 0;

    fauth();
  }

  fauth() {
    setState(() {
      isLoading = true;
    });

    check();

    _errorMessage = "";

    setState(() {
      isLoading = false;
    });
  }

  check() async {
    FirebaseUser user = await _firebaseAuth.currentUser();

    if (user != null) {
      setState(() {
        isLoading = true;
      });
      print(user.email);

      usersRef
          .document(DateTime.now().toString())
          .setData({"email": user.email, "timestamp": DateTime.now()});

      find();

      setState(() {
        isLoading = false;
        isAuth = true;
      });
    }
  }

  List<Pep> li = [];

  find() async {
    setState(() {
      isLoading = true;
      li = [];
    });

    QuerySnapshot snapshot =
        await usersRef.orderBy('timestamp', descending: true).getDocuments();

    setState(() {
      li = snapshot.documents.map((doc) => Pep.fromDocument(doc)).toList();
      isLoading = false;
    });
  }

  fun1() {
    showDialog(
        context: context,
        builder: (_) => new AlertDialog(
              backgroundColor: _getColorFromHex("#F2F2F2"),
              title: new Text("ACCOUNT CREATED",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 20,
                      fontFamily: "Poppins-Bold",
                      fontWeight: FontWeight.bold,
                      color: Colors.black)),
              content: Text("EMAIL ID: ${eC.text.trim()}",
                  style: TextStyle(
                      fontSize: 14,
                      fontFamily: "Poppins-Regular",
                      fontWeight: FontWeight.bold,
                      color: Colors.black)),
            ));
  }

  funx1() {
    showDialog(
        context: context,
        builder: (_) => new AlertDialog(
              backgroundColor: _getColorFromHex("#F2F2F2"),
              title: Text("ERROR",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 20,
                      fontFamily: "Poppins-Bold",
                      fontWeight: FontWeight.bold,
                      color: Colors.black)),
              content: Text("$_errorMessage",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14,
                      fontFamily: "Poppins-Regular",
                      fontWeight: FontWeight.bold,
                      color: Colors.black)),
            ));
  }

  // Check if form is valid before perform login or signup
  bool validateAndSave() {
    final form = _formKey.currentState;
    if (form.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  // Perform login or signup
  void validateAndSubmit() async {
    setState(() {
      _errorMessage = "";
      isLoading = true;
    });
    if (validateAndSave()) {
      String userId = "";
      try {
        if (!signup) {
          AuthResult result = await _firebaseAuth.signInWithEmailAndPassword(
              email: eC.text.trim(), password: pC.text.trim());
          FirebaseUser id = result.user;
          userId = id.uid;
          print('Signed in: $userId ');

          usersRef
              .document(DateTime.now().toString())
              .setData({"email": id.email, "timestamp": DateTime.now()});
          find();

          print(id.email);
          print(id.displayName);
          print(id.uid);

          setState(() {
            isAuth = true;
          });
        } else {
          AuthResult result =
              await _firebaseAuth.createUserWithEmailAndPassword(
                  email: eC.text.trim(), password: pC.text.trim());
          //widget.auth.sendEmailVerification();
          //_showVerifyEmailSentDialog();
          FirebaseUser id = result.user;
          userId = id.uid;
          print('Signed up user: $userId ');

          fun1();
        }
        setState(() {
          isLoading = false;
        });

        if (userId.length > 0 && userId != null && !signup) {}
      } catch (e) {
        print('Error: $e');

        setState(() {
          isLoading = false;
          _errorMessage = e.message;
        });
        funx1();
      }
    } else {
      setState(() {
        _errorMessage = "Invalid Data Entry.Entry can\'t be NULL";
      });

      funx1();

      isLoading = false;
    }
  }

  PageController pageController;
  int pageIndex = 0;

  onPageChanged(int pageIndex) {
    setState(() {
      this.pageIndex = pageIndex;
    });
  }

  onTap(int pageIndex) {
    pageController.animateToPage(pageIndex,
        duration: Duration(milliseconds: 200), curve: Curves.bounceOut);
  }

  @override
  Widget build(BuildContext context) {
    if (isAuth == true)
      return Scaffold(
        backgroundColor: _getColorFromHex("#9E8F64"),
        appBar: AppBar(
          centerTitle: true,
          title: Text("Pepcorns Project",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          actions: [
            IconButton(
                icon: Icon(Icons.input),
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (context) {
                        Future.delayed(Duration(seconds: 3), () {
                          Navigator.of(context).pop(true);
                        });
                        return AlertDialog(
                          backgroundColor: Colors.white,
                          title: new Text("Logging out!",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 20.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black)),
                          content: Container(
                            padding: EdgeInsets.only(bottom: 10.0),
                            child: LinearProgressIndicator(
                              valueColor: AlwaysStoppedAnimation(Colors.black),
                            ),
                          ),
                        );
                      });

                  Future.delayed(Duration(seconds: 3), () {
                    _firebaseAuth.signOut();

                    setState(() {
                      isAuth = false;
                    });
                  });
                })
          ],
        ),
        body: PageView(
          children: <Widget>[
            Container(
                height: MediaQuery.of(context).size.height,
                padding: EdgeInsets.only(top: 10),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Padding(
                          padding: EdgeInsets.fromLTRB(10, 5, 10, 10),
                          child: Card(
                              color: Colors.black,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10.0))),
                              borderOnForeground: true,
                              elevation: 5.0,
                              child: Container(
                                alignment: Alignment.center,
                                child: ListTile(
                                  onTap: () {
                                    setState(() {
                                      if (ip != "Tap to find IPv4 Address")
                                        ip = "Tap to find IPv4 Address";
                                      else
                                        printIps();
                                    });
                                  },
                                  title: (iploader == true)
                                      ? Container(
                                          alignment: Alignment.center,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 3,
                                            valueColor: AlwaysStoppedAnimation(
                                                _getColorFromHex("#9E8F64")),
                                          ))
                                      : Text(
                                          ip,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontFamily: "Poppins-Bold",
                                              color:
                                                  _getColorFromHex("#9E8F64"),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20),
                                        ),
                                ),
                              ))),
                      Padding(
                          padding: EdgeInsets.fromLTRB(10, 5, 10, 10),
                          child: Card(
                              color: Colors.black,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10.0))),
                              borderOnForeground: true,
                              elevation: 5.0,
                              child: Container(
                                alignment: Alignment.center,
                                child: ListTile(
                                  onTap: () {
                                    setState(() {
                                      if (open == true)
                                        open = false;
                                      else {
                                        open = true;
                                        x = Random().nextInt(ranD.length);
                                      }
                                    });
                                  },
                                  title: (open == true)
                                      ? Container(
                                          alignment: Alignment.center,

                                          child: Image.network(ranD[x],
                                           loadingBuilder: (BuildContext context, Widget child,
                      ImageChunkEvent loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                       
                      ),
                    );
                  },
                                              height: 200, width: 200,
                                            ))
                                      : Text(
                                          "Click here to test OpenAPI\n(Picture of Random Dogs)",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontFamily: "Poppins-Bold",
                                              color:
                                                  _getColorFromHex("#9E8F64"),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20),
                                        ),
                                ),
                              ))),
                      Padding(
                          padding: EdgeInsets.fromLTRB(10, 5, 10, 10),
                          child: Card(
                              color: Colors.black,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10.0))),
                              borderOnForeground: true,
                              elevation: 5.0,
                              child: Container(
                                alignment: Alignment.center,
                                child: ListTile(
                                  onTap: () {
                                    setState(() {
                                      if (address !=
                                          "Tap to find current location")
                                        address =
                                            "Tap to find current location";
                                      else
                                        getlocation();
                                    });
                                  },
                                  title: (adloader == true)
                                      ? Container(
                                          alignment: Alignment.center,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 3,
                                            valueColor: AlwaysStoppedAnimation(
                                                _getColorFromHex("#9E8F64")),
                                          ))
                                      : Text(
                                          address,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontFamily: "Poppins-Bold",
                                              color:
                                                  _getColorFromHex("#9E8F64"),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20),
                                        ),
                                ),
                              )))
                    ])),
            RefreshIndicator(
                onRefresh: () async {
                  find();
                },
                child: Container(
                    padding: EdgeInsets.only(top: 10),
                    child: (isLoading)
                        ? Container(
                            alignment: Alignment.center,
                            padding: EdgeInsets.only(top: 10.0),
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation(Colors.black),
                            ))
                        : ListView.builder(
                            itemCount: li.length,
                            itemBuilder: (context, int index) {
                              return Column(children: [
                                Padding(
                                    padding: EdgeInsets.fromLTRB(10, 5, 10, 10),
                                    child: Card(
                                        color: Colors.black,
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(10.0))),
                                        borderOnForeground: true,
                                        elevation: 5.0,
                                        child: Container(
                                          alignment: Alignment.center,
                                          child: ListTile(
                                            onTap: () {},
                                            leading: Image.asset(
                                                (index % 3 == 1)
                                                    ? 'images/woman.png'
                                                    : 'images/man.png',
                                                height: 50),
                                            title: Text(
                                              "User has logged in on ${converter1(li[index].timestamp)} at ${converter(li[index].timestamp)} Hrs IST. (${timeago.format(li[index].timestamp.toDate())})",
                                              style: TextStyle(
                                                  fontFamily: "Poppins-Regular",
                                                  color: _getColorFromHex(
                                                      "#9E8F64"),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12),
                                            ),
                                            subtitle: Text(
                                              "\n" + li[index].email,
                                              style: TextStyle(
                                                  fontFamily: "Poppins-Regular",
                                                  color: _getColorFromHex(
                                                      "#9E8F64"),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12),
                                            ),
                                          ),
                                        )))
                              ]);
                            }))),
          ],
          controller: pageController,
          onPageChanged: onPageChanged,
          physics: NeverScrollableScrollPhysics(),
        ),
        bottomNavigationBar: BottomNavigationBar(
            elevation: 20,
            iconSize: 30,
            currentIndex: pageIndex,
            onTap: onTap,
            selectedItemColor: _getColorFromHex("#9E8F64"),
            items: [
              BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  title: Text("Home",
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: (pageIndex == 0)
                              ? FontWeight.bold
                              : FontWeight.normal)),
                  activeIcon: Icon(Icons.home)),
              BottomNavigationBarItem(
                  icon: Icon(Icons.notifications_active_outlined),
                  title: Text("Logs",
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: (pageIndex == 1)
                              ? FontWeight.bold
                              : FontWeight.normal)),
                  activeIcon: Icon(Icons.notifications_active)),
            ]),
      );
    else
      return Scaffold(
          backgroundColor: _getColorFromHex("#9E8F64"),
          appBar: AppBar(
            centerTitle: true,
            title: Text("Pepcorns Project",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            actions: [],
          ),
          body: ListView(children: [
            Container(height: 30),
            Container(
                padding: EdgeInsets.all(10),
                alignment: Alignment.center,
                child: Image.asset('images/man.png', height: 100)),
            Container(height: 50),
            Center(
                child: Text(
              (signup) ? "CREATE AN ACCOUNT" : "ENTER THE FOLLOWING DETAILS",
              style: TextStyle(
                  fontSize: 15.0,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Poppins-Regular"),
            )),
            Form(
                key: _formKey,
                child: Column(children: [
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Container(
                      child: TextFormField(
                        style: TextStyle(
                            fontSize: 15.0,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontFamily: "Poppins-Regular"),
                        controller: eC,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(30.0)),
                            borderSide:
                                BorderSide(color: Colors.black, width: 2.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(30.0)),
                            borderSide:
                                BorderSide(color: Colors.black, width: 2.0),
                          ),
                          contentPadding: EdgeInsets.only(
                              top: 10, right: 10, bottom: 10, left: 10),
                          // labelText: "Email",
                          labelStyle: TextStyle(
                              fontSize: 12.0,
                              color: Colors.black54,
                              fontFamily: "Poppins-Regular"),
                          hintText: "Enter your Email ID",
                          hintStyle: TextStyle(
                              fontSize: 12.0,
                              color: Colors.black54,
                              fontFamily: "Poppins-Regular"),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Container(
                      child: TextFormField(
                        obscureText: true,
                        style: TextStyle(
                            fontSize: 15.0,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontFamily: "Poppins-Regular"),
                        controller: pC,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(30.0)),
                            borderSide:
                                BorderSide(color: Colors.black, width: 2.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(30.0)),
                            borderSide:
                                BorderSide(color: Colors.black, width: 2.0),
                          ),
                          contentPadding: EdgeInsets.only(
                              top: 10, right: 10, bottom: 10, left: 10),
                          // labelText: "Password",
                          labelStyle: TextStyle(
                              fontSize: 12.0,
                              color: Colors.black54,
                              fontFamily: "Poppins-Regular"),
                          hintText: "Enter Password",
                          hintStyle: TextStyle(
                              fontSize: 12.0,
                              color: Colors.black54,
                              fontFamily: "Poppins-Regular"),
                        ),
                      ),
                    ),
                  ),
                ])),
            Container(
              alignment: Alignment.center,
              child: RaisedButton(
                child: Text(
                  "Click here to " + ((signup) ? "Sign Up" : "Log In"),
                  style: TextStyle(
                      color: Colors.white, fontFamily: "Poppins-Regular"),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                color: Colors.black,
                onPressed: () {
                  validateAndSubmit();
                },
              ),
            ),
            Container(height: 15),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(
                (signup)
                    ? "Already have an account? "
                    : "Don't have an account? ",
                style: TextStyle(
                    fontSize: 13.0,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontFamily: "Poppins-Regular"),
              ),
              GestureDetector(
                  onTap: () {
                    setState(() {
                      signup = !signup;
                    });
                  },
                  child: Text(
                    (signup) ? "Log In" : "Sign Up",
                    style: TextStyle(
                        fontSize: 13.0,
                        color: _getColorFromHex("#215280"),
                        fontWeight: FontWeight.bold,
                        fontFamily: "Poppins-Regular"),
                  ))
            ]),
            Container(height: 20),
            (isLoading)
                ? Container(
                    alignment: Alignment.center,
                    padding: EdgeInsets.only(top: 10.0),
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation(Colors.black),
                    ))
                : Container(height: 0, width: 0)
          ]));
  }
}

converter(t) {
  var x = DateTime.fromMicrosecondsSinceEpoch(t.microsecondsSinceEpoch);

  var y = x.toString().split(" ");

  var z = y[1].substring(0, 5);

  return z;
}

converter1(t) {
  var x = DateTime.fromMicrosecondsSinceEpoch(t.microsecondsSinceEpoch);

  var y = x.toString().split(" ");

  return y[0];
}

Color _getColorFromHex(String hexColor) {
  hexColor = hexColor.replaceAll("#", "");
  if (hexColor.length == 6) {
    hexColor = "FF" + hexColor;
  }
  if (hexColor.length == 8) {
    return Color(int.parse("0x$hexColor"));
  }
}
