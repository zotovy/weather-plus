import 'package:flutter/material.dart';
import 'package:weather_app/today.dart';

main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'SF-Pro-Display',
        accentColor: Colors.black12,
      ),
      title: 'Weather+',
      home: TodayPage(),
    );
  }
}
