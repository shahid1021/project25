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
    final firstName = prefs.getString("firstName") ?? "Student";
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
      "firstName": "Student",
      "lastName": "",
      "name": "Student",
      "status": "Active",
    };
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
                          '${user['firstName'] ?? 'Student'} ${user['lastName'] ?? ''}'
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
                                  value: user['role'] ?? 'Student',
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
                  // Only clear auth-related data
                  await prefs.remove('token');
                  await prefs.remove('email');
                  await prefs.remove('studentName');

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

// ================= PROFILE SCREEN (Menu) =================
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(top: 15, left: 15),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black, size: 30),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(left: 0, top: 15),
          child: const Text(
            "Menu",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 30,
            ),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(padding: EdgeInsets.all(16.0)),
              Container(
                child: Column(
                  children: [
                    _buildBoxItem(
                      icon: Icons.share_outlined,
                      title: 'Share',
                      onTap: _shareApp,
                    ),
                    const SizedBox(height: 10),
                    _buildBoxItem(
                      icon: Icons.info_outline,
                      title: 'About',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AboutPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildBoxItem(
                      icon: Icons.help_outline,
                      title: 'Help',
                      onTap: _sendEmail,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBoxItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFE5A72E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8D89A)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Colors.black87),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
