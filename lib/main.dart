import 'package:job_seeker_app/Screens/Login_screen.dart';
import 'package:job_seeker_app/Screens/home_page.dart';
import 'package:job_seeker_app/Screens/notification.dart';
import 'package:job_seeker_app/Screens/post_job_screen.dart';
import 'package:job_seeker_app/screens/available_duties_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'Screens/Login_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const LoginScreen(),
    );
  }
}