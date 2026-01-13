import 'dart:io';
import 'package:http_parser/http_parser.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UploadFilesPage extends StatefulWidget {
  const UploadFilesPage({super.key});

  @override
  State<UploadFilesPage> createState() => _UploadFilesPageState();
}

class _UploadFilesPageState extends State<UploadFilesPage> {
  File? selectedFile;
  bool isUploading = false;

  // TEMP list – later replaced with API data
  final List<String> uploadedFiles = [];

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
      // final uri = Uri.parse('http://192.168.1.64:5171/api/projects/upload');
      final uri = Uri.parse('http://192.168.1.65:5171/api/projects/1/upload');

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
          uploadedFiles.add(selectedFile!.path.split('/').last);
          selectedFile = null;
        });

        _showMessage('Upload successful');
      } else {
        _showMessage('Upload failed (${response.statusCode})');
      }
    } catch (e) {
      _showMessage(e.toString());
    } finally {
      setState(() => isUploading = false);
    }
  }

  /// Delete locally (API later)
  void deleteFile(int index) {
    setState(() {
      uploadedFiles.removeAt(index);
    });
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Files')),
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
                  uploadedFiles.isEmpty
                      ? const Center(child: Text('No files uploaded yet'))
                      : ListView.builder(
                        itemCount: uploadedFiles.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: const Icon(Icons.picture_as_pdf),
                            title: Text(uploadedFiles[index]),
                            trailing: PopupMenuButton(
                              itemBuilder:
                                  (_) => const [
                                    PopupMenuItem(
                                      value: 'view',
                                      child: Text('View Details'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete'),
                                    ),
                                  ],
                              onSelected: (value) {
                                if (value == 'delete') {
                                  deleteFile(index);
                                }
                              },
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
