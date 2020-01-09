import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geocoder/geocoder.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:http/http.dart' as http;

class TodayPage extends StatefulWidget {
  @override
  _TodayPageState createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  String address = '';
  String dateOfTheWeek = '';
  String time = '';
  String dayTime = '';

  String temp = '';
  String condition = '';
  String icon = '';
  String humidity = '';
  String wind = '';
  String pressure = ' ';

  List<Map<String, dynamic>> forecast = [];
  List<Map<String, dynamic>> hourly = [];

  // Help variables
  String message = '';
  int hourSystem = 0;

  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  _initLocation() async {
    LocationData currentLocation;

    var location = new Location();

    try {
      // Get location
      currentLocation = await location.getLocation();
      double longitude = currentLocation.longitude;
      double latitude = currentLocation.latitude;

      // Correlate cordinates and region
      Coordinates coordinates = new Coordinates(latitude, longitude);
      List<Address> _addresses =
          await Geocoder.local.findAddressesFromCoordinates(coordinates);
      Address firstAddress = _addresses.first;
      String _address = firstAddress.locality;

      if (mounted) {
        setState(() {
          address = _address;
        });
      }
      return {
        'latitude': latitude,
        'longitude': longitude,
      };
    } catch (e) {
      if (e.code == 'PERMISSION_DENIED') {
        _scaffoldKey.currentState.showSnackBar(SnackBar(
          content: Text('Access to geolocation is required.'),
          backgroundColor: Colors.redAccent,
        ));
      }
      currentLocation = null;
      return null;
    }
  }

  _getPartOfTheDay() {
    int hour = TimeOfDay.now().hour;
    String _dayTime;
    if (0 <= hour && hour <= 5) {
      _dayTime = 'night';
    } else if (5 < hour && hour <= 11) {
      _dayTime = 'morning';
    } else if (11 < hour && hour <= 6) {
      _dayTime = 'day';
    } else {
      _dayTime = 'evening';
    }
    return _dayTime;
  }

  _initDate() {
    if (mounted) {
      setState(() {
        dateOfTheWeek =
            DateFormat('EEEE').format(DateTime.now()).substring(0, 3);
        time = DateFormat('Hm').format(DateTime.now());
        dayTime = _getPartOfTheDay();
      });
    }
  }

