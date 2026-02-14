import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:project_management/config/api_config.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  String? selectedFileName;
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
    if (selectedFileName == null || extractedText == null) {
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
      // Call Backend AI API to detect duplicates
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/ai/detect-duplicate'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'abstractText': extractedText,
              'filePath': selectedFileName,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
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
            content: Text('Error: ${response.statusCode} - ${response.body}'),
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
  bool showAllNewKeywords = false;
  bool showAllMatchingKeywords = false;

  @override
  Widget build(BuildContext context) {
    final isDuplicate = widget.result['isDuplicate'] ?? false;
    final similarProjects = widget.result['similarProjects'] ?? [];
    final matchingKeywords = widget.result['matchingKeywords'] ?? [];
    final newKeywords = widget.result['newKeywords'] ?? [];
    final newFeatures = widget.result['newFeatures'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Analysis Results',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Header
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

              // Similar Projects Section
              if (isDuplicate && similarProjects.isNotEmpty) ...[
                const Text(
                  'Similar Projects',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...similarProjects.asMap().entries.map((entry) {
                  final project = entry.value;
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                project['name'] ?? 'Project',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5A72E).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Similarity: ${project['similarity'] ?? 0}%',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE5A72E),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Batch: ${project['batch'] ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Group: ${project['group'] ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                const SizedBox(height: 24),
              ],

              // New Keywords Section
              if (newKeywords.isNotEmpty) ...[
                const Text(
                  'New Keywords (Not Found in Existing Projects)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...newKeywords
                        .take(showAllNewKeywords ? newKeywords.length : 6)
                        .map<Widget>(
                          (keyword) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.3),
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              keyword.toString(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    if (newKeywords.length > 6)
                      GestureDetector(
                        onTap:
                            () => setState(
                              () => showAllNewKeywords = !showAllNewKeywords,
                            ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.3),
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            showAllNewKeywords
                                ? 'Less'
                                : '+${newKeywords.length - 6} More',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // Matching Keywords Section
              if (matchingKeywords.isNotEmpty) ...[
                const Text(
                  'Matching Keywords (Found in Existing Projects)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...matchingKeywords
                        .take(
                          showAllMatchingKeywords ? matchingKeywords.length : 6,
                        )
                        .map<Widget>(
                          (keyword) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.3),
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              keyword.toString(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    if (matchingKeywords.length > 6)
                      GestureDetector(
                        onTap:
                            () => setState(
                              () =>
                                  showAllMatchingKeywords =
                                      !showAllMatchingKeywords,
                            ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.3),
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            showAllMatchingKeywords
                                ? 'Less'
                                : '+${matchingKeywords.length - 6} More',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // New Features Section
              if (newFeatures.isNotEmpty) ...[
                const Text(
                  'New Features / Differences',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      newFeatures
                          .map<Widget>(
                            (feature) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.3),
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                feature.toString(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                ),
                const SizedBox(height: 24),
              ],

              // Detailed Analysis
              if (widget.result['analysis'] != null) ...[
                const Text(
                  'Detailed Analysis',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    widget.result['analysis'].toString(),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.6,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back to Upload'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Save Analysis'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE5A72E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Analysis saved successfully'),
                          ),
                        );
                      },
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
}
