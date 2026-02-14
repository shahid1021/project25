import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:project_management/config/api_config.dart';

class AiService {
  final String baseUrl = "${ApiConfig.baseUrl}/ai";

  Future<String?> sendChatMessage(String message) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/chat"),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'Message': message}),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              print('Request timeout - API took too long to respond');
              throw Exception(
                'Request timeout - Groq API took too long to respond',
              );
            },
          );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['response'];
      } else {
        print('Error: ${response.statusCode}');
        print('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception: $e');
      return null;
    }
  }
}
