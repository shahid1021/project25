import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProjectService {
  final String baseUrl = "http://192.168.10.54:44319/api/Projects";
  // Example:
  // final String baseUrl = "http://192.168.1.64:44319/api/Projects";

  Future<bool> uploadPdf(int projectId) async {
    // Pick PDF
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null) return false;

    File file = File(result.files.single.path!);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token == null) return false;

    var request = http.MultipartRequest(
      "POST",
      Uri.parse("$baseUrl/$projectId/upload"),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath("file", file.path));

    var response = await request.send();

    return response.statusCode == 200;
  }
}
