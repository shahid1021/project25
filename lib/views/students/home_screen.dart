import 'package:google_fonts/google_fonts.dart';
import 'package:project_management/views/students/chat.dart';
import 'package:project_management/views/students/dfd.dart';
import 'package:project_management/views/students/profile.dart';
import 'package:project_management/views/students/upload_files_page.dart';
import 'package:project_management/views/students/trending_projects.dart';
import 'package:project_management/views/students/student_notifications.dart';
import 'package:project_management/config/api_config.dart';
import 'package:project_management/services/background_message_checker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StudentHome extends StatefulWidget {
  final Function(int)? onNavigate;
  const StudentHome({super.key, this.onNavigate});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  String studentName = '';
  int unreadMessageCount = 0;

  @override
  void initState() {
    super.initState();
    loadStudentName();
    checkForNewMessages();
    // Start background message checker
    BackgroundMessageChecker.startPeriodicCheck();
  }

  Future<void> loadStudentName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      studentName = prefs.getString('studentName') ?? '';
    });
  }

  Future<void> checkForNewMessages() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/notifications/get'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final count = (data['notifications'] as List?)?.length ?? 0;
        final prefs = await SharedPreferences.getInstance();
        final lastSeenCount = prefs.getInt('lastSeenMessageCount') ?? 0;

        if (count > lastSeenCount) {
          setState(() {
            unreadMessageCount = count - lastSeenCount;
          });
        }
      }
    } catch (e) {
      print('Error checking messages: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.only(left: 10, top: 15),
          child: Text(
            studentName.isEmpty ? 'Hey!' : 'Hey, $studentName!',

            style: GoogleFonts.poppins(
              textStyle: const TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10, top: 8),
            child: Stack(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_rounded,
                    color: Colors.black,
                    size: 30,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => const StudentNotificationsScreen(),
                      ),
                    ).then((_) {
                      // Refresh unread count after returning from notifications
                      checkForNewMessages();
                    });
                  },
                ),
                if (unreadMessageCount > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        unreadMessageCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 20, top: 8),
            child: IconButton(
              icon: const Icon(
                Icons.menu_rounded,
                color: Colors.black,
                size: 40,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 30, left: 30, right: 30, bottom: 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Project Name Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                top: 40,
                left: 20,
                right: 20,
                bottom: 20,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFE5A72E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Project Name',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'In progress',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: ListView(
                children: [
                  buildInfoBox(
                    'Upload files',
                    Icons.upload_file,
                    isNavigateToTab: true,
                    tabIndex: 1,
                    context,
                  ),
                  buildInfoBox(
                    'Trending Projects',
                    Icons.trending_up,
                    navigateTo: TrendingProjectsScreen(),
                    context,
                  ),
                  buildInfoBox(
                    'Documentation support',
                    Icons.description,
                    navigateTo: DfdSupportScreen(),
                    context,
                  ),
                  buildInfoBox(
                    'AI Assistant',
                    Icons.chat_bubble_outline,
                    navigateTo: chatscreen(),
                    context,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildInfoBox(
    String title,
    dynamic icon,
    BuildContext context, {
    bool isNavigateToTab = false,
    int? tabIndex,
    Widget? navigateTo,
  }) {
    return InkWell(
      onTap: () {
        if (isNavigateToTab && tabIndex != null && widget.onNavigate != null) {
          widget.onNavigate!(tabIndex);
        } else if (navigateTo != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => navigateTo),
          );
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Color(0xFFE5A72E), width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon is String
                    ? SvgPicture.asset(
                      icon,
                      height: 35,
                      color: Color(0xFFE5A72E),
                    )
                    : Icon(icon, size: 35, color: Color(0xFFE5A72E)),

                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
