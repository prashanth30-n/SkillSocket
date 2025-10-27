//import 'package:barter_system/login.dart';
import 'package:barter_system/splashscreen.dart'; // import the new splash page
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) { 
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SkillSocket',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        primaryColor: const Color.fromARGB(255, 177, 66, 116),
      ),
      home: const LoadingPage(), // changed from LoginScreen to LoadingPage
    );
  }
}     
