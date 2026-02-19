import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:project_management/config/api_config.dart';

class TeacherProjectService {
  static Future<List<dynamic>> getProjects(String teacherEmail) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/teacher-projects?teacherEmail=$teacherEmail',
        ),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      print('Error loading projects from API: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> createProject({
    required String teacherEmail,
    required String groupNumber,
    required String groupMembers,
    required String projectName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/teacher-projects'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'teacherEmail': teacherEmail,
          'groupNumber': groupNumber,
          'groupMembers': groupMembers,
          'projectName': projectName,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error creating project: $e');
      return null;
    }
  }

  static Future<bool> updateStages(int projectId, List<bool> stages) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/teacher-projects/$projectId/stages'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'completionStages': stages}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating stages: $e');
      return false;
    }
  }

  static Future<bool> deleteProject(int projectId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/teacher-projects/$projectId'),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting project: $e');
      return false;
    }
  }
}
