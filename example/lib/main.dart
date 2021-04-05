import 'dart:async';

import 'package:flutter/material.dart';
import 'package:loadmore/loadmore.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        primarySwatch: Colors.red,
      ),
      home: new MyHomePage(title: 'Döviz Kurları'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int get count => list.length;
  int  itemsize = 4;

  List<int> list = [];
  void initState() {
    super.initState();
    load();
  }

  void load() {
    setState(() {
      list.addAll(List.generate(itemsize, (v) => v));
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.title),
      ),
      body: Container(
        height: 50,
        color: Colors.black,
        child: LoadMore(
          isFinish: count >= 60000,
          onLoadMore: _loadMore,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemBuilder: (BuildContext context, int index) {
              return getRow();
            },
            itemCount: count,
          ),
          whenEmptyLoad: true,
          delegate: DefaultLoadMoreDelegate(),
          textBuilder: DefaultLoadMoreTextBuilder.english,
        ),
      ),
    );
  }

  Future<bool> _loadMore() async {
    load();
    return true;
  }

  Widget getRow() {
    return Container(
        margin: EdgeInsets.only(left: 20, right: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [column1(), column2()],
        ));
  }

  column1() {
    return Container(
        width: 60,
        height: 40,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              children: [text1()],
            ),
            Text(
              "+%0.53",
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey),
            ),
          ],
        ));
  }

  column2() {
    return Container(
      //width: 50,
      height: 35,
      margin: EdgeInsets.only(left: 5),
      child: Text(
        "1389.42",
        style: TextStyle(
            fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  text1() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "ALTIN",
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        Container(
          width: 5,
          height: 15,
          margin: EdgeInsets.only(bottom: 8, left: 2),
          child: Icon(
            Icons.expand_less_rounded,
            color: Colors.red,
          ),
        )
      ],
    );
  }
}
