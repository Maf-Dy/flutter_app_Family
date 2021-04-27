import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

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
