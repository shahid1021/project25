import 'package:project_management/views/auth/login_screen.dart';
import 'package:project_management/views/auth/navigation.dart';
import 'package:project_management/views/teacher/nav.dart';
import 'package:project_management/views/admin/admin_panel.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Check login status after 3 seconds
    Timer(const Duration(seconds: 3), () {
      _checkLoginStatus();
    });
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final role = prefs.getString('role');

    if (token != null && token.isNotEmpty) {
      // User is logged in, navigate based on role
      if (role == 'Student') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      } else if (role == 'Teacher') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const NavigationPage()),
        );
      } else if (role == 'Admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminPanel()),
        );
      } else {
        // Unknown role, go to login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } else {
      // Not logged in, go to login page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // ✅ Gradient background
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 109, 90, 22), // dark blue-black
              Color(0xFF493D13), // deep teal
              Color.fromARGB(255, 53, 44, 13), // deep teal

              Color.fromARGB(255, 0, 0, 0),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 200,
                child: Image.asset(
                  'assets/images/Login.png',
                  height: 120,
                  width: 300,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 5),
              Image.asset(
                'assets/images/name.png',
                width: 220,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
