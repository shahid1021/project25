import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:project_management/config/api_config.dart';
import 'package:project_management/services/notification_service.dart';

const String backgroundTaskKey = 'check_messages';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == backgroundTaskKey) {
        await checkForNewMessages();
      }
    } catch (e) {
      print('❌ Background task error: $e');
    }
    return Future.value(true);
  });
}

Future<void> checkForNewMessages() async {
  try {
    final response = await http
        .get(Uri.parse('${ApiConfig.baseUrl}/notifications/get'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final notificationsList = data['notifications'] as List?;

      if (notificationsList != null && notificationsList.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final lastSeenCount = prefs.getInt('lastSeenMessageCount') ?? 0;
        final currentCount = notificationsList.length;

        if (currentCount > lastSeenCount) {
          final newMessageCount = currentCount - lastSeenCount;
          final latestMessage = notificationsList.first;

          // Show notification
          await NotificationService.showNotification(
            title: '🔔 ${latestMessage['senderName'] ?? 'Teacher'}',
            body: latestMessage['message'] ?? 'New message from teacher',
          );

          print('✅ New message notification shown! ($newMessageCount new)');
        }
      }
    }
  } catch (e) {
    print('❌ Error checking messages: $e');
  }
}

class BackgroundMessageChecker {
  static Future<void> startPeriodicCheck() async {
    try {
      // Initialize notification service first
      await NotificationService.initialize();

      // Initialize workmanager
      await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

      // Register periodic task (15 minute interval, minimum recommended)
      await Workmanager().registerPeriodicTask(
        backgroundTaskKey,
        backgroundTaskKey,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(
          requiresCharging: false,
          requiresDeviceIdle: false,
          networkType: NetworkType.connected,
        ),
      );

      print('✅ Background message checker started (15 min interval)');
    } catch (e) {
      print('❌ Error starting background checker: $e');
    }
  }

  static Future<void> stopPeriodicCheck() async {
    try {
      await Workmanager().cancelAll();
      print('✅ Background message checker stopped');
    } catch (e) {
      print('❌ Error stopping background checker: $e');
    }
  }
}
