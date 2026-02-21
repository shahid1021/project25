import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:project_management/services/auth_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final AuthService _authService = AuthService();

  int _currentStep = 0; // 0 = email, 1 = OTP, 2 = new password
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _savedEmail = '';
  String _savedOtp = '';

  // ========== STEP 1: Send OTP ==========
  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnackBar('Please enter your email', Colors.redAccent);
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.forgotPassword(email);

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      _savedEmail = email;
      setState(() => _currentStep = 1);
      _showSnackBar(
        'OTP sent to $email',
        const Color.fromARGB(255, 231, 185, 20),
      );
    } else {
      _showSnackBar(
        result['message'] ?? 'Failed to send OTP',
        Colors.redAccent,
      );
    }
  }

  // ========== STEP 2: Verify OTP ==========
  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty || otp.length != 6) {
      _showSnackBar('Please enter the 6-digit OTP', Colors.redAccent);
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.verifyOtp(_savedEmail, otp);

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      _savedOtp = otp;
      setState(() => _currentStep = 2);
      _showSnackBar('OTP verified!', Colors.green);
    } else {
      _showSnackBar(result['message'] ?? 'Invalid OTP', Colors.redAccent);
    }
  }

  // ========== STEP 3: Reset Password ==========
  Future<void> _resetPassword() async {
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (password.isEmpty) {
      _showSnackBar('Please enter a new password', Colors.redAccent);
      return;
    }
    if (password.length < 6) {
      _showSnackBar('Password must be at least 6 characters', Colors.redAccent);
      return;
    }
    if (password != confirm) {
      _showSnackBar('Passwords do not match', Colors.redAccent);
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.resetPassword(
      _savedEmail,
      _savedOtp,
      password,
    );

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      _showSnackBar('Password reset successful!', Colors.green);
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.pop(context);
    } else {
      _showSnackBar(
        result['message'] ?? 'Failed to reset password',
        Colors.redAccent,
      );
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  // ========== BUILD STEP CONTENT ==========
  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isActive = index <= _currentStep;
        return Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    isActive
                        ? const Color.fromARGB(255, 231, 185, 20)
                        : Colors.white24,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.white54,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            if (index < 2)
              Container(
                width: 40,
                height: 2,
                color:
                    index < _currentStep
                        ? const Color.fromARGB(255, 231, 185, 20)
                        : Colors.white24,
              ),
          ],
        );
      }),
    );
  }

  Widget _buildEmailStep() {
    return Column(
      children: [
        const Text(
          'Enter your registered email',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 30),
        _buildTextField(_emailController, 'Email', Icons.email_outlined),
        const SizedBox(height: 30),
        _buildActionButton('Send OTP', _sendOtp),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      children: [
        Text(
          'Enter the 6-digit code sent to\n$_savedEmail',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 30),
        _buildTextField(
          _otpController,
          'Enter OTP',
          Icons.lock_clock_outlined,
          keyboardType: TextInputType.number,
          maxLength: 6,
        ),
        const SizedBox(height: 15),
        GestureDetector(
          onTap: _isLoading ? null : _sendOtp,
          child: const Text(
            'Resend OTP',
            style: TextStyle(
              color: Color.fromARGB(255, 231, 185, 20),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
              decorationColor: Color.fromARGB(255, 231, 185, 20),
            ),
          ),
        ),
        const SizedBox(height: 25),
        _buildActionButton('Verify OTP', _verifyOtp),
      ],
    );
  }

  Widget _buildNewPasswordStep() {
    return Column(
      children: [
        const Text(
          'Create your new password',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 30),
        _buildPasswordField(
          _passwordController,
          'New Password',
          _obscurePassword,
          () {
            setState(() => _obscurePassword = !_obscurePassword);
          },
        ),
        const SizedBox(height: 15),
        _buildPasswordField(
          _confirmPasswordController,
          'Confirm Password',
          _obscureConfirm,
          () {
            setState(() => _obscureConfirm = !_obscureConfirm);
          },
        ),
        const SizedBox(height: 30),
        _buildActionButton('Reset Password', _resetPassword),
      ],
    );
  }

  // ========== REUSABLE WIDGETS ==========
  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.emailAddress,
    int? maxLength,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.5),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLength: maxLength,
        style: TextStyle(
          color: Colors.white70,
          letterSpacing: maxLength != null ? 8 : 0,
        ),
        textAlign: maxLength != null ? TextAlign.center : TextAlign.start,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white, fontSize: 16),
          border: InputBorder.none,
          counterText: '',
          prefixIcon: Icon(icon, color: Colors.white70),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 25,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(
    TextEditingController controller,
    String hint,
    bool obscure,
    VoidCallback toggleObscure,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.5),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white70),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white, fontSize: 16),
          border: InputBorder.none,
          prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off : Icons.visibility,
              color: Colors.white70,
            ),
            onPressed: toggleObscure,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 25,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: 200,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 231, 185, 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child:
            _isLoading
                ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
                : Text(
                  text,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
      ),
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
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Image.asset(
                      'assets/images/Login.png',
                      height: 120,
                      width: 300,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 25),

                    const Text(
                      'Forgot Password',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Step indicator
                    _buildStepIndicator(),
                    const SizedBox(height: 25),

                    // Step content
                    if (_currentStep == 0) _buildEmailStep(),
                    if (_currentStep == 1) _buildOtpStep(),
                    if (_currentStep == 2) _buildNewPasswordStep(),

                    const SizedBox(height: 30),

                    GestureDetector(
                      onTap: () {
                        if (_currentStep > 0) {
                          setState(() => _currentStep--);
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      child: Text(
                        _currentStep > 0 ? '← Go Back' : 'Back to Login',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
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

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
