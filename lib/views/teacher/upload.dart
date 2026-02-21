import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:project_management/config/api_config.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  String? selectedFileName;
  String? selectedFilePath;
  String? extractedText;
  bool isLoading = false;
  Map<String, dynamic>? detectionResult;

  Future<bool> requestStoragePermission() async {
    if (await Permission.storage.isGranted) return true;
    var status = await Permission.storage.request();
    if (status.isGranted) return true;
    if (await Permission.photos.isGranted ||
        await Permission.videos.isGranted ||
        await Permission.audio.isGranted) {
      return true;
    }
    await openAppSettings();
    return false;
  }

  Future<String> extractTextFromFile(File file) async {
    try {
      if (file.path.endsWith('.pdf')) {
        // For PDFs, read as bytes and send to backend for proper extraction
        // PDF binary data can't be simply converted to string
        final bytes = await file.readAsBytes();
        return base64Encode(bytes); // Send as base64 to backend
      } else if (file.path.endsWith('.txt')) {
        return await file.readAsString();
      } else if (file.path.endsWith('.doc') || file.path.endsWith('.docx')) {
        // For DOCX, read as bytes - backend can handle conversion
        final bytes = await file.readAsBytes();
        return base64Encode(bytes); // Send as base64 to backend
      } else {
        return await file.readAsString();
      }
    } catch (e) {
      print('Error extracting text: $e');
      return '';
    }
  }

  Future<void> checkFileForDuplicates() async {
    if (selectedFileName == null || selectedFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a file first')),
      );
      return;
    }

    setState(() {
      isLoading = true;
      detectionResult = null;
    });

    try {
      // Send file as multipart for proper server-side text extraction
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/ai/detect-duplicate'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('file', selectedFilePath!),
      );

      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 120),
      );
      var responseBody = await streamedResponse.stream.bytesToString();

      // Print the full API response body to console for debugging
      print('Duplicate Detection API Response:');
      print(responseBody);

      if (streamedResponse.statusCode == 200) {
        final result = jsonDecode(responseBody);
        // Print only debug fields for easy visibility
        print('DEBUG EXTRACTED TEXT:');
        print(result['debugExtractedText']);
        print('DEBUG DATABASE ABSTRACTIONS:');
        print(result['debugDatabaseAbstractions']);
        setState(() {
          detectionResult = result;
          isLoading = false;
        });

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => DuplicateResultsPage(result: detectionResult!),
            ),
          );
        }
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${streamedResponse.statusCode} - $responseBody',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error analyzing file')));
    }
  }

  // Removed AI similarity check function

  Future<void> pickFile() async {
    bool allowed = await requestStoragePermission();
    if (!allowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage permission required')),
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'doc', 'docx'],
      allowMultiple: false,
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final physicalFile = File(file.path!);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Extracting text from file...')),
      );

      final text = await extractTextFromFile(physicalFile);

      setState(() {
        selectedFileName = file.name;
        selectedFilePath = file.path;
        extractedText = text;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('File loaded successfully')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        title: const Text(
          'Project Checker',
          style: TextStyle(
            color: Color.fromARGB(255, 0, 0, 0),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFE5A72E),
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.folder_outlined,
              color: Colors.black,
              size: 28,
            ),
            tooltip: 'Previous Year Projects',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PreviousYearProjectsPage(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body:
          isLoading
              ? const LoadingAnimationPage()
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Upload Student Abstract',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload your student\'s project abstract to check for duplicate or similar ideas',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 30),

                      // File Upload Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFE5A72E).withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5A72E).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.cloud_upload_outlined,
                                size: 48,
                                color: Color(0xFFE5A72E),
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (selectedFileName == null)
                              const Text(
                                'No file selected',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            else
                              Column(
                                children: [
                                  const Text(
                                    'File selected',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    selectedFileName!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.attach_file),
                                label: const Text(
                                  'Choose File',
                                  style: TextStyle(fontSize: 16),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE5A72E),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: pickFile,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Check File Button with Search Icon
                      if (selectedFileName != null)
                        Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.search),
                                    label: const Text(
                                      'Check the File',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFE5A72E),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: checkFileForDuplicates,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      const SizedBox(height: 20),

                      // Info Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5E6C3).withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'How it works:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '1. Upload the student\'s abstract\n2. Click "Check the File"\n3. System scans against existing projects\n4. Detects similar ideas and shows results\n5. View matching keywords and differences',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}

// ==================== LOADING ANIMATION ====================
class LoadingAnimationPage extends StatefulWidget {
  const LoadingAnimationPage({Key? key}) : super(key: key);

  @override
  State<LoadingAnimationPage> createState() => _LoadingAnimationPageState();
}

class _LoadingAnimationPageState extends State<LoadingAnimationPage>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<String> statusMessages;
  late int _currentMessageIndex;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    statusMessages = [
      'Finding old projects...',
      'Scanning database...',
      'Analyzing keywords...',
      'Comparing abstracts...',
    ];
    _currentMessageIndex = 0;

    // Change message every 2 seconds
    Future.delayed(const Duration(seconds: 0), _changeMessage);
  }

  void _changeMessage() {
    if (mounted) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _currentMessageIndex =
                (_currentMessageIndex + 1) % statusMessages.length;
          });
          _changeMessage();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated circular loading with scanning effect
            SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer rotating ring
                  RotationTransition(
                    turns: _controller,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFFE5A72E),
                          width: 4,
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Inner pulsing circle
                  ScaleTransition(
                    scale: Tween<double>(begin: 0.5, end: 1.0).animate(
                      CurvedAnimation(parent: _controller, curve: Curves.ease),
                    ),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE5A72E),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.search,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Checking Projects',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 50,
              child: Center(
                child: Text(
                  statusMessages[_currentMessageIndex],
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== RESULTS PAGE ====================
class DuplicateResultsPage extends StatefulWidget {
  final Map<String, dynamic> result;

  const DuplicateResultsPage({Key? key, required this.result})
    : super(key: key);

  @override
  State<DuplicateResultsPage> createState() => _DuplicateResultsPageState();
}

class _DuplicateResultsPageState extends State<DuplicateResultsPage> {
  @override
  Widget build(BuildContext context) {
    final isDuplicate = widget.result['isDuplicate'] ?? false;
    final similarProjects =
        widget.result['similarProjects'] as List<dynamic>? ?? [];
    final newFeatures = widget.result['newFeatures'] as List<dynamic>? ?? [];
    final totalChecked = widget.result['totalChecked'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Analysis Results',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= STATUS CARD =================
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      isDuplicate
                          ? Colors.red.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        isDuplicate
                            ? Colors.red.withOpacity(0.3)
                            : Colors.green.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isDuplicate
                          ? Icons.error_outline
                          : Icons.check_circle_outline,
                      color: isDuplicate ? Colors.red : Colors.green,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isDuplicate ? 'Already Done!' : 'Unique Project',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDuplicate ? Colors.red : Colors.green,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isDuplicate
                                ? 'Similar projects found in database'
                                : 'No similar projects found',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ================= SIMILAR PROJECTS =================
              if (isDuplicate && similarProjects.isNotEmpty) ...[
                const Text(
                  'Similar Projects',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                ...similarProjects.map((project) {
                  final similarity = project['similarity'] ?? 0;
                  final reason = project['reason'] ?? '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ===== TITLE + MATCH =====
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                project['name'] ?? 'Project',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    similarity >= 70
                                        ? Colors.red.withOpacity(0.2)
                                        : similarity >= 40
                                        ? Colors.orange.withOpacity(0.2)
                                        : const Color(
                                          0xFFE5A72E,
                                        ).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$similarity% Match',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      similarity >= 70
                                          ? Colors.red
                                          : similarity >= 40
                                          ? Colors.orange
                                          : const Color(0xFFE5A72E),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        if (reason.toString().isNotEmpty)
                          Text(
                            reason.toString(),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              height: 1.4,
                              fontStyle: FontStyle.italic,
                            ),
                          ),

                        const SizedBox(height: 10),

                        // ===== VIEW DETAILS BUTTON =====
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            icon: const Icon(Icons.visibility, size: 18),
                            label: const Text("View Details"),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    title: Text(project['name'] ?? 'Project'),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _detailRow("Batch", project['batch']),
                                          _detailRow("Group", project['group']),
                                          _detailRow(
                                            "Created By",
                                            project['createdBy'],
                                          ),
                                          _detailRow(
                                            "Team Members",
                                            project['teamMembers'],
                                          ),
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text("Close"),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),

                const SizedBox(height: 24),
              ],

              // ================= ACTION BUTTONS =================
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back to Upload'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= DETAIL ROW =================
  Widget _detailRow(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$title: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              value?.toString() ?? "N/A",
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== AI SIMILARITY RESULTS PAGE ====================
class AiSimilarityResultsPage extends StatelessWidget {
  final Map<String, dynamic> result;

  const AiSimilarityResultsPage({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final isDuplicate = result['isDuplicate'] ?? false;
    final similarProjects = result['similarProjects'] as List<dynamic>? ?? [];
    final totalChecked = result['totalChecked'] ?? 0;
    final analysis = result['analysis'] ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'AI Similarity Results',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDuplicate ? Colors.red.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      isDuplicate ? Colors.red.shade200 : Colors.green.shade200,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    isDuplicate
                        ? Icons.warning_rounded
                        : Icons.verified_rounded,
                    size: 48,
                    color: isDuplicate ? Colors.red : Colors.green,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isDuplicate ? 'Similar Projects Found' : 'Unique Project!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color:
                          isDuplicate
                              ? Colors.red.shade700
                              : Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    analysis,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Checked against $totalChecked projects using AI',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (similarProjects.isNotEmpty) ...[
              Text(
                'Similar Projects (${similarProjects.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...similarProjects.map((project) {
                final similarity = project['similarity'] ?? 0;
                final Color simColor =
                    similarity >= 70
                        ? Colors.red
                        : similarity >= 40
                        ? Colors.orange
                        : Colors.yellow.shade700;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              project['name'] ?? 'Unknown',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: simColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$similarity% Match',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: simColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Similarity bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: similarity / 100.0,
                          backgroundColor: Colors.grey.shade200,
                          color: simColor,
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _infoChip('Batch: ${project['batch'] ?? 'N/A'}'),
                          const SizedBox(width: 8),
                          _infoChip('By: ${project['createdBy'] ?? 'N/A'}'),
                        ],
                      ),
                      if (project['reason'] != null &&
                          project['reason'].toString().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.psychology_rounded,
                                size: 18,
                                color: Colors.blue.shade700,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  project['reason'],
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ],

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Upload'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
      ),
    );
  }
}

// ==================== PREVIOUS YEAR PROJECTS PAGE ====================
class PreviousYearProjectsPage extends StatefulWidget {
  const PreviousYearProjectsPage({Key? key}) : super(key: key);

  @override
  State<PreviousYearProjectsPage> createState() =>
      _PreviousYearProjectsPageState();
}

class _PreviousYearProjectsPageState extends State<PreviousYearProjectsPage> {
  List<Map<String, dynamic>> allProjects = [];
  List<Map<String, dynamic>> filteredProjects = [];
  bool isLoading = true;
  String searchQuery = '';
  String selectedYear = 'All';
  List<String> availableYears = ['All'];
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchProjects();
  }

  Future<void> _fetchProjects() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/projects/previous-year'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['projects'] as List;
        setState(() {
          allProjects = list.map((p) => Map<String, dynamic>.from(p)).toList();
          // Extract unique years from batch field
          final years =
              allProjects
                  .map((p) => (p['batch'] ?? '').toString())
                  .where((b) => b.isNotEmpty)
                  .toSet()
                  .toList();
          years.sort((a, b) => b.compareTo(a));
          availableYears = ['All', ...years];
          _applyFilters();
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error fetching previous year projects: $e');
      setState(() => isLoading = false);
    }
  }

  void _applyFilters() {
    filteredProjects =
        allProjects.where((project) {
          final title = (project['title'] ?? '').toString().toLowerCase();
          final createdBy =
              (project['createdBy'] ?? '').toString().toLowerCase();
          final teamMembers =
              (project['teamMembers'] ?? '').toString().toLowerCase();
          final batch = (project['batch'] ?? '').toString();
          final query = searchQuery.toLowerCase();

          final matchesSearch =
              query.isEmpty ||
              title.contains(query) ||
              createdBy.contains(query) ||
              teamMembers.contains(query);

          final matchesYear = selectedYear == 'All' || batch == selectedYear;

          return matchesSearch && matchesYear;
        }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Previous Year Projects',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFE5A72E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFE5A72E)),
              )
              : Column(
                children: [
                  // Search bar + Year filter
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) {
                              setState(() {
                                searchQuery = val;
                                _applyFilters();
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Search by name...',
                              prefixIcon: const Icon(Icons.search, size: 22),
                              suffixIcon:
                                  searchQuery.isNotEmpty
                                      ? IconButton(
                                        icon: const Icon(Icons.close, size: 20),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {
                                            searchQuery = '';
                                            _applyFilters();
                                          });
                                        },
                                      )
                                      : null,
                              filled: true,
                              fillColor: Colors.grey[100],
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 0,
                                horizontal: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedYear,
                              icon: const Icon(Icons.filter_list, size: 20),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                              items:
                                  availableYears
                                      .map(
                                        (y) => DropdownMenuItem(
                                          value: y,
                                          child: Text(y),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (val) {
                                setState(() {
                                  selectedYear = val ?? 'All';
                                  _applyFilters();
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Results
                  Expanded(
                    child:
                        filteredProjects.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.folder_open,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    allProjects.isEmpty
                                        ? 'No previous year projects yet'
                                        : 'No matching projects found',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : RefreshIndicator(
                              onRefresh: _fetchProjects,
                              child: ListView.separated(
                                padding: const EdgeInsets.all(12),
                                itemCount: filteredProjects.length,
                                separatorBuilder:
                                    (context, index) =>
                                        const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final project = filteredProjects[index];
                                  return _buildProjectCard(project);
                                },
                              ),
                            ),
                  ),
                ],
              ),
    );
  }

  Future<void> _openFile(
    int projectId,
    String fileName,
    String displayName,
  ) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const Center(
              child: CircularProgressIndicator(color: Color(0xFFE5A72E)),
            ),
      );

      final url =
          '${ApiConfig.baseUrl}/projects/previous-year/$projectId/files/$fileName/download';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final filePath = '${dir.path}/$displayName';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        if (mounted) Navigator.pop(context);
        await OpenFile.open(filePath);
      } else {
        if (mounted) Navigator.pop(context);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Failed to load file')));
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _buildProjectCard(Map<String, dynamic> project) {
    final files = (project['files'] as List?) ?? [];
    final projectId = project['id'];
    final title = project['title'] ?? 'Untitled';
    final batch = project['batch'] ?? '';
    final createdBy = project['createdBy'] ?? '';
    final teamMembers = project['teamMembers'] ?? '';
    final description = project['description'] ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE5A72E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.folder, color: Color(0xFFE5A72E), size: 26),
          ),
          title: Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (batch.isNotEmpty)
                Text(
                  'Batch: $batch',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              if (createdBy.isNotEmpty)
                Text(
                  'By: $createdBy',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              if (teamMembers.isNotEmpty)
                Text(
                  'Team: $teamMembers',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
            ],
          ),
          children: [
            if (description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Text(
                  description,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ),
            if (files.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No files attached',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...files.map<Widget>((file) {
                final displayName =
                    file['displayName'] ?? file['fileName'] ?? 'Unknown';
                final fName = file['fileName'] ?? '';
                final fileSize = file['size'] ?? 0;
                final sizeStr =
                    fileSize > 1048576
                        ? '${(fileSize / 1048576).toStringAsFixed(1)} MB'
                        : '${(fileSize / 1024).toStringAsFixed(1)} KB';
                return ListTile(
                  onTap: () {
                    if (projectId != null && fName.isNotEmpty) {
                      _openFile(projectId, fName, displayName);
                    }
                  },
                  leading: const Icon(
                    Icons.insert_drive_file,
                    color: Color(0xFFE5A72E),
                  ),
                  title: Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    sizeStr,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  trailing: const Icon(
                    Icons.open_in_new,
                    size: 18,
                    color: Colors.grey,
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }
}
