import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:project_management/services/auth_service.dart';
import 'package:project_management/views/auth/login_screen.dart';

class Registerpage extends StatefulWidget {
  const Registerpage({super.key});

  @override
  State<Registerpage> createState() => _RegisterpageState();
}

class _RegisterpageState extends State<Registerpage> {
  final TextEditingController _firstnameController = TextEditingController();
  final TextEditingController _lastnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmpasswordController =
      TextEditingController();

  // FocusNodes to detect when user taps the fields
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  // Visibility control
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  // Eye icon visibility
  bool _showPasswordEye = false;
  bool _showConfirmPasswordEye = false;

  // Password rule booleans
  bool _hasUpper = false;
  bool _hasLower = false;
  bool _hasDigit = false;
  bool _hasSymbol = false;
  bool _hasMinLength = false;

  // Confirm password match
  bool _passwordsMatch = true;

  bool _isPasswordValid = false;

  // ***** NEW: Register Button Active State *****
  bool _isRegisterButtonActive = false;

  // SHOW / HIDE UI FLAGS
  bool _showPasswordRules = false;
  bool _showPasswordMatchText = false;

  @override
  void initState() {
    super.initState();

    _passwordFocus.addListener(() {
      setState(() {
        _showPasswordEye = _passwordFocus.hasFocus;
      });
    });

    _confirmPasswordFocus.addListener(() {
      setState(() {
        _showConfirmPasswordEye = _confirmPasswordFocus.hasFocus;
      });
    });

    // ***** NEW: Listen to all fields *****
    _firstnameController.addListener(_updateRegisterButtonState);
    _lastnameController.addListener(_updateRegisterButtonState);
    _emailController.addListener(_updateRegisterButtonState);
    _passwordController.addListener(_updateRegisterButtonState);
    _confirmpasswordController.addListener(_updateRegisterButtonState);
  }

  // ***** NEW: ENABLE/DISABLE REGISTER BUTTON *****
  void _updateRegisterButtonState() {
    setState(() {
      _isRegisterButtonActive =
          _firstnameController.text.isNotEmpty &&
          _lastnameController.text.isNotEmpty &&
          _emailController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty &&
          _confirmpasswordController.text.isNotEmpty &&
          _isPasswordValid &&
          _passwordsMatch;
    });
  }

  // VALIDATE PASSWORD RULES
  void _validatePassword(String password) {
    setState(() {
      _showPasswordRules = true; // ✅ REQUIRED

      _hasUpper = password.contains(RegExp(r'[A-Z]'));
      _hasLower = password.contains(RegExp(r'[a-z]'));
      _hasDigit = password.contains(RegExp(r'[0-9]'));
      _hasSymbol = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
      _hasMinLength = password.length >= 6;

      _isPasswordValid =
          _hasUpper && _hasLower && _hasDigit && _hasSymbol && _hasMinLength;

      _passwordsMatch = password == _confirmpasswordController.text;
      _showPasswordMatchText = true;
    });

    _updateRegisterButtonState();
  }

