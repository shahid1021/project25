import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_management/config/api_config.dart';

class UploadFilesPage extends StatefulWidget {
  const UploadFilesPage({super.key});

  @override
  State<UploadFilesPage> createState() => _UploadFilesPageState();
}

class _UploadFilesPageState extends State<UploadFilesPage> {
  File? selectedFile;
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
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
  Future<void> uploadFile({
    required String projectName,
    required String teamMembers,
    required String batch,
  }) async {
    if (selectedFile == null) return;

    setState(() => isUploading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final email = prefs.getString('email');
      final studentName = prefs.getString('studentName');

      print("JWT TOKEN = $token");

      if (token == null) {
        throw 'User not authenticated';
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/projects/1/upload');

      final request = http.MultipartRequest('POST', uri);

      // AUTH HEADER
      request.headers['Authorization'] = 'Bearer $token';

      // Add file
      request.files.add(
        await http.MultipartFile.fromPath(
          'File', // MUST be capital F
          selectedFile!.path,
        ),
      );

      // Add project metadata
      request.fields['projectName'] = projectName;
      request.fields['teamMembers'] = teamMembers;
      request.fields['batch'] = batch;
      request.fields['createdBy'] = email ?? studentName ?? 'Student';

      final response = await request.send();

      final responseBody = await response.stream.bytesToString();

      print('UPLOAD STATUS => ${response.statusCode}');
      print('UPLOAD BODY => $responseBody');

      if (response.statusCode == 200) {
        setState(() {
          selectedFile = null;
        });

        _showMessage('Project uploaded successfully');
      } else {
        _showMessage('Upload failed (${response.statusCode})');
      }
    } catch (e) {
      _showMessage(e.toString());
    } finally {
      setState(() => isUploading = false);
    }
  }

  /// Show project details dialog before upload
  void _showProjectDetailsDialog() {
    final projectNameController = TextEditingController();
    final teamMembersController = TextEditingController();
    final batchController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Project Details',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: projectNameController,
                  decoration: InputDecoration(
                    labelText: 'Project Name',
                    hintText: 'Enter project name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: teamMembersController,
                  decoration: InputDecoration(
                    labelText: 'Team Members',
                    hintText: 'Enter team members names',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: batchController,
                  decoration: InputDecoration(
                    labelText: 'Batch Year',
                    hintText: 'e.g., 2024, 2025',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE5A72E),
              ),
              onPressed: () {
                if (projectNameController.text.isEmpty ||
                    teamMembersController.text.isEmpty ||
                    batchController.text.isEmpty) {
                  _showMessage('Please fill all fields');
                  return;
                }

                Navigator.pop(context);

                uploadFile(
                  projectName: projectNameController.text,
                  teamMembers: teamMembersController.text,
                  batch: batchController.text,
                );
              },
              child: const Text('Upload'),
            ),
          ],
        );
      },
    );
  }

  /// Delete file from backend
  // Removed - no longer needed

  /// View/Download file
  // Removed - no longer needed

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFE5A72E),
        elevation: 0,
        title: const Text(
          'Upload Files',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: ElevatedButton.icon(
                onPressed: pickFile,
                icon: const Icon(Icons.attach_file, color: Colors.white),
                label: const Text(
                  'Select PDF',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE5A72E),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ),

            if (selectedFile != null) ...[
              const SizedBox(height: 12),
              Text(
                selectedFile!.path.split('/').last,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Center(
                child: ElevatedButton(
                  onPressed: isUploading ? null : _showProjectDetailsDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE5A72E),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child:
                      isUploading
                          ? const CircularProgressIndicator()
                          : const Text(
                            'Confirm Upload',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
