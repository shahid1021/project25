import 'dart:io';
import 'dart:convert';
import 'package:http_parser/http_parser.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_management/config/api_config.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path_provider/path_provider.dart';

class UploadFilesPage extends StatefulWidget {
  const UploadFilesPage({super.key});

  @override
  State<UploadFilesPage> createState() => _UploadFilesPageState();
}

class _UploadFilesPageState extends State<UploadFilesPage> {
  File? selectedFile;
  bool isUploading = false;
  bool isLoading = true;
  List<dynamic> uploadedFiles = [];

  @override
  void initState() {
    super.initState();
    syncExistingFiles();
    fetchUploadedFiles();
  }

  /// Sync existing files to database
  Future<void> syncExistingFiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return;

      final uri = Uri.parse('${ApiConfig.baseUrl}/Projects/1/sync-files');

      final response = await http.post(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      print('SYNC STATUS => ${response.statusCode}');
      print('SYNC BODY => ${response.body}');
    } catch (e) {
      print('Sync error: $e');
    }
  }

  /// Fetch uploaded files from backend
  Future<void> fetchUploadedFiles() async {
    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw 'User not authenticated';
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/Projects/1/files');

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      print('FETCH FILES STATUS => ${response.statusCode}');
      print('FETCH FILES BODY => ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          uploadedFiles = data['files'] ?? [];
        });
      } else if (response.statusCode == 401) {
        _showMessage('Session expired. Please log in again.');
      } else {
        _showMessage('Failed to load files');
      }
    } catch (e) {
      print('Error fetching files: $e');
      _showMessage('Failed to load files');
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// Pick PDF file
  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        selectedFile = File(result.files.single.path!);
      });
    }
  }

  /// Upload file to backend
  Future<void> uploadFile() async {
    if (selectedFile == null) return;

    setState(() => isUploading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      print("JWT TOKEN = $token");

      if (token == null) {
        throw 'User not authenticated';
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/projects/1/upload');

      final request = http.MultipartRequest('POST', uri);

      // AUTH HEADER
      request.headers['Authorization'] = 'Bearer $token';

      // DO NOT set Content-Type manually

      request.files.add(
        await http.MultipartFile.fromPath(
          'File', // MUST be capital F
          selectedFile!.path,
        ),
      );

      final response = await request.send();

      final responseBody = await response.stream.bytesToString();

      print('UPLOAD STATUS => ${response.statusCode}');
      print('UPLOAD BODY => $responseBody');

      if (response.statusCode == 200) {
        setState(() {
          selectedFile = null;
        });

        _showMessage('Upload successful');

        // Refresh the file list
        fetchUploadedFiles();
      } else {
        _showMessage('Upload failed (${response.statusCode})');
      }
    } catch (e) {
      _showMessage(e.toString());
    } finally {
      setState(() => isUploading = false);
    }
  }

  /// Delete file from backend
  Future<void> deleteFile(int index) async {
    final file = uploadedFiles[index];
    final fileName = file['fileName'];

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw 'User not authenticated';
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/Projects/1/files/$fileName');

      final response = await http.delete(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      print('DELETE STATUS => ${response.statusCode}');
      print('DELETE BODY => ${response.body}');

      if (response.statusCode == 200) {
        setState(() {
          uploadedFiles.removeAt(index);
        });
        _showMessage('File deleted successfully');
      } else {
        _showMessage('Failed to delete file');
      }
    } catch (e) {
      print('Error deleting file: $e');
      _showMessage('Error: ${e.toString()}');
    }
  }

  /// View/Download file
  Future<void> viewFile(int index) async {
    final file = uploadedFiles[index];
    final fileName = file['fileName'];
    final displayName = file['displayName'] ?? 'file.pdf';

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw 'User not authenticated';
      }

      _showMessage('Downloading $displayName...');

      final url = '${ApiConfig.baseUrl}/Projects/1/files/$fileName/download';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('Download status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Get temporary directory
        final dir = await getTemporaryDirectory();
        final filePath = '${dir.path}/$displayName';

        // Save file
        final fileToSave = File(filePath);
        await fileToSave.writeAsBytes(response.bodyBytes);

        print('File saved to: $filePath');
        _showMessage('Opening file...');

        // Open file
        final result = await OpenFile.open(filePath);

        if (result.type != ResultType.done) {
          _showMessage('Could not open file: ${result.message}');
        }
      } else {
        _showMessage('Failed to download file');
      }
    } catch (e) {
      print('Error viewing file: $e');
      _showMessage('Error: ${e.toString()}');
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Files'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await syncExistingFiles();
              await fetchUploadedFiles();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: pickFile,
              icon: const Icon(Icons.attach_file),
              label: const Text('Select PDF'),
            ),

            if (selectedFile != null) ...[
              const SizedBox(height: 12),
              Text(
                selectedFile!.path.split('/').last,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: isUploading ? null : uploadFile,
                child:
                    isUploading
                        ? const CircularProgressIndicator()
                        : const Text('Confirm Upload'),
              ),
            ],

            const SizedBox(height: 20),
            const Divider(),

            Expanded(
              child:
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : uploadedFiles.isEmpty
                      ? const Center(child: Text('No files uploaded yet'))
                      : ListView.builder(
                        itemCount: uploadedFiles.length,
                        itemBuilder: (context, index) {
                          final file = uploadedFiles[index];
                          final displayName =
                              file['displayName'] ??
                              file['fileName'] ??
                              'Unknown';
                          final fileSize = file['size'] ?? 0;

                          return ListTile(
                            onTap: () => viewFile(index),
                            leading: const Icon(
                              Icons.picture_as_pdf,
                              color: Colors.red,
                              size: 40,
                            ),
                            title: Text(
                              displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${(fileSize / 1024).toStringAsFixed(2)} KB',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => deleteFile(index),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
