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

  // Project data
  String projectName = '';
  String projectStatus = '';
  int completedStages = 0;
  int totalStages = 10;
  bool projectLoading = true;
  bool hasProject = false;

  @override
  void initState() {
    super.initState();
    loadStudentName();
    checkForNewMessages();
    fetchStudentProject();
    BackgroundMessageChecker.startPeriodicCheck();
  }

  Future<void> loadStudentName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      studentName = prefs.getString('studentName') ?? '';
    });
  }

  Future<void> fetchStudentProject() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final registerNumber = prefs.getString('registerNumber') ?? '';

      if (registerNumber.isEmpty) {
        setState(() => projectLoading = false);
        return;
      }

      final response = await http
          .get(
            Uri.parse(
              '${ApiConfig.baseUrl}/teacher-projects/by-student?registerNumber=$registerNumber',
            ),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final project = data[0]; // First (most recent) project
          final stages = List<bool>.from(project['completionStages'] ?? []);
          final completed = stages.where((s) => s).length;

          setState(() {
            projectName = project['projectName'] ?? 'Unnamed Project';
            projectStatus = project['status'] ?? 'Ongoing';
            completedStages = completed;
            totalStages = stages.length;
            hasProject = true;
            projectLoading = false;
          });
        } else {
          setState(() => projectLoading = false);
        }
      } else {
        setState(() => projectLoading = false);
      }
    } catch (e) {
      print('Error fetching student project: $e');
      setState(() => projectLoading = false);
    }
  }

  Future<void> checkForNewMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final registerNumber = prefs.getString('registerNumber') ?? '';

      // Student view: only get notifications from their teacher + admin broadcasts
      final url =
          registerNumber.isNotEmpty
              ? '${ApiConfig.baseUrl}/notifications/get?registerNumber=${Uri.encodeComponent(registerNumber)}'
              : '${ApiConfig.baseUrl}/notifications/get';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final count = (data['notifications'] as List?)?.length ?? 0;
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
            projectLoading
                ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5A72E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                )
                : hasProject
                ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(
                    top: 25,
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
                      Text(
                        projectName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 15),
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value:
                              totalStages > 0
                                  ? completedStages / totalStages
                                  : 0,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              projectStatus == 'Completed'
                                  ? 'Completed'
                                  : 'In progress',
                              style: TextStyle(
                                color:
                                    projectStatus == 'Completed'
                                        ? Colors.green
                                        : Colors.blue,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            '${totalStages > 0 ? ((completedStages / totalStages) * 100).toInt() : 0}% completed',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
                : Container(
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
                        'No Project Assigned',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your teacher hasn\'t assigned a project yet',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13,
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