  _weather() async {
    final coordinates = await _initLocation();
    if (coordinates == null) {
      // Error
      return null;
    }

    //  Init coordinates
    double latitude = coordinates['latitude'];
    double longitude = coordinates['longitude'];

    var response = await http.get(
        'https://api.weather.yandex.ru/v1/forecast?lat=$latitude&lon=$longitude&hour=true&limit=7&extra=true',
        headers: {'X-Yandex-API-Key': 'f5ae353a-943a-4388-a7b5-13dfef3b8db6'});
    Map<String, dynamic> body = jsonDecode(response.body);

    // Init variables
    int _temp = body['fact']['temp'];
    String _condition = body['fact']['condition'].replaceAll('-', ' ');
    String _icon = body['fact']['icon'];
    _condition = _condition[0].toUpperCase() + _condition.substring(1);
    String _humidity = body['fact']['humidity'].toString();
    String _wind = body['fact']['wind_gust'].toString();
    String _pressure = body['fact']['pressure_pa'].toString();

    // Init forecast
    List<Map<String, dynamic>> _forecasts = [];
    for (var i = 0; i < 7; i++) {
      DateTime date = DateTime.parse(body['forecasts'][i]['date']);
      String _dayOfTheWeek = DateFormat('EEEE').format(date);
      String _icon = body['forecasts'][i]['parts']['day_short']['icon'];
      int _temp = body['forecasts'][i]['parts']['day_short']['temp'];
      Map<String, dynamic> data = {
        'dayOfTheWeek': _dayOfTheWeek,
        'icon': _icon,
        'temp': _temp,
      };
      _forecasts.add(data);
    }

    // Init hourly weather
    List<Map<String, dynamic>> _hourly = [];
    for (var i = 0; i < 24; i += 2) {
      String __time = body['forecasts'][0]['hours'][i]['hour'];
      String __icon = body['forecasts'][0]['hours'][i]['icon'];
      int __temp = body['forecasts'][0]['hours'][i]['temp'];
      _hourly.add(
        {
          'time': __time,
          'icon': __icon,
          'temp': __temp,
        },
      );
    }

    // Init helping time (Is current time == _hourly?)
    int _currentHour = DateTime.now().hour;
    if (_currentHour % 2 != 0) {
      _currentHour += 1;
    }

    if (mounted) {
      setState(() {
        temp = _temp.toString();
        condition = _condition;
        icon = _icon;
        humidity = _humidity;
        wind = _wind;
        pressure = _pressure;

        forecast = _forecasts;
        hourly = _hourly;

        message = '200';
        hourSystem = _currentHour;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _initLocation();
    _initDate();
    _weather();
  }

  Widget _buildDetailInfo() {
    double initScrollValue = (hourSystem / 6) * 255;
    ScrollController _scrollController = new ScrollController(
      initialScrollOffset: initScrollValue,
      keepScrollOffset: true,
    );
    return Container(
      margin: EdgeInsets.only(right: 28, left: 28, top: 25),
      padding: EdgeInsets.only(left: 25, right: 25, top: 25),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
        color: Colors.white,
        boxShadow: [
          BoxShadow(offset: Offset(0, 0), blurRadius: 7, color: Colors.black26)
        ],
      ),
      child: Column(
        children: <Widget>[
          Container(
            height: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Container(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        '$humidity%',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Humidity',
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    color: Colors.black38,
                  ),
                ),
                Container(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        '${wind}m/s',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Wind',
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    color: Colors.black38,
                  ),
                ),
                Container(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        '${pressure}mb',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Pressure',
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 15),
            width: double.infinity,
            height: 227,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Change of Temperature',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                Container(
                  margin: EdgeInsets.only(top: 10),
                  width: double.infinity,
                  height: 155,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(
                        hourly.length,
                        (int i) {
                          Map<String, dynamic> currentWeather = hourly[i];
                          bool isCurrentHour =
                              hourSystem.toString() == currentWeather['time'];

                          return Container(
                            margin: EdgeInsets.only(
                                top: isCurrentHour ? 0 : 15,
                                bottom: isCurrentHour ? 15 : 0,
                                right: 15),
                            width: 70,
                            height: 135,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: Colors.blue[200],
                                width: 0.5,
                              ),
                              borderRadius: BorderRadius.circular(100),
                              boxShadow: isCurrentHour
                                  ? [
                                      BoxShadow(
                                        offset: Offset(0, 4),
                                        blurRadius: 5,
                                        color: Color(0xFFDEE9F8),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Container(
                                  margin: EdgeInsets.only(top: 12),
                                  child: Text(
                                    '${currentWeather['time']}:00',
                                    style: TextStyle(
                                      color: Color(0xFF282828),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 45,
                                  height: 45,
                                  padding: EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFFDEE9F8),
                                  ),
                                  child: Center(
                                    child: SvgPicture.network(
                                        'https://yastatic.net/weather/i/icons/blueye/color/svg/${currentWeather['icon']}.svg'),
                                  ),
                                ),
                                Container(
                                  margin: EdgeInsets.only(bottom: 12),
                                  child: Text(
                                    '${currentWeather['temp'].toString()}°',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF282828),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanel() {
    return GestureDetector(
      onPanUpdate: (detail) {
        // detail.globalPosition.dy > 0
      },
      child: Column(children: <Widget>[
        Container(
          margin: EdgeInsets.only(top: 20, bottom: 20),
          width: MediaQuery.of(context).size.width * 0.25,
          height: 3,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            color: Colors.black54,
          ),
        ),
        Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height - 119,
          child: ListView(
            children: List.generate(forecast.length, (int i) {
                  Map<String, dynamic> _forecast = forecast[i];

                  // Unpack
                  String _day = _forecast['dayOfTheWeek'];
                  String _icon = _forecast['icon'];
                  String _temp = _forecast['temp'].toString();

                  // Is Today?
                  if (_day == DateFormat('EEEE').format(DateTime.now())) {
                    _day = 'Today';
                  }

                  return Container(
                    height: 35,
                    // color: Colors.redAccent,
                    margin: EdgeInsets.only(top: 10),
                    padding: EdgeInsets.symmetric(horizontal: 28),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          _day,
                          style: TextStyle(
                            color: Color(0xFF323232),
                            fontSize: 20,
                          ),
                        ),
                        Container(
                          width: 100,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              _icon == ''
                                  ? SizedBox(width: 20)
                                  : SvgPicture.network(
                                      'https://yastatic.net/weather/i/icons/blueye/color/svg/$_icon.svg'),
                              SizedBox(width: 15),
                              Text(
                                _temp + '°',
                                style: TextStyle(
                                  color: Color(0xFF5C99D7),
                                  fontSize: 22,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }) +
                [_buildDetailInfo()],
          ),
        )
      ]),
    );
  }

  Widget _buildBody() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black12,
        image: DecorationImage(
          image: AssetImage('assets/illustrations/day.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        children: <Widget>[
          // Up Row
          Container(
            padding: EdgeInsets.symmetric(vertical: 35),
            height: 124,
            child: Row(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            address,
                            style: TextStyle(
                              color: Colors.white,
                              // fontWeight: FontWeight.w600,
                              fontSize: 28,
                              shadows: [
                                Shadow(
                                  color: Colors.black12,
                                  offset: Offset(1, 2),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '$dateOfTheWeek, $time',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              shadows: [
                                Shadow(
                                  color: Colors.black12,
                                  offset: Offset(1, 2),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Center
          Container(
            height: MediaQuery.of(context).size.height * 0.87 - 124,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 124),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      condition,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        shadows: [
                          Shadow(
                            color: Colors.black12,
                            offset: Offset(1, 2),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '$temp°',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 72,
                        shadows: [
                          Shadow(
                            color: Colors.black12,
                            offset: Offset(1, 2),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget widget;
    if (message == '200') {
      widget = SlidingUpPanel(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
        minHeight: MediaQuery.of(context).size.height * 0.13,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        panel: _buildPanel(),
        body: _buildBody(),
      );
    } else if (message == '403') {
      widget = Center(
        child:
            Text("Sorry, we can't load data:( Exceeded the number of requests"),
      );
    } else {
      widget = Center(
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/launcher/icon.png'),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      key: _scaffoldKey,
      body: widget,
    );
  }
}
