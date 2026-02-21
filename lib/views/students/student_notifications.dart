import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:project_management/config/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentNotificationsScreen extends StatefulWidget {
  const StudentNotificationsScreen({super.key});

  @override
  State<StudentNotificationsScreen> createState() =>
      _StudentNotificationsScreenState();
}

class _StudentNotificationsScreenState
    extends State<StudentNotificationsScreen> {
  late List<TeacherMessage> messages;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    messages = [];
    loadMessages();
  }

  Future<void> loadMessages() async {
    try {
      // Load student's registerNumber to get scoped notifications
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
        final notificationsList = data['notifications'] as List;

        // Check for new messages
        final lastSeenCount = prefs.getInt('lastSeenMessageCount') ?? 0;
        final currentCount = notificationsList.length;

        setState(() {
          messages =
              notificationsList
                  .map(
                    (item) => TeacherMessage(
                      senderName: item['senderName'] ?? 'Teacher',
                      content: item['message'] ?? '',
                      timestamp: item['timestamp'] ?? '',
                    ),
                  )
                  .toList();
          isLoading = false;
        });

        // Show popup if there are new messages
        if (currentCount > lastSeenCount) {
          final newMessageCount = currentCount - lastSeenCount;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '🔔 $newMessageCount new message${newMessageCount > 1 ? 's' : ''} from teacher!',
              ),
              backgroundColor: const Color(0xFFE5A72E),
              duration: const Duration(seconds: 3),
            ),
          );
        }

        // Save current count as seen
        await prefs.setInt('lastSeenMessageCount', currentCount);
      } else {
        setState(() {
          errorMessage = 'Failed to load messages';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFE5A72E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'MESSAGES FROM TEACHERS',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE5A72E)),
                ),
              )
              : errorMessage != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 60, color: Colors.red[400]),
                    const SizedBox(height: 16),
                    Text(
                      errorMessage!,
                      style: TextStyle(color: Colors.red[600], fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isLoading = true;
                          errorMessage = null;
                        });
                        loadMessages();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE5A72E),
                      ),
                      child: const Text(
                        'Retry',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              )
              : messages.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.mail_outline, size: 60, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No messages yet',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!, width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  message.senderName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFFE5A72E),
                                  ),
                                ),
                                Text(
                                  message.timestamp,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              message.content,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}

class TeacherMessage {
  final String senderName;
  final String content;
  final String timestamp;

  TeacherMessage({
    required this.senderName,
    required this.content,
    required this.timestamp,
  });
}
