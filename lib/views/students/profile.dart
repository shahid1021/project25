import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_management/views/auth/login_screen.dart';
import 'package:project_management/config/api_config.dart';

// ================= FETCH PROFILE =================
Future<Map<String, dynamic>> fetchProfile() async {
  final prefs = await SharedPreferences.getInstance();
  final email = prefs.getString("email");

  final response = await http.get(
    Uri.parse('${ApiConfig.baseUrl}/User/me?email=$email'),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception("Failed to load profile");
  }
}

// ================= STUDENT PROFILE =================
class StudentProfile extends StatefulWidget {
  const StudentProfile({super.key});

  @override
  State<StudentProfile> createState() => _StudentProfileState();
}

class _StudentProfileState extends State<StudentProfile> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder(
          future: fetchProfile(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData) {
              return const Center(child: Text('Failed to load profile'));
            }

            final user = snapshot.data as Map<String, dynamic>;

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // ===== HEADER =====
                        Stack(
                          alignment: Alignment.bottomCenter,
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              height: height * 0.25,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE5A72E),
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.elliptical(509, 230),
                                  bottomRight: Radius.elliptical(509, 230),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: -height * 0.06,
                              child: Container(
                                padding: EdgeInsets.all(width * 0.01),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: width * 0.11,
                                  backgroundColor: Colors.white,
                                  child: Icon(
                                    Icons.person,
                                    size: width * 0.18,
                                    color: const Color(0xFFE5A72E),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: height * 0.08),

                        // ===== NAME =====
                        Text(
                          user['name'],
                          style: TextStyle(
                            fontSize: width * 0.06,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: height * 0.005),

                        // ===== EMAIL =====
                        Text(
                          user['email'],
                          style: TextStyle(
                            fontSize: width * 0.035,
                            color: Colors.black54,
                          ),
                        ),

                        SizedBox(height: height * 0.04),

                        // ===== INFO CARD =====
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: width * 0.07,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5E6C3),
                              borderRadius: BorderRadius.circular(width * 0.05),
                            ),
                            child: Column(
                              children: [
                                const Divider(height: 1),
                                _buildInfoTile(
                                  icon: Icons.verified_user,
                                  label: 'Role',
                                  value: user['role'],
                                  width: width,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ===== LOGOUT BUTTON =====
                Padding(
                  padding: EdgeInsets.only(
                    left: width * 0.25,
                    right: width * 0.25,
                    bottom: height * 0.05,
                  ),
                  child: SizedBox(
                    height: height * 0.065,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _showLogoutPopup(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE5A72E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(width * 0.04),
                        ),
                      ),
                      child: Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: width * 0.055,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ===== INFO TILE =====
  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required double width,
  }) {
    return Padding(
      padding: EdgeInsets.all(width * 0.04),
      child: Row(
        children: [
          Icon(icon, size: width * 0.06),
          SizedBox(width: width * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: width * 0.03,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: width * 0.01),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: width * 0.045,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== LOGOUT POPUP =====
  void _showLogoutPopup(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Logout"),
            content: const Text("Are you sure you want to logout?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE5A72E),
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (_) => false,
                  );
                },
                child: const Text("Logout"),
              ),
            ],
          ),
    );
  }
}
