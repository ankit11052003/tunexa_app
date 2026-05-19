import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.purple,
    scaffoldBackgroundColor: Colors.black,
  );

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.purple,
    scaffoldBackgroundColor: Colors.white,
  );
}
