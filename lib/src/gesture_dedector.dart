import 'package:flutter/cupertino.dart';

class CustomGestureDedector extends StatefulWidget {
  final Function(bool progress) clickCallBack;
  final Function() onResumeCallBack;

  /// Only support [ListView]
  final Widget child;

  CustomGestureDedector(
      {Key key, this.child, this.clickCallBack, this.onResumeCallBack})
      : super(key: key);

  @override
  _GestureDedectorState createState() => _GestureDedectorState();
}

class _GestureDedectorState extends State<CustomGestureDedector> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        child: widget.child,
        onTapDown: (_) {
          print("onTapDown");
          widget.clickCallBack(true); // stop timer
        },
        onTapCancel: () {
          print("onTapCancel");
          // widget.clickCallBack(true, false);
        },
        onTapUp: (_) {
          print("onTapUp");
          //resume starter
          widget.clickCallBack(false); // start timer
          widget.onResumeCallBack();
        },
        onHorizontalDragStart: (_) {
          print("onHorizontalDragStart");
        },
        onHorizontalDragDown: (_) {
          //
          print("onHorizontalDragDown");
          widget.clickCallBack(true); //stop timer
        },
        onHorizontalDragUpdate: (_) {
          print("onHorizontalDragUpdate");
        },
        onHorizontalDragEnd: (_) {
          print("onHorizontalDragEnd");
        },
        onVerticalDragStart: (_) {
          print("onVerticalDragStart");
        },
        onVerticalDragDown: (_) {
          //
          print("onVerticalDragDown");
          widget.clickCallBack(true); //stop timer
        },
        onVerticalDragUpdate: (_) {
          print("onVerticalDragUpdate");
        },
        onVerticalDragEnd: (_) {
          print("onVerticalDragEnd");
        });
  }
}
