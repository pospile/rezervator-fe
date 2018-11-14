import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rezervator/main.dart';
import 'package:flutter_calendar_carousel/flutter_calendar_carousel.dart'
    show CalendarCarousel;
import 'package:intl/intl.dart' show DateFormat;
import 'package:rezervator/CarTO.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class Calendar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    initializeDateFormatting();
    return MaterialApp(
      title: 'Rezervace',
      home: CalendarPage(title: 'Rezervace'),
    );
  }
}

class CalendarPage extends StatefulWidget {
  CalendarPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _selectedDate = DateTime.now();
  List<String> _cars = <String>['Fabia 1', 'BMW 3'];
  Map<String, Car> _carsMap;
  Car _selectedCar;


  Widget calendar(double width, double height) {
    _carsMap = new Map<String,Car>();
    _cars.forEach((car) {
      _carsMap.putIfAbsent(car, () {return new Car(car, (Random().nextDouble()*1000), []);});
    });

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.0),
      child: CalendarCarousel(
        dayPadding: 1.0,
        width: width,
        height: height,
        weekDays: ["Po", "Út", "St", "Čt", "Pá", "So", "Ne"],
        onDayPressed: (DateTime date) {
          setState(() {
            if (date.compareTo(DateTime.now()) > 0) {
              _selectedDate = date;
            }
          });
        },
        thisMonthDayBorderColor: Colors.grey,
        todayBorderColor: Colors.greenAccent,
        todayButtonColor: Colors.blueAccent,
        selectedDateTime: _selectedDate,
        daysHaveCircularBorder: null,

        /// null for not rendering any border, true for circular border, false for rectangular border
        //          weekendStyle: TextStyle(
        //            color: Colors.red,
        //          ),
        //          weekDays: null, /// for pass null when you do not want to render weekDays
        //          headerText: Container( /// Example for rendering custom header
        //            child: Text('Custom Header'),
        //          ),
      ),
    );
  }

  Widget renderDateReservation(DateTime date) {
    if (_selectedCar == null) {
      _selectedCar = _carsMap[_cars[0]];
    }
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Text('Vyberte vozidlo:'),
            ),
            DropdownButton<String>(
              hint: Text(_selectedCar.name),
              items: _cars.map((String value) {
                return new DropdownMenuItem<String>(
                  value: value,
                  child: new Text(value),
                );
              }).toList(),
              onChanged: (car) {
                setState(() {
                  _selectedCar = _carsMap[car];
                });
              },
            ),
            Text(' za ${_selectedCar.dayPrice.toStringAsPrecision(5).split('.')[0]} Kč na den'),
          ],
        ),
        Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
            child: SizedBox(
              height: 55.0,
              child: MaterialButton(
                elevation: 25.0,
                color: Colors.green,
                textColor: Colors.white,
                onPressed: () {
                  FirebaseAuth.instance.currentUser().then((user) {
                    Firestore.instance.collection('rent').document()
                            .setData({ 'date': _selectedDate, 'user': user.email, 'car': _selectedCar.name});
                  });
                  //
                  //
                },
                child: Center(
                  child: Row(
                    children: <Widget>[
                      Center(
                          child: Row(
                        children: <Widget>[
                          Padding(
                            child: Icon(Icons.directions_car),
                            padding: EdgeInsets.only(left: 16.0, right: 10.0),
                          ),
                          Text(
                              'Objednat ${_selectedCar.name} na ${DateFormat.yMMMMd('cs').format(_selectedDate)}')
                        ],
                      )),
                    ],
                  ),
                ),
              ),
            )),
      ],
    );
  }

  void _showDialog() {
    // flutter defined function
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: Text("Tuto akci nejde vzít zpět"),
          content: Text("Opravdu se chcete odhlásit?"),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            FlatButton(
              textColor: Colors.red,
              child: Text("Ano 😢"),
              onPressed: () {
                FirebaseAuth.instance.signOut();
                Route route =
                    MaterialPageRoute(builder: (context) => MyHomePage());
                Navigator.pushReplacement(context, route);
              },
            ),
            FlatButton(
              child: Text('NE!'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: Colors.white,
        title: Text(
          'Rezervator',
          style: Theme.of(context).textTheme.headline,
        ),
        centerTitle: true,
        actions: <Widget>[
          // overflow menu
          IconButton(
            color: Colors.black,
            icon: Icon(Icons.sentiment_dissatisfied),
            tooltip: 'Odhlásit se',
            onPressed: () {
              _showDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          calendar(MediaQuery.of(context).size.width,
              MediaQuery.of(context).size.height / 1.75),
          renderDateReservation(_selectedDate),
        ],
      ),
    );
  }
}
