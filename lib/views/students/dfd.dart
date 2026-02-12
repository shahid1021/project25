import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:project_management/config/api_config.dart';

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
  String? dfdGuidance;
  bool showAnimation = false;

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
    if (isLoading || selectedFile == null) return;

    setState(() {
      isLoading = true;
      dfdGuidance = null;
    });

    try {
      // Upload file and get DFD guidance
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/ai/dfd-guidance'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('file', selectedFile!.path),
      );

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (!mounted) return;

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseBody);
        setState(() {
          showAnimation = true;
        });

        // Wait 1.5 seconds then hide animation and show guidance
        await Future.delayed(const Duration(milliseconds: 1500));

        if (mounted) {
          setState(() {
            dfdGuidance = jsonResponse['guidance'];
            isLoading = false;
            showAnimation = false;
          });
        }
      } else {
        setState(() {
          isLoading = false;
          dfdGuidance = 'Error: ${response.statusCode}\n${responseBody}';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        dfdGuidance =
            'API Error: $e\n\nMake sure backend is running on ${ApiConfig.baseUrl}';
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
        backgroundColor: const Color(0xFFE5A72E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'DFD Support',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
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

              // ================= UPLOAD ABSTRACT (Hidden if guidance shown) =================
              if (dfdGuidance == null) ...[
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

                // ================= AI BUTTON (Hidden if guidance shown) =================
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
              ],

              // ================= ANIMATION =================
              if (showAnimation) ...[
                SizedBox(height: height * 0.2),
                Column(
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(scale: value, child: child);
                      },
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5A72E),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                    ),
                    SizedBox(height: height * 0.02),
                    const Text(
                      'Guidance Generated!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE5A72E),
                      ),
                    ),
                  ],
                ),
              ],

              // ================= LOADING =================
              if (isLoading) ...[
                const SizedBox(height: 20),
                const CircularProgressIndicator(),
              ],

              // ================= AI RESULT =================
              if (dfdGuidance != null) ...[
                const SizedBox(height: 20),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: width * 0.06),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE5A72E),
                        width: 2,
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DFD Creation Guide',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE5A72E),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          dfdGuidance!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // ================= UPLOAD NEW FILE BUTTON =================
                GestureDetector(
                  onTap: () {
                    setState(() {
                      dfdGuidance = null;
                      selectedFile = null;
                      fileName = null;
                    });
                    pickAbstractFile();
                  },
                  child: Container(
                    width: width * 0.6,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5A72E),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text(
                        'Upload New File',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
