import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// THE FIX: It knows its new family name now! Yay!
import 'package:sports_app/features/pose_detector/screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SAI Talent Assessment',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          color: Colors.transparent,
          elevation: 0,
        ),
        textTheme: GoogleFonts.firaCodeTextTheme(
          Theme.of(context).textTheme.apply(
                bodyColor: Colors.white,
                displayColor: Colors.white,
              ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

