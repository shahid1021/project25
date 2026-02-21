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

  void _updateButtonState() {
    setState(() {
      _isButtonActive =
          _emailController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty;
    });
  }

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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Branding
                Text(
                  'PRYXEL',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Project Management App',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.85),
                    fontWeight: FontWeight.w400,
                    letterSpacing: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                // Glassmorphic Login Box
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      width: 380,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 36,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Color(0xFFE5A72E), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 16,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Email
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Color(0xFFE5A72E)),
                            ),
                            child: TextField(
                              controller: _emailController,
                              style: TextStyle(
                                color: Color(0xFFE5A72E),
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Email ID',
                                hintStyle: TextStyle(
                                  color: Color(0xFFE5A72E).withOpacity(0.7),
                                  fontSize: 16,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          // Password
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Color(0xFFE5A72E)),
                            ),
                            child: TextField(
                              controller: _passwordController,
                              focusNode: _passwordFocus,
                              obscureText: !_passwordVisible,
                              style: TextStyle(
                                color: Color(0xFFE5A72E),
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Password',
                                hintStyle: TextStyle(
                                  color: Color(0xFFE5A72E).withOpacity(0.7),
                                  fontSize: 16,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _passwordVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: Color(0xFFE5A72E),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _passwordVisible = !_passwordVisible;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
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
                                style: TextStyle(
                                  color: Color(0xFFE5A72E),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed:
                                  _isButtonActive
                                      ? () async {
                                        try {
                                          final result = await AuthService()
                                              .login(
                                                _emailController.text.trim(),
                                                _passwordController.text.trim(),
                                              );
                                          if (result == "Student") {
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (_) => MainNavigation(),
                                              ),
                                            );
                                          } else if (result == "Teacher") {
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (_) => NavigationPage(),
                                              ),
                                            );
                                          } else if (result == "Admin") {
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (_) => const AdminPanel(),
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
                                          } else if (result ==
                                              "wrong_password") {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "Incorrect password",
                                                ),
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
                                                            () => Navigator.pop(
                                                              ctx,
                                                            ),
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
                                        } catch (e) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text("Error: $e"),
                                            ),
                                          );
                                        }
                                      }
                                      : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    _isButtonActive
                                        ? Color(0xFFE5A72E)
                                        : Colors.grey.shade300,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey.shade300,
                                disabledForegroundColor: Colors.white70,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  side: BorderSide(
                                    color: Color(0xFFE5A72E),
                                    width: 2,
                                  ),
                                ),
                              ),
                              child: const Text(
                                "Sign in",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Register
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don’t have an account? ",
                                style: TextStyle(
                                  color: Color(0xFFE5A72E),
                                  fontWeight: FontWeight.w500,
                                ),
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
                                    color: Color(0xFFE5A72E),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
