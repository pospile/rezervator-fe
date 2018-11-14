import 'package:flutter/material.dart';

Widget button(title, uri, [ color = const Color.fromRGBO(68, 68, 76, .8) ]) {
  return Container(
    height: 60.0,
    child: Center(
      child: Row(
        children: <Widget>[
          Image.asset(
            uri,
            width: 23.0,
          ),
          Padding(
            child: Text(
              "$title",
              style:  TextStyle(
                fontSize: 15.0,
                fontFamily: 'Roboto',
                color: color,
              ),
            ),
            padding: new EdgeInsets.only(left: 15.0),
          ),
        ],
      ),
    ),
  );
}