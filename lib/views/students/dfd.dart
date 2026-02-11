import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class DfdSupportScreen extends StatefulWidget {
  const DfdSupportScreen({super.key});

  @override
  State<DfdSupportScreen> createState() => _DfdSupportScreenState();
}

class _DfdSupportScreenState extends State<DfdSupportScreen> {
  File? selectedFile;
  String? fileName;

  Map<String, dynamic>? dfdResult;
  bool isLoading = false;

  // ================= FILE PICKER =================
  Future<void> pickAbstractFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        selectedFile = File(result.files.single.path!);
        fileName = result.files.single.name;
        dfdResult = null;
      });
    }
  }

  // ================= BACKEND AI CALL =================
  Future<void> fetchDfdGuidance() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://10.249.120.82:5171/api/ai/dfd-guidance'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'abstractText':
              'This project is an AI-based student project management system where students upload academic projects, faculty review submissions, and administrators manage approvals and workflows.',
          'filePath': selectedFile?.path ?? 'dummy.pdf',
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          dfdResult = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          dfdResult = {
            "dfd_level": "Error",
            "external_entities": [],
            "processes": [],
            "data_stores": [],
            "data_flows": ["Server error: ${response.statusCode}"],
          };
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        dfdResult = {
          "dfd_level": "Error",
          "external_entities": [],
          "processes": [],
          "data_stores": [],
          "data_flows": ["API not reachable. Check backend & IP."],
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black, size: width * 0.09),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'DFD SUPPORT',
          style: TextStyle(
            color: Colors.black,
            fontSize: width * 0.05,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Align(
          alignment: Alignment.topCenter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: height * 0.08),

              // ================= UPLOAD ABSTRACT =================
              GestureDetector(
                onTap: pickAbstractFile,
                child: Container(
                  width: width * 0.7,
                  height: height * 0.18,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5A72E),
                    borderRadius: BorderRadius.circular(width * 0.1),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.file_upload_outlined,
                        color: Colors.white,
                        size: width * 0.12,
                      ),
                      SizedBox(height: height * 0.015),
                      Text(
                        'Upload Abstract',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: width * 0.045,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ================= FILE NAME =================
              if (fileName != null) ...[
                SizedBox(height: height * 0.02),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: width * 0.1),
                  child: Row(
                    children: [
                      const Icon(Icons.insert_drive_file, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          fileName!,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: width * 0.035),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ================= AI BUTTON =================
              if (selectedFile != null) ...[
                SizedBox(height: height * 0.03),
                GestureDetector(
                  onTap: fetchDfdGuidance,
                  child: Image.asset(
                    'assets/icons/generate.png',
                    width: width * 0.30,
                  ),
                ),
              ],

              // ================= LOADING =================
              if (isLoading) ...[
                const SizedBox(height: 20),
                const CircularProgressIndicator(),
              ],

              // ================= AI RESULT =================
              if (dfdResult != null) ...[
                const SizedBox(height: 20),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: width * 0.06),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "DFD Level: ${dfdResult!['dfd_level']}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Entities: ${dfdResult!['external_entities'].join(', ')}",
                      ),
                      Text("Processes: ${dfdResult!['processes'].join(', ')}"),
                      Text(
                        "Data Stores: ${dfdResult!['data_stores'].join(', ')}",
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Data Flows:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ...List.generate(
                        dfdResult!['data_flows'].length,
                        (index) => Text("• ${dfdResult!['data_flows'][index]}"),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
