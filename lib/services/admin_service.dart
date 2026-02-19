import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:project_management/config/api_config.dart';

class AdminService {
  final String baseUrl = '${ApiConfig.baseUrl}/admin';

  // ==================== DASHBOARD STATS ====================
  Future<Map<String, dynamic>?> getDashboardStats() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/stats'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error fetching stats: $e');
    }
    return null;
  }

  // ==================== USERS ====================
  Future<List<dynamic>> getAllUsers() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['users'] ?? [];
      }
    } catch (e) {
      print('Error fetching users: $e');
    }
    return [];
  }

  Future<bool> updateUserRole(int userId, String role) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId/role'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'role': role}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating role: $e');
      return false;
    }
  }

  Future<bool> toggleUserApproval(int userId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId/approve'),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error toggling approval: $e');
      return false;
    }
  }

  Future<bool> deleteUser(int userId) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/users/$userId'));
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }

  // ==================== PROJECTS ====================
  Future<List<dynamic>> getAllProjects() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/projects'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['projects'] ?? [];
      }
    } catch (e) {
      print('Error fetching projects: $e');
    }
    return [];
  }

  Future<bool> deleteProject(int projectId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/projects/$projectId'),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting project: $e');
      return false;
    }
  }

  // ==================== NOTIFICATIONS ====================
  Future<List<dynamic>> getAllNotifications() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/notifications'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['notifications'] ?? [];
      }
    } catch (e) {
      print('Error fetching notifications: $e');
    }
    return [];
  }

  Future<bool> deleteNotification(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/notifications/$id'),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting notification: $e');
      return false;
    }
  }

  Future<bool> sendNotification(String message, String teacherName) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/notifications/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': message, 'teacherName': teacherName}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error sending notification: $e');
      return false;
    }
  }

  // ==================== UPLOAD PROJECT WITH FILE ====================
  Future<bool> uploadProject({
    required String title,
    required String description,
    required String abstraction,
    required String batch,
    required String createdBy,
    required String teamMembers,
    String? filePath,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/projects/upload'),
      );

      request.fields['title'] = title;
      request.fields['description'] = description;
      request.fields['abstraction'] = abstraction;
      request.fields['batch'] = batch;
      request.fields['createdBy'] = createdBy;
      request.fields['teamMembers'] = teamMembers;

      if (fileBytes != null && fileName != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'File',
            fileBytes,
            filename: fileName,
            contentType: MediaType('application', 'octet-stream'),
          ),
        );
      }

      final response = await request.send();
      return response.statusCode == 200;
    } catch (e) {
      print('Error uploading project: $e');
      return false;
    }
  }

  // ==================== UPLOAD FILE TO EXISTING PROJECT ====================
  Future<bool> uploadFileToProject({
    required int projectId,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/projects/$projectId/upload'),
      );
      request.files.add(
        http.MultipartFile.fromBytes(
          'File',
          fileBytes,
          filename: fileName,
          contentType: MediaType('application', 'octet-stream'),
        ),
      );

      final response = await request.send();
      return response.statusCode == 200;
    } catch (e) {
      print('Error uploading file to project: $e');
      return false;
    }
  }
}
