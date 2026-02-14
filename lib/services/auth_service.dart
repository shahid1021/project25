import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_management/config/api_config.dart';

class AuthService {
  // REGISTER
  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/User/register');

      print('REGISTER URL => $uri');

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'firstName': firstName,
              'lastName': lastName,
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 30));

      print('REGISTER STATUS => ${response.statusCode}');
      print('REGISTER BODY => ${response.body}');

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Registration successful'};
      } else if (response.statusCode == 400) {
        return {'success': false, 'message': 'Email already exists'};
      } else {
        return {
          'success': false,
          'message': 'Registration failed: ${response.statusCode}',
        };
      }
    } on Exception catch (e) {
      print('REGISTER ERROR => $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // LOGIN
  Future<String> login(String email, String password) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/User/login');

    print('LOGIN URL => $uri');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    print('LOGIN STATUS => ${response.statusCode}');
    print('LOGIN BODY => ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
      await prefs.setString('role', data['role']);
      await prefs.setString('studentName', (data['name'] ?? '').toString());
      await prefs.setString('firstName', (data['firstName'] ?? '').toString());
      await prefs.setString('lastName', (data['lastName'] ?? '').toString());
      await prefs.setString('email', email);

      return data['role']; // Student / Teacher
    }

    if (response.statusCode == 401) return 'wrong_password';
    if (response.statusCode == 404) return 'no_account';

    return 'error';
  }

  // UPDATE NAME
  Future<Map<String, dynamic>> updateName(
    String email,
    String firstName,
    String lastName,
  ) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/User/update-name?email=$email',
      );

      print('UPDATE NAME URL => $uri');

      final response = await http
          .put(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'firstName': firstName, 'lastName': lastName}),
          )
          .timeout(const Duration(seconds: 30));

      print('UPDATE NAME STATUS => ${response.statusCode}');
      print('UPDATE NAME BODY => ${response.body}');

      if (response.statusCode == 200) {
        // Update SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('firstName', firstName);
        await prefs.setString('lastName', lastName);
        await prefs.setString('studentName', '${firstName} ${lastName}'.trim());

        return {'success': true, 'message': 'Name updated successfully'};
      } else {
        return {'success': false, 'message': 'Failed to update name'};
      }
    } on Exception catch (e) {
      print('UPDATE NAME ERROR => $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }
}
