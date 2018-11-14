import 'dart:async';
import 'package:flutter/material.dart';



class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Auth Demo',
      home: BasicPage(title: 'Firebase Auth Demo'),
    );
  }
}

class BasicPage extends StatefulWidget {
  BasicPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _BasicPageState createState() => _BasicPageState();
}

class _BasicPageState extends State<BasicPage> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
  }

}