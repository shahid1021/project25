import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_management/config/api_config.dart';

class AuthService {
  // REGISTER
  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/auth/register');

    print('REGISTER URL => $uri');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
      }),
    );

    print('REGISTER STATUS => ${response.statusCode}');
    print('REGISTER BODY => ${response.body}');

    return response.statusCode == 200;
  }

  // LOGIN
  Future<String> login(String email, String password) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/auth/login');

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
      await prefs.setString('studentName', (data['name'] ?? '').toString());
      await prefs.setString('email', email);

      return data['role']; // Student / Teacher
    }

    if (response.statusCode == 401) return 'wrong_password';
    if (response.statusCode == 404) return 'no_account';

    return 'error';
  }
}
