import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_app5/NamesPage.dart';
import 'package:wifi/wifi.dart';

void main() async {
  runApp(MyApp());

  await createHttp();
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Family V2',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Family 2'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  List<String> names = [];
  TextEditingController controller = TextEditingController();

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
                      names = [];
                      _counter = names.length;
                    });
                  })
            ],
          ),
          body: Center(
            child: Flex(
              direction: Axis.vertical,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Align(
                    alignment: Alignment.center,
                    child: Column(children: <Widget>[
                      Text(
                        'Enter Names',
                        style: TextStyle(
                            fontSize: 20,
                            color: Theme.of(context).primaryColor),
                      ),
                      Text(
                        'List count: $_counter',
                        style: TextStyle(
                          fontSize: 20,
                        ),
                      )
                    ])),
                Card(
                    borderOnForeground: true,
                    child: TextField(
                      controller: controller,
                      style: TextStyle(
                        fontSize: 20,
                      ),
                      decoration: InputDecoration(
                        icon: Icon(Icons.contact_page),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(5))),
                        labelText: 'Name',
                      ),
                      maxLines: 1,
                    )),
                OutlinedButton(
                    child: Text('Start',
                        style: TextStyle(
                          fontSize: 15,
                        )),
                    onPressed: () {
                      if (names.length > 0) {
                        names.shuffle(Random(names.length + 1));
                        names.shuffle();
                        names.shuffle();

                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                          return NamesPage(names: names);
                        }));
                      }
                    })
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              if (controller.text.replaceAll(' ', '').length > 0) {
                setState(() {
                  names.add(controller.text);

                  controller.text = '';
                  _counter = names.length;
                });
              }
            },
            tooltip: 'Increment',
            child: Icon(Icons.add),
          ),
        ),
        onWillPop: () async {
          return false;
        });
  }
}

Future<void> createHttp() async {
  var server = await HttpServer.bind(
    "0.0.0.0",
    4040,
  );
  print('Listening on ${server.address.address} localhost:${server.port}');

  print(Wifi.ip.then((value) => value));

  await for (HttpRequest request in server) {
    request.response
      ..headers.contentType = ContentType("text", "plain", charset: "utf-8")
      ..write("hello world");
    await request.response.flush();
    await request.response.close();
  }
}
