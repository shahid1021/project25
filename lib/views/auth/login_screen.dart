import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:project_management/services/auth_service.dart';
import 'package:project_management/views/auth/navigation.dart';
import 'package:project_management/views/auth/register.dart';
import 'package:project_management/views/auth/forgot_password.dart';
import 'package:project_management/views/students/home_screen.dart';
import 'package:project_management/views/teacher/home.dart';
import 'package:project_management/views/teacher/nav.dart';
import 'package:project_management/views/admin/admin_panel.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _passwordFocus = FocusNode();

  bool _passwordVisible = false;
  bool _showPasswordEye = false; // Show eye only when clicked

  bool _isButtonActive = false;

  @override
  void initState() {
    super.initState();

    _emailController.addListener(_updateButtonState);
    _passwordController.addListener(_updateButtonState);

    // When user clicks the password field → eye appears
    _passwordFocus.addListener(() {
      setState(() {
        _showPasswordEye = _passwordFocus.hasFocus;
      });
    });
  }

  void _updateButtonState() {
    setState(() {
      _isButtonActive =
          _emailController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty;
    });
    print("Button Active: $_isButtonActive");

    // Show eye if the user typed something
    if (_passwordController.text.isNotEmpty) {
      setState(() {
        _showPasswordEye = true;
      });
    } else {
      // Hide eye if empty AND not focused
      if (!_passwordFocus.hasFocus) {
        setState(() {
          _showPasswordEye = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/loginimg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            color: Colors.black.withOpacity(0.3),
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/Login.png',
                        height: 140,
                        width: 300,
                        fit: BoxFit.contain,
                      ),

                      const SizedBox(height: 40),

                      // EMAIL
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white),
                        ),
                        child: TextField(
                          controller: _emailController,
                          style: TextStyle(color: Colors.white70),
                          decoration: InputDecoration(
                            hintText: 'Email ID',
                            hintStyle: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 25,
                              vertical: 18,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // PASSWORD (EYE SHOWS ONLY WHEN CLICKED)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white),
                        ),
                        child: TextField(
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          obscureText: !_passwordVisible,
                          style: TextStyle(color: Colors.white70),
                          decoration: InputDecoration(
                            hintText: 'Password',
                            hintStyle: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 25,
                              vertical: 18,
                            ),

                            // Eye icon appears only when focused or typing
                            suffixIcon:
                                _showPasswordEye
                                    ? IconButton(
                                      icon: Icon(
                                        _passwordVisible
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                        color: Colors.white,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _passwordVisible = !_passwordVisible;
                                        });
                                      },
                                    )
                                    : null,
                          ),
                        ),
                      ),

                      // FORGOT PASSWORD
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordPage(),
                              ),
                            );
                          },
                          child: Text(
                            'Forgot password?',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // LOGIN BUTTON (DISABLED)
                      SizedBox(
                        width: 200,
                        height: 50,
                        child: ElevatedButton(
                          // onPressed:
                          //     _isButtonActive
                          //         ? () async {
                          //           try {
                          //             String result = await AuthService().login(
                          //               _emailController.text.trim(),
                          //               _passwordController.text.trim(),
                          //             );

                          //             if (result == "Student") {
                          //               Navigator.pushReplacement(
                          //                 context,
                          //                 MaterialPageRoute(
                          //                   builder: (_) => MainNavigation(),
                          //                 ),
                          //               );
                          //             } else if (result == "Teacher") {
                          //               Navigator.pushReplacement(
                          //                 context,
                          //                 MaterialPageRoute(
                          //                   builder: (_) => NavigationPage(),
                          //                 ),
                          //               );
                          //             } else if (result == "no_account") {
                          //               ScaffoldMessenger.of(
                          //                 context,
                          //               ).showSnackBar(
                          //                 SnackBar(
                          //                   content: Text(
                          //                     "Please register first",
                          //                   ),
                          //                 ),
                          //               );
                          //             } else if (result == "wrong_password") {
                          //               ScaffoldMessenger.of(
                          //                 context,
                          //               ).showSnackBar(
                          //                 SnackBar(
                          //                   content: Text("Incorrect password"),
                          //                 ),
                          //               );
                          //             } else {
                          //               ScaffoldMessenger.of(
                          //                 context,
                          //               ).showSnackBar(
                          //                 SnackBar(
                          //                   content: Text("Login failed"),
                          //                 ),
                          //               );
                          //             }
                          //           } catch (e) {
                          //             ScaffoldMessenger.of(
                          //               context,
                          //             ).showSnackBar(
                          //               SnackBar(
                          //                 content: Text(
                          //                   "An error occurred: $e",
                          //                 ),
                          //               ),
                          //             );
                          //           }
                          //         }
                          //         : null,
                          onPressed:
                              _isButtonActive
                                  ? () async {
                                    print('LOGIN BUTTON CLICKED');

                                    try {
                                      print('CALLING LOGIN API...');
                                      final result = await AuthService().login(
                                        _emailController.text.trim(),
                                        _passwordController.text.trim(),
                                      );
                                      print('LOGIN RESULT => $result');

                                      if (result == "Student") {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => MainNavigation(),
                                          ),
                                        );
                                      } else if (result == "Teacher") {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => NavigationPage(),
                                          ),
                                        );
                                      } else if (result == "Admin") {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const AdminPanel(),
                                          ),
                                        );
                                      } else if (result == "no_account") {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Please register first",
                                            ),
                                          ),
                                        );
                                      } else if (result == "wrong_password") {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text("Incorrect password"),
                                          ),
                                        );
                                      } else if (result == "blocked") {
                                        showDialog(
                                          context: context,
                                          builder:
                                              (ctx) => AlertDialog(
                                                title: const Row(
                                                  children: [
                                                    Icon(
                                                      Icons.block,
                                                      color: Colors.red,
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text('Access Blocked'),
                                                  ],
                                                ),
                                                content: const Text(
                                                  'Your account has been blocked by the admin. Please contact the administrator for further assistance.',
                                                ),
                                                actions: [
                                                  ElevatedButton(
                                                    style:
                                                        ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors.red,
                                                          foregroundColor:
                                                              Colors.white,
                                                        ),
                                                    onPressed:
                                                        () =>
                                                            Navigator.pop(ctx),
                                                    child: const Text('OK'),
                                                  ),
                                                ],
                                              ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text("Login failed"),
                                          ),
                                        );
                                      }
                                    } catch (e, s) {
                                      print('LOGIN EXCEPTION => $e');
                                      print(s);

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text("Error: $e")),
                                      );
                                    }
                                  }
                                  : null,

                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isButtonActive
                                    ? Color(0xFFE5A72E)
                                    : Colors.grey,
                            foregroundColor: Colors.black,
                            disabledBackgroundColor: Colors.grey,
                            disabledForegroundColor: Colors.white70,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),

                          child: const Text(
                            "Log In",
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // GO TO REGISTER PAGE
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don’t have an account? ",
                            style: TextStyle(color: Colors.white70),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => Registerpage(),
                                ),
                              );
                            },
                            child: Text(
                              "Register",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }
}
