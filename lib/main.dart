import 'package:flutter/material.dart';
import 'package:project_management/views/auth/splash_screen.dart';
import 'package:project_management/views/students/home_screen.dart';
import 'package:project_management/views/students/profile.dart';
import 'package:project_management/views/students/projects.dart';
import 'package:project_management/views/teacher/pfp.dart';
import 'package:project_management/views/teacher/upload.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Project',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: SplashScreen(),
    );
  }
}
