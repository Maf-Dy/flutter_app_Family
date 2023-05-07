import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'dart:io';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:lottie/lottie.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:vibration/vibration.dart';

import 'NamesPage.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Family Game',
      darkTheme: ThemeData.dark(useMaterial3: true),
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blueGrey,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Family Game'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;
  List names = [];

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  int _counter = 0;

  TextEditingController controller = TextEditingController();

  String _serverUrl = ''; // Add a variable to store the server URL

  // Serve the webpage that contains a text field for entering names
  void _serveWebPage(HttpResponse response) {
    response.headers.contentType = ContentType.html;
    response.write('''
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>Family: Names</title>
        <style>
          body {
            font-family: sans-serif;
            padding: 20px;
            text-align: center;
            display: flex;
            align-items: center;
            justify-content: center;
          }
          form {
            display: inline-block;
            border: 2px solid #ccc;
            border-radius: 5px;
            padding: 20px;
            max-width: 500px;
            width: 100%;
            box-sizing: border-box;
            margin: 0 auto;
          }
          label {
            display: block;
            font-size: 18px;
            font-weight: bold;
            margin-bottom: 10px;
          }
          input[type="text"] {
            display: block;
            width: 100%;
            font-size: 18px;
            padding: 10px;
            border: 2px solid #ccc;
            border-radius: 5px;
            box-sizing: border-box;
            margin-bottom: 20px;
          }
          input[type="submit"] {
            display: block;
            background-color: #607D8B;
            color: white;
            font-size: 18px;
            font-weight: bold;
            padding: 10px 20px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
          }
          input[type="submit"]:hover {
            background-color: #90A4AE;
          }
        </style>
      </head>
      <body>
        <form method="post">
          <label for="name">Enter Name:</label>
          <input type="text" id="name" name="name">
          <input type="submit" value="Submit">
        </form>
      </body>
    </html>
  ''');
    response.close();
  }

  // Receive the names entered in the web page form
  Future<void> _handleWebForm(HttpRequest request) async {
    var body = await utf8.decoder.bind(request).join();
    var formData = Uri.splitQueryString(body);

    var name = formData['name'];
    var cookie = request.cookies
        .firstWhere((cookie) => cookie.name == 'clientID', orElse: () => null);
    if (name != null &&
        name.isNotEmpty &&
        (cookie == null ||
            !widget.names.any((entry) => entry['clientID'] == cookie.value))) {

      vibrate();

      setState(() {
        widget.names.add(
            {'name': name, 'clientID': cookie != null ? cookie.value : null});
        _counter = widget.names.length;
      });
    }

    request.response.statusCode = HttpStatus.seeOther;
    request.response.headers.set('Location', '/');
    request.response.cookies.add(Cookie('clientID',
        cookie?.value ?? DateTime.now().millisecondsSinceEpoch.toString()));
    await request.response.close();
  }

  void vibrate() {
    Vibration.vibrate(pattern: [200, 200, 200, 200,400,200]);
  }

  HttpServer _server; // Add a variable to store the HttpServer instance

  Future<void> _startServer() async {
    var ip;

    final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4, includeLinkLocal: true);

    try {
      NetworkInterface interface =
          interfaces.firstWhere((element) => element.name.contains("wlan"));
      ip = interface.addresses.first.address;
    } catch (ex) {}

    _server = await HttpServer.bind(ip, 8182);
    _serverUrl =
        'http://${_server.address.host}:${_server.port}'; // Set the server URL
    print('Local server started at $_serverUrl');

    await for (var request in _server) {
      if (request.method == 'GET' && request.uri.path == '/') {
        var cookie = request.cookies.firstWhere(
            (cookie) => cookie.name == 'clientID',
            orElse: () => null);
        request.response.cookies.add(Cookie('clientID',
            cookie?.value ?? DateTime.now().millisecondsSinceEpoch.toString()));
        _serveWebPage(request.response);
      } else if (request.method == 'POST' && request.uri.path == '/') {
        await _handleWebForm(request);
      } else if (request.method == 'GET' && request.uri.path == '/admin') {
        request.response.write(widget.names
            .map((entry) => '${entry['name']} (${entry['clientID']})')
            .join('\n'));
        await request.response.close();
      }
    }
  }

  // Stop local HTTP server
  Future<void> _stopServer() async {
    if (_server != null) {
      await _server.close(force: true);
      print('Local server stopped');
    }
  }

  StreamSubscription<ConnectivityResult> _connectivitySubscription;

  Timer _timer;
  bool lanWorking = false;

  Future<void> _checkNetworkStatus() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    //if (connectivityResult != ConnectivityResult.none) {
    try {
      await _stopServer();
    } catch (e) {
      print(e);
    }
    try {
      await _startServer();
      lanWorking = true;
    } catch (e) {
      print(e);
      lanWorking = false;
    } finally {
      setState(() {});
    }
    //}
  }

  @override
  void initState() {
    super.initState();
    try {
      _startServer();
      lanWorking = true;
    } catch (e) {
      print(e);
      lanWorking = false;
    } finally {
      setState(() {});
    }
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) async {
      //if (result != ConnectivityResult.none) {
      try {
        await _stopServer();
      } catch (e) {
        print(e);
      }
      try {
        await _startServer();
        lanWorking = true;
      } catch (e) {
        print(e);
        lanWorking = false;
      } finally {
        setState(() {});
      }
      //}

      setState(() {});
    });

    // Start a timer to periodically check network status
    _timer = Timer.periodic(Duration(seconds: 4), (timer) {
      try {
        _checkNetworkStatus();
      } catch (e) {
        print(e);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
        appBar: AppBar(
          elevation: 4,
          title: Text(widget.title),
          actions: [
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                setState(() {
                  widget.names = [];
                  _counter = widget.names.length;
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () async {
                try {
                  await _stopServer();
                } catch (e) {
                  print(e);
                }
                try {
                  await _startServer();
                  lanWorking = true;
                } catch (e) {
                  print(e);
                  lanWorking = false;
                } finally {
                  setState(() {});
                }
              },
            ),
          ],
        ),
        body: Center(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: 0.5,
                child: Lottie.asset(
                  'assets/animations/background.json',
                  fit: BoxFit.cover,
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    height: 80,
                    child: AnimatedTextKit(
                      repeatForever: true,
                      pause: Duration(milliseconds: 0),
                      animatedTexts: [
                        RotateAnimatedText('Enter Names Here',
                            transitionHeight: 50,
                            duration: Duration(milliseconds: 7000),
                            textAlign: TextAlign.center,
                            textStyle: TextStyle(
                              fontSize: 20,
                            )),
                        RotateAnimatedText(
                            'Share link with friends\n to enter Names',
                            duration: Duration(milliseconds: 7000),
                            transitionHeight: 50,
                            textAlign: TextAlign.center,
                            textStyle: TextStyle(

                              fontSize: 20,
                            ))
                      ],
                    ),
                  ),
                  Container(
                    height: 40,
                    child: AnimatedTextKit(
                      repeatForever: true,
                      pause: Duration(milliseconds: 0),
                      animatedTexts: [ColorizeAnimatedText(
                        'Count: $_counter',
                        speed: Duration(milliseconds: 200),
                        textStyle: TextStyle(
                          fontSize: 20,
                        ), colors: [
                        Colors.blueGrey.shade200,
                        Colors.deepOrange,
                        Colors.brown,],
                      )],
                    ),
                  ),
                  SizedBox(height: 20),
                  AnimatedContainer(
                    duration: Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    height: lanWorking && _serverUrl != '' ? 300 : 200,
                    child: lanWorking && _serverUrl != ''
                        ? GestureDetector(
                            onTap: () async {
                              Clipboard.setData(
                                  ClipboardData(text: '$_serverUrl'));
                              await FlutterShare.share(
                                  title: 'Enter Name link',
                                  chooserTitle: 'Share link to enter names',
                                  text: 'Link to enter names:',
                                  linkUrl: '$_serverUrl');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Link copied to clipboard'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                AnimatedSize(
                                  duration: Duration(milliseconds: 1000),
                                  curve: Curves.easeInOut,
                                  child: QrImage(
                                    backgroundColor: Colors.white,
                                    data: '$_serverUrl',
                                    version: QrVersions.auto,
                                    size: 200.0,
                                  ),
                                ),
                                SizedBox(height: 20),
                                AnimatedDefaultTextStyle(
                                  duration: Duration(milliseconds: 2000),
                                  curve: Curves.easeInOut,
                                  style: TextStyle(fontSize: 18),
                                  child: Text(
                                    '👥 Tap to Share Game Link 🎮',
                                  ),
                                ),
                                SizedBox(height: 10),
                                AnimatedDefaultTextStyle(
                                  duration: Duration(milliseconds: 2000),
                                  curve: Curves.easeInOut,
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.blue),
                                  child: Text(
                                    '$_serverUrl',
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            child: Lottie.asset(
                              'assets/animations/lost_connection.json',
                              repeat: false,
                              frameRate: FrameRate(60),
                              delegates: LottieDelegates(
                                values: [
                                  ValueDelegate.color(
                                    // keyPath order: ['layer name', 'group name', 'shape name']
                                    const ['**', '3d_box', '**'],
                                    value: Colors.blueGrey,
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                  SizedBox(height: 10),
                  Card(
                    borderOnForeground: true,
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: Form(
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: TextFormField(
                          controller: controller,
                          validator: (value) {
                            if (value.replaceAll(" ", "").isNotEmpty) {
                              return 'Please remember to add the name';
                            }
                            return null;
                          },
                          style: TextStyle(
                            fontSize: 20,
                          ),
                          decoration: InputDecoration(
                            icon: Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(5),
                              ),
                            ),
                            labelText: 'Name',
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  OutlinedButton(
                    child: Text(
                      'Start',
                      style: TextStyle(
                        fontSize: 15,
                      ),
                    ),
                    onPressed: () async {
                      if (widget.names.length > 0) {
                        bool confirm = await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text("Confirmation"),
                              content: Text("Are you sure ?"),
                              actions: [
                                TextButton(
                                  child: Text("Cancel"),
                                  onPressed: () {
                                    Navigator.of(context).pop(false);
                                  },
                                ),
                                TextButton(
                                  child: Text("Yes"),
                                  onPressed: () {
                                    Navigator.of(context).pop(true);
                                  },
                                ),
                              ],
                            );
                          },
                        );

                        if (confirm) {
                          widget.names.shuffle(Random(widget.names.length + 1));
                          widget.names.shuffle();
                          widget.names.shuffle();

                          await _stopServer();

                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) {
                                return NamesPage(
                                  names: widget.names
                                      .map((entry) => entry['name'].toString())
                                      .toList(),
                                );
                              },
                            ),
                          );

                          try {
                            await _startServer();
                            lanWorking = true;
                          } catch (e) {
                            print(e);
                            lanWorking = false;
                          } finally {
                            setState(() {});
                          }
                        }
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            if (controller.text.replaceAll(' ', '').length > 0) {

              vibrate();

              setState(() {
                widget.names.add({'name': controller.text, 'clientID': ''});

                controller.text = '';
                _counter = widget.names.length;
              });
            }
          },
          tooltip: 'Add Name',
          isExtended: true,
          backgroundColor: Color(0xFF607D8B),
          foregroundColor: Colors.white,
          clipBehavior: Clip.antiAliasWithSaveLayer,
          label: Text('Add Name'),
          icon: Icon(Icons.add),
        ),
        extendBody: true,
        extendBodyBehindAppBar: true,
      ),
      onWillPop: () async {
        return false;
      },
    );
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _stopServer();
    _timer.cancel(); // Cancel the timer on dispose
    super.dispose();
  }
}
