import 'package:flutter/material.dart';
import 'package:project_management/views/auth/navigation.dart';
import 'package:project_management/views/students/home_screen.dart';
import 'package:project_management/config/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationItem {
  final int id;
  final String userName;
  final String action;
  final String fileName;
  final String time;
  final String avatarColor;
  final bool isTeacherMessage;

  NotificationItem({
    required this.id,
    required this.userName,
    required this.action,
    required this.fileName,
    required this.time,
    required this.avatarColor,
    this.isTeacherMessage = false,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late List<NotificationItem> todayNotifications;
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;
  bool isLoading = true;
  String teacherEmail = '';
  String teacherName = '';

  @override
  void initState() {
    super.initState();
    todayNotifications = [];
    _loadTeacherInfo();
  }

  Future<void> _loadTeacherInfo() async {
    final prefs = await SharedPreferences.getInstance();
    teacherEmail = prefs.getString('email') ?? '';
    final firstName = prefs.getString('firstName') ?? '';
    final lastName = prefs.getString('lastName') ?? '';
    teacherName = '$firstName $lastName'.trim();
    if (teacherName.isEmpty) teacherName = 'Teacher';
    loadMessagesFromDatabase();
  }

  Future<void> loadMessagesFromDatabase() async {
    try {
      // Teacher view: only load notifications sent by this teacher
      final url =
          teacherEmail.isNotEmpty
              ? '${ApiConfig.baseUrl}/notifications/get?teacherEmail=${Uri.encodeComponent(teacherEmail)}'
              : '${ApiConfig.baseUrl}/notifications/get';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final notificationsList = data['notifications'] as List;

        setState(() {
          todayNotifications =
              notificationsList
                  .map(
                    (item) => NotificationItem(
                      id: item['id'] ?? 0,
                      userName: item['senderName'] ?? 'Teacher',
                      action: 'announced',
                      fileName: item['message'] ?? '',
                      time: item['timestamp'] ?? '',
                      avatarColor: 'brown',
                      isTeacherMessage: true,
                    ),
                  )
                  .toList();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading messages: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  // ================= DELETE NOTIFICATION =================
  Future<void> _deleteNotification(NotificationItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Announcement'),
            content: const Text(
              'Are you sure you want to delete this announcement?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/notifications/${item.id}'),
      );

      if (response.statusCode == 200) {
        await loadMessagesFromDatabase();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Announcement deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showComposeDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(
              'Send Message to Your Students',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            content: TextField(
              controller: _messageController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Type your message here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _messageController.clear();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed:
                    _isSending
                        ? null
                        : () {
                          _sendMessage();
                          Navigator.pop(context);
                        },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE5A72E),
                  foregroundColor: Colors.white,
                ),
                child:
                    _isSending
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Text('Send'),
              ),
            ],
          ),
    );
  }

  void _sendMessage() async {
    if (_messageController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Message cannot be empty')));
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      // Send message to backend API
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/notifications/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': _messageController.text,
          'teacherName': teacherName,
          'teacherEmail': teacherEmail,
        }),
      );

      if (response.statusCode == 200) {
        // Reload messages from database to show the new message
        await loadMessagesFromDatabase();

        _messageController.clear();
        setState(() {
          _isSending = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message sent to your students!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _isSending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      setState(() {
        _isSending = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  final List<NotificationItem> thisMonthNotifications = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFE5A72E),
        elevation: 0,

        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back, color: Colors.black),
        //   onPressed: () {
        //     Navigator.pushReplacement(
        //       context,
        //       MaterialPageRoute(builder: (context) => const MainNavigation()),
        //     );
        //   },
        // ),
        title: Padding(
          padding: const EdgeInsets.only(left: 5, top: 30, bottom: 20),
          child: const Text(
            'NOTIFICATIONS',
            style: TextStyle(
              color: Color.fromARGB(255, 0, 0, 0),
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
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
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 10,
                        left: 15,
                        bottom: 10,
                      ),
                      child: RichText(
                        text: TextSpan(
                          text: 'You have ',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                          children: [
                            TextSpan(
                              text:
                                  '${todayNotifications.length} Announcement${todayNotifications.length == 1 ? '' : 's'}',
                              style: const TextStyle(
                                color: Color(0xFFE5A72E),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        'Your Announcements',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    if (todayNotifications.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'No announcements yet',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: todayNotifications.length,
                        itemBuilder: (context, index) {
                          return _buildNotificationItem(
                            todayNotifications[index],
                            showDot: true,
                          );
                        },
                      ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showComposeDialog,
        backgroundColor: const Color(0xFFE5A72E),
        child: const Icon(Icons.add_comment, color: Colors.white),
      ),
    );
  }

  Widget _buildNotificationItem(
    NotificationItem item, {
    required bool showDot,
  }) {
    return Dismissible(
      key: Key('notification_${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.delete, color: Colors.red, size: 28),
      ),
      confirmDismiss: (direction) async {
        _deleteNotification(item);
        return false; // We handle removal via reload
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showDot)
              Container(
                margin: const EdgeInsets.only(right: 8, top: 12),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            CircleAvatar(
              radius: 20,
              backgroundColor: _getAvatarColor(item.avatarColor),
              child: Text(
                item.userName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                      children: [
                        TextSpan(
                          text: item.userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE5A72E),
                          ),
                        ),
                        TextSpan(text: ' ${item.action} '),
                        TextSpan(
                          text: item.fileName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        TextSpan(
                          text: ' · ${item.time}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Delete icon button
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 20,
              ),
              onPressed: () => _deleteNotification(item),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAvatarColor(String colorName) {
    switch (colorName) {
      case 'brown':
        return Colors.brown;
      case 'blue':
        return Colors.blue;
      case 'purple':
        return Colors.purple;
      case 'teal':
        return Colors.teal;
      case 'navy':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }
}
