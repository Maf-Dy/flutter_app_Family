import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:wifi_ip/wifi_ip.dart';

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
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
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

class _MyHomePageState extends State<MyHomePage> {
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

  HttpServer _server; // Add a variable to store the HttpServer instance

  Future<void> _startServer() async {
    var ip = (await WifiIp.getWifiIp).ip;
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

  @override
  void initState() {
    super.initState();
    _startServer();
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) async {
      if (result != ConnectivityResult.none) {
        try {
          await _stopServer();
        } catch (e) {
          print(e);
        }
        try {
          await _startServer();
        } catch (e) {
          print(e);
        } finally {
          setState(() {});
        }
      }

      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
        appBar: AppBar(
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
                } catch (e) {
                  print(e);
                }
                setState(() {});
              },
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Enter Names',
                style: TextStyle(
                  fontSize: 20,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              Text(
                'List count: $_counter',
                style: TextStyle(
                  fontSize: 20,
                ),
              ),
              SizedBox(height: 40),
              GestureDetector(
                onTap: () async {
                  Clipboard.setData(ClipboardData(text: '$_serverUrl'));
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
                    QrImage(
                      data: '$_serverUrl',
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'tap to copy and share the link:',
                      style: TextStyle(fontSize: 18),
                    ),
                    Text(
                      '$_serverUrl',
                      style: TextStyle(fontSize: 18, color: Colors.blue),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
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
                        icon: Icon(Icons.contact_page),
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
              SizedBox(height: 20),
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

                      await _startServer();
                    }
                  }
                },
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            if (controller.text.replaceAll(' ', '').length > 0) {
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
    super.dispose();
  }
}
