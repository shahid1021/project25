import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_management/views/auth/login_screen.dart';
import 'package:project_management/config/api_config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:project_management/views/students/about_page.dart';

// ================= FETCH PROFILE =================
Future<Map<String, dynamic>> fetchProfile() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString("email");
    final firstName = prefs.getString("firstName") ?? "Teacher";
    final lastName = prefs.getString("lastName") ?? "";

    if (email == null || email.isEmpty) {
      return {
        "email": "user@example.com",
        "firstName": firstName,
        "lastName": lastName,
        "name": "$firstName $lastName".trim(),
        "status": "Active",
      };
    }

    final response = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/User/me?email=$email'),
          headers: {'Content-Type': 'application/json'},
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      // Return default data if API fails
      return {
        "email": email,
        "firstName": firstName,
        "lastName": lastName,
        "name": "$firstName $lastName".trim(),
        "status": "Active",
      };
    }
  } catch (e) {
    print('Error fetching profile: $e');
    // Return mock data on error
    return {
      "email": "user@example.com",
      "firstName": "Teacher",
      "lastName": "",
      "name": "Teacher",
      "status": "Active",
    };
  }
}

// ================= TEACHER PROFILE =================
class TeacherProfile extends StatefulWidget {
  const TeacherProfile({super.key});

  @override
  State<TeacherProfile> createState() => _TeacherProfileState();
}

class _TeacherProfileState extends State<TeacherProfile> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFE5A72E),
        elevation: 0,
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert, color: Colors.black, size: 26),
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    child: Row(
                      children: [
                        const Icon(Icons.share_outlined, color: Colors.black),
                        const SizedBox(width: 0),
                        const Text('Share'),
                      ],
                    ),
                    onTap: () => _shareApp(),
                  ),
                  PopupMenuItem(
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.black),
                        const SizedBox(width: 12),
                        const Text('About'),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AboutPage(),
                        ),
                      );
                    },
                  ),
                  PopupMenuItem(
                    child: Row(
                      children: [
                        const Icon(Icons.help_outline, color: Colors.black),
                        const SizedBox(width: 12),
                        const Text('Help'),
                      ],
                    ),
                    onTap: () => _sendEmail(),
                  ),
                ],
          ),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder(
          future: fetchProfile(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    const Text('Error loading profile'),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text('No profile data available'),
                  ],
                ),
              );
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
                          '${user['firstName'] ?? 'Teacher'} ${user['lastName'] ?? ''}'
                              .trim(),
                          style: TextStyle(
                            fontSize: width * 0.06,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: height * 0.005),

                        // ===== EMAIL =====
                        Text(
                          user['email'] ?? 'user@example.com',
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
                                  value: user['role'] ?? 'Teacher',
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
    required dynamic value,
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
                  (value ?? '').toString(),
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
                  // Only clear auth-related data, keep projects
                  await prefs.remove('token');
                  await prefs.remove('email');
                  await prefs.remove('studentName');
                  // teacher_projects is preserved for next login

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

  Future<void> _sendEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'smrtlng746@gmail.com',
      queryParameters: {'subject': 'Support - Project Management App'},
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      }
    } catch (e) {
      // Handle error
    }
  }

  void _shareApp() {
    Share.share(
      'Check out the Project Management App! A comprehensive platform to manage and track your projects with AI assistance.',
      subject: 'Project Management App',
    );
  }
}
