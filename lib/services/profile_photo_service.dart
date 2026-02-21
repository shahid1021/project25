import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:project_management/config/api_config.dart';

class ProfilePhotoService {
  /// Fetch profile photo settings from server and cache locally
  static Future<Map<String, dynamic>> getProfilePhoto(String email) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/User/profile-photo?email=$email',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Cache locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profilePhotoType', data['type'] ?? 'none');
        await prefs.setInt('profileAvatarIndex', data['avatarIndex'] ?? 0);

        // If type is image, download and cache the image
        if (data['type'] == 'image' && data['hasImage'] == true) {
          await _downloadAndCacheImage(email);
        }

        return {
          'success': true,
          'type': data['type'],
          'avatarIndex': data['avatarIndex'],
        };
      }
      return {'success': false};
    } catch (e) {
      print('GET PROFILE PHOTO ERROR => $e');
      return {'success': false};
    }
  }

  /// Set avatar (preset) on server
  static Future<bool> setAvatar(String email, int avatarIndex) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/User/profile-photo?email=$email',
      );
      final response = await http
          .put(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'type': 'avatar', 'avatarIndex': avatarIndex}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profilePhotoType', 'avatar');
        await prefs.setInt('profileAvatarIndex', avatarIndex);
        await prefs.setString('profilePhotoPath', '');
        return true;
      }
      return false;
    } catch (e) {
      print('SET AVATAR ERROR => $e');
      return false;
    }
  }

  /// Upload image to server
  static Future<bool> uploadImage(String email, String filePath) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/User/profile-photo/upload?email=$email',
      );
      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Download the server copy back for local caching
        await _downloadAndCacheImage(email);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profilePhotoType', 'image');
        await prefs.setInt('profileAvatarIndex', 0);
        return true;
      }
      return false;
    } catch (e) {
      print('UPLOAD IMAGE ERROR => $e');
      return false;
    }
  }

  /// Remove profile photo on server
  static Future<bool> removePhoto(String email) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/User/profile-photo?email=$email',
      );
      final response = await http
          .put(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'type': 'none', 'avatarIndex': 0}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profilePhotoType', 'none');
        await prefs.setInt('profileAvatarIndex', 0);
        await prefs.setString('profilePhotoPath', '');
        return true;
      }
      return false;
    } catch (e) {
      print('REMOVE PHOTO ERROR => $e');
      return false;
    }
  }

  /// Download the profile image from server and save locally
  static Future<void> _downloadAndCacheImage(String email) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/User/profile-photo/image?email=$email',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final appDir = await getApplicationDocumentsDirectory();
        final savedPath = '${appDir.path}/profile_photo.jpg';
        await File(savedPath).writeAsBytes(response.bodyBytes);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profilePhotoPath', savedPath);
      }
    } catch (e) {
      print('DOWNLOAD IMAGE ERROR => $e');
    }
  }

  /// Sync profile photo from server on login
  static Future<void> syncOnLogin(String email) async {
    await getProfilePhoto(email);
  }
}
