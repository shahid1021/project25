import 'package:flutter/material.dart';
import 'package:project_management/views/auth/navigation.dart';
import 'package:project_management/views/students/home_screen.dart';

class NotificationItem {
  final String userName;
  final String action;
  final String fileName;
  final String time;
  final String avatarColor;

  NotificationItem({
    required this.userName,
    required this.action,
    required this.fileName,
    required this.time,
    required this.avatarColor,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final int _selectedIndex = 2;

  final List<NotificationItem> todayNotifications = [
    NotificationItem(
      userName: 'Jasmine',
      action: 'uploaded',
      fileName: 'Carrier guidance.pdf',
      time: '2 h ago',
      avatarColor: 'brown',
    ),
    NotificationItem(
      userName: 'stephy',
      action: 'edited the date in',
      fileName: 'management system.pdf',
      time: '3 h ago',
      avatarColor: 'blue',
    ),
    NotificationItem(
      userName: 'John',
      action: 'edited the date in',
      fileName: 'management system.pdf',
      time: '2 h ago',
      avatarColor: 'yellow',
    ),
  ];

  final List<NotificationItem> thisWeekNotifications = [
    NotificationItem(
      userName: 'George',
      action: 'uploaded',
      fileName: 'management system.pdf',
      time: '4 June',
      avatarColor: 'purple',
    ),
    NotificationItem(
      userName: 'Sam',
      action: 'updated second page in',
      fileName: 'data base management.pdf',
      time: '4 June',
      avatarColor: 'teal',
    ),
    NotificationItem(
      userName: 'zain',
      action: 'uploaded',
      fileName: 'machine learning.pdf',
      time: '1 June',
      avatarColor: 'navy',
    ),
    NotificationItem(
      userName: 'Zara',
      action: 'uploaded',
      fileName: 'project.pdf',
      time: '1 June',
      avatarColor: 'navy',
    ),
  ];
  final List<NotificationItem> thisMonthNotifications = [
    NotificationItem(
      userName: 'George',
      action: 'uploaded',
      fileName: 'management system.pdf',
      time: '4 June',
      avatarColor: 'purple',
    ),
    NotificationItem(
      userName: 'Sam',
      action: 'updated second page in',
      fileName: 'data base management.pdf',
      time: '4 June',
      avatarColor: 'teal',
    ),
    NotificationItem(
      userName: 'zain',
      action: 'uploaded',
      fileName: 'machine learning.pdf',
      time: '1 June',
      avatarColor: 'navy',
    ),
    NotificationItem(
      userName: 'Zara',
      action: 'uploaded',
      fileName: 'project.pdf',
      time: '1 June',
      avatarColor: 'navy',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
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
          padding: const EdgeInsets.only(left: 5, top: 30),
          child: const Text(
            'NOTIFICATIONS',
            style: TextStyle(
              color: Colors.black,
              fontSize: 27,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10, left: 15, bottom: 10),
              child: RichText(
                text: const TextSpan(
                  text: 'You have ',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                  children: [
                    TextSpan(
                      text: '3 Notifications',
                      style: TextStyle(
                        color: Color(0xFFE5A72E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextSpan(
                      text: ' today.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Today',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            SizedBox(
              height: 110, // show 2 messages; scroll for more
              child: ListView.builder(
                itemCount: todayNotifications.length,
                itemBuilder: (context, index) {
                  return _buildNotificationItem(
                    todayNotifications[index],
                    showDot: true,
                  );
                },
              ),
            ),

            const Padding(
              padding: EdgeInsets.all(16),
              child: Divider(thickness: 1),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'This week',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            SizedBox(
              height: 160,
              child: ListView.builder(
                itemCount: thisWeekNotifications.length,
                itemBuilder: (context, index) {
                  return _buildNotificationItem(
                    thisWeekNotifications[index],
                    showDot: false,
                  );
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Divider(thickness: 1),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'This Month',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            SizedBox(
              height: 160,
              child: ListView.builder(
                itemCount: thisWeekNotifications.length,
                itemBuilder: (context, index) {
                  return _buildNotificationItem(
                    thisWeekNotifications[index],
                    showDot: false,
                  );
                },
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
    NotificationItem item, {
    required bool showDot,
  }) {
    return Padding(
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
        ],
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