  // RULE BUILDER FOR GREEN/RED CHECKMARK
  Widget _buildRule(String text, bool condition) {
    return Row(
      children: [
        Icon(
          condition ? Icons.check_circle : Icons.cancel,
          color: condition ? Colors.greenAccent : Colors.redAccent,
          size: 18,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: condition ? Colors.greenAccent : Colors.redAccent,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
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
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 180),

                          // FIRST NAME
                          _buildTextField(
                            controller: _firstnameController,
                            hint: 'First Name',
                          ),
                          const SizedBox(height: 20),

                          // LAST NAME
                          _buildTextField(
                            controller: _lastnameController,
                            hint: 'Last Name',
                          ),
                          const SizedBox(height: 20),

                          // EMAIL
                          _buildTextField(
                            controller: _emailController,
                            hint: 'Email ID',
                          ),
                          const SizedBox(height: 20),

                          // PASSWORD FIELD
                          _buildTextField(
                            controller: _passwordController,
                            hint: 'Password',
                            obscureText: !_passwordVisible,
                            focusNode: _passwordFocus,
                            onChanged: (value) {
                              _validatePassword(value);

                              _passwordsMatch =
                                  value == _confirmpasswordController.text;

                              _showPasswordEye =
                                  value.isNotEmpty || _passwordFocus.hasFocus;
                            },
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

                          const SizedBox(height: 10),

                          // PASSWORD RULE CHECKLIST
                          if (_showPasswordRules)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildRule(
                                  "At least 6 characters",
                                  _hasMinLength,
                                ),
                                _buildRule("One uppercase letter", _hasUpper),
                                _buildRule("One lowercase letter", _hasLower),
                                _buildRule("One number", _hasDigit),
                                _buildRule("One special symbol", _hasSymbol),
                              ],
                            ),

                          const SizedBox(height: 20),

                          // CONFIRM PASSWORD FIELD
                          _buildTextField(
                            controller: _confirmpasswordController,
                            hint: 'Confirm Password',
                            obscureText: !_confirmPasswordVisible,
                            focusNode: _confirmPasswordFocus,
                            onChanged: (value) {
                              setState(() {
                                _passwordsMatch =
                                    value == _passwordController.text;

                                _showConfirmPasswordEye =
                                    value.isNotEmpty ||
                                    _confirmPasswordFocus.hasFocus;
                              });

                              _updateRegisterButtonState(); // ***** NEW *****
                            },
                            suffixIcon:
                                _showConfirmPasswordEye
                                    ? IconButton(
                                      icon: Icon(
                                        _confirmPasswordVisible
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                        color: Colors.white,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _confirmPasswordVisible =
                                              !_confirmPasswordVisible;
                                        });
                                      },
                                    )
                                    : null,
                          ),

                          // PASSWORD MATCH MESSAGE
                          if (_showPasswordMatchText)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _passwordsMatch
                                    ? "Passwords match "
                                    : "Passwords do not match ",
                                style: TextStyle(
                                  color:
                                      _passwordsMatch
                                          ? Colors.greenAccent
                                          : Colors.redAccent,
                                  fontSize: 14,
                                ),
                              ),
                            ),

                          const SizedBox(height: 30),

                          // ***** REGISTER BUTTON WITH DISABLED LOGIC *****
                          SizedBox(
                            width: 150,
                            height: 50,
                            child: ElevatedButton(
                              onPressed:
                                  _isRegisterButtonActive
                                      ? () async {
                                        try {
                                          final result = await AuthService()
                                              .register(
                                                firstName:
                                                    _firstnameController.text
                                                        .trim(),
                                                lastName:
                                                    _lastnameController.text
                                                        .trim(),
                                                email:
                                                    _emailController.text
                                                        .trim(),
                                                password:
                                                    _passwordController.text
                                                        .trim(),
                                              );

                                          if (result['success'] == true) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "Registration successful",
                                                ),
                                                backgroundColor: Colors.green,
                                              ),
                                            );

                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (_) => const LoginPage(),
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  result['message'] ??
                                                      "Registration failed",
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                "Error: ${e.toString()}",
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                      : null,

                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(
                                  0xFFE5A72E,
                                ), // ACTIVE COLOR
                                disabledBackgroundColor: const Color.fromARGB(
                                  255,
                                  98,
                                  96,
                                  96,
                                ), // DISABLED COLOR
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 5,
                              ),

                              child: const Text(
                                'Register',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 15),

                          // Already Have an Account? Login
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Already Have an Account? ',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LoginPage(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Login',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
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

                    Positioned(
                      top: 30,
                      child: Image.asset(
                        'assets/images/Login.png',
                        height: 140,
                        width: 300,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // UPDATED TEXT FIELD BUILDER
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool obscureText = false,
    Function(String)? onChanged,
    Widget? suffixIcon,
    FocusNode? focusNode,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.5),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white70),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white, fontSize: 16),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 25,
            vertical: 18,
          ),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}
