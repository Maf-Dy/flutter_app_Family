import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:ping_discover_network/ping_discover_network.dart';
import 'package:wifi/wifi.dart';

class NamesPage extends StatefulWidget {
  List<String> names;

  NamesPage({this.names});

  @override
  State<StatefulWidget> createState() => NamesPageState(names: names);
}

class NamesPageState extends State<NamesPage> {
  List<String> names;

  NamesPageState({this.names});

  Key key;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Names"),
      ),
      body: Center(
        child: Flex(
          direction: Axis.vertical,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            AnimationLimiter(
                child: ListView.builder(
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    itemCount: names.length,
                    itemBuilder: (context, i) {
                      return AnimationConfiguration.staggeredList(
                          position: i,
                          key: key,
                          duration: const Duration(milliseconds: 500),
                          child: FadeInAnimation(
                              child: Card(
                                  child: Center(
                                      child: Text(
                            '${names[i]}',
                            style: Theme.of(context).textTheme.headline5,
                          )))));
                    }))
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          HttpClientRequest request =
              await HttpClient().post("0.0.0.0", 4040, "") /*1*/
                ..headers.contentType = ContentType.text /*2*/
                ..write(utf8.encoder.convert(names.toString())); /*3*/
          HttpClientResponse response = await request.close(); /*4*/
          await utf8.decoder.bind(response /*5*/).forEach(print);

          await search();

          setState(() {
            names.shuffle(Random(names.length + 1));
            names.shuffle();
            names.shuffle();
          });
        },
        tooltip: 'Shuffle',
        child: Icon(Icons.shuffle),
      ),
    );
  }
}

Future<void> search() async {
  final String ip = await Wifi.ip;
  final String subnet = ip.substring(0, ip.lastIndexOf('.'));
  final int port = 4040;

  final stream = NetworkAnalyzer.discover2(subnet, port);
  stream.listen((NetworkAddress addr) {
    if (addr.exists) {
      print('Found device: ${addr.ip}');
    }
  });
}
