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
      key: Key('Scaffold2'),
      appBar: AppBar(
        title: Text("Names"),
      ),
      body: Center(
        child: Flex(
          direction: Axis.vertical,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            AnimationLimiter(
                child: ListView.builder(
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    padding: EdgeInsets.all(8),
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
        onPressed: () {
          /* HttpClientRequest request =
              await HttpClient().post("0.0.0.0", 4040, "") /*1*/
                ..headers.contentType = ContentType.text /*2*/
                ..write(utf8.encoder.convert(names.toString())); /*3*/
          HttpClientResponse response = await request.close(); /*4*/
          await utf8.decoder.bind(response /*5*/).forEach(print);*/

          search().then((value) {
            value.listen((addr) async {
              if (addr.exists) {
                Map jsonData = {
                  'name': 'Han Solo',
                  'job': 'reluctant hero',
                  'BFF': 'Chewbacca',
                  'ship': 'Millennium Falcon',
                  'weakness': 'smuggling debts'
                };

                HttpClientRequest request2 = await HttpClient()
                    .post(addr.ip, 4040, "/?name=${names[0]}") /*2*/
                  ..headers.add('Content-Type',
                      'application/x-www-form-urlencoded; charset=UTF-8')
                  ..write(utf8.encoder.convert(jsonEncode(jsonData))); /*3*/
                HttpClientResponse response2 = await request2.close(); /*4*/
                await utf8.decoder.bind(response2 /*5*/).forEach(print);
              }
            });
          });

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

Future<Stream<NetworkAddress>> search() async {
  final String ip = await Wifi.ip;
  final String subnet = ip.substring(0, ip.lastIndexOf('.'));
  final int port = 4040;

  final stream = NetworkAnalyzer.discover2(subnet, port);
  return stream;
}
