import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_management/config/api_config.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

// ================= DATA MODELS =================
class CompletedProject {
  final String id;
  final String title;
  final String abstraction;
  final String description;
  final String createdBy;
  final String batch;
  final String teamMembers;
  final String dateCompleted;
  final String status;
  final bool isStudent;

  CompletedProject({
    required this.id,
    required this.title,
    required this.abstraction,
    required this.description,
    required this.createdBy,
    required this.batch,
    required this.teamMembers,
    required this.dateCompleted,
    required this.status,
    required this.isStudent,
  });

  factory CompletedProject.fromJson(Map<String, dynamic> json) {
    return CompletedProject(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'Untitled Project',
      abstraction: json['abstraction'] ?? json['description'] ?? '',
      description: json['description'] ?? '',
      createdBy: json['createdBy'] ?? 'Anonymous',
      batch: json['batch'] ?? '2024',
      teamMembers: json['teamMembers'] ?? 'Solo',
      dateCompleted: json['dateCompleted'] ?? DateTime.now().toString(),
      status: json['status'] ?? 'Completed',
      isStudent: json['isStudent'] ?? false,
    );
  }
}

// ================= PREVIOUS PROJECTS SCREEN =================
class PreviousProjectsScreen extends StatefulWidget {
  const PreviousProjectsScreen({super.key});

  @override
  State<PreviousProjectsScreen> createState() => _PreviousProjectsScreenState();
}

class _PreviousProjectsScreenState extends State<PreviousProjectsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<CompletedProject> myProjects = [];
  List<CompletedProject> seniorProjects = [];
  bool isLoading = true;
  String? currentUserEmail;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProjects();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      currentUserEmail = prefs.getString('email');

      print('DEBUG: Current user email = $currentUserEmail');

      // Fetch completed projects from backend
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/Projects/completed'))
          .timeout(const Duration(seconds: 10));

      print('DEBUG: Fetch completed projects status = ${response.statusCode}');
      print('DEBUG: Response body = ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('DEBUG: Total projects fetched = ${data.length}');

        setState(() {
          myProjects =
              data
                  .where((p) {
                    final project = CompletedProject.fromJson(p);
                    print(
                      'DEBUG: Checking project - createdBy: ${project.createdBy}, currentEmail: $currentUserEmail, match: ${project.createdBy.toLowerCase() == currentUserEmail?.toLowerCase()}',
                    );
                    return project.createdBy.toLowerCase() ==
                        currentUserEmail?.toLowerCase();
                  })
                  .map((p) => CompletedProject.fromJson(p))
                  .toList();
          seniorProjects =
              data
                  .where((p) {
                    final project = CompletedProject.fromJson(p);
                    return project.createdBy.toLowerCase() !=
                        currentUserEmail?.toLowerCase();
                  })
                  .map((p) => CompletedProject.fromJson(p))
                  .toList();
          isLoading = false;
        });

        print(
          'DEBUG: My projects count = ${myProjects.length}, Senior projects count = ${seniorProjects.length}',
        );
      } else {
        print('DEBUG: Failed to fetch, loading mock data');
        // Load mock data on error
        _loadMockProjects();
      }
    } catch (e, stacktrace) {
      print('Error loading projects: $e');
      print('Stacktrace: $stacktrace');
      _loadMockProjects();
    }
  }

  Future<void> _downloadProjectFile(CompletedProject project) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        _showSnackBar('User not authenticated');
        return;
      }

      _showSnackBar('Fetching project files...');

      // Fetch files list for this project
      final filesResponse = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/Projects/${project.id}/files'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));

      print('DEBUG: Files response status = ${filesResponse.statusCode}');
      print('DEBUG: Files response body = ${filesResponse.body}');

      if (filesResponse.statusCode == 200) {
        final fileData = jsonDecode(filesResponse.body);
        print('DEBUG: Parsed file data = $fileData');
        final files = fileData['files'] as List<dynamic>?;

        if (files == null || files.isEmpty) {
          _showSnackBar('No files available for this project');
          return;
        }

        // Get the first file (you can modify this to show a list)
        final file = files.first as Map<String, dynamic>;
        final fileName = file['fileName'] as String?;

        if (fileName == null) {
          _showSnackBar('File information not available');
          return;
        }

        _showSnackBar('Downloading ${file['displayName'] ?? fileName}...');

        // Download the file
        final downloadUrl =
            '${ApiConfig.baseUrl}/Projects/${project.id}/files/$fileName/download';

        final response = await http
            .get(
              Uri.parse(downloadUrl),
              headers: {'Authorization': 'Bearer $token'},
            )
            .timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          // Get downloads directory
          final directory = await getDownloadsDirectory();
          if (directory == null) {
            _showSnackBar('Downloads directory not available');
            return;
          }

          final displayName = file['displayName'] as String? ?? fileName;
          final filePath = '${directory.path}/$displayName';
          final fileToSave = File(filePath);

          await fileToSave.writeAsBytes(response.bodyBytes);
          _showSnackBar('File downloaded successfully to Downloads');
        } else {
          _showSnackBar('Failed to download file (${response.statusCode})');
        }
      } else {
        _showSnackBar('Failed to fetch files');
      }
    } catch (e) {
      print('Download error: $e');
      _showSnackBar('Error downloading file: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _loadMockProjects() {
    setState(() {
      myProjects = [
        CompletedProject(
          id: '1',
          title: 'Smart Chat System',
          abstraction:
              'An AI-powered chatbot system using NLP and machine learning. Features include conversation history, sentiment analysis, and multi-language support.',
          description:
              'A comprehensive chatbot implementation with advanced features.',
          createdBy: currentUserEmail ?? 'student@example.com',
          batch: '2024',
          teamMembers: 'Hudha Reem',
          dateCompleted: '2024-01-15',
          status: 'Completed',
          isStudent: true,
        ),
      ];
      seniorProjects = [
        CompletedProject(
          id: '2',
          title: 'E-Commerce Platform',
          abstraction:
              'Full-featured e-commerce platform with product catalog, shopping cart, and payment integration.',
          description: 'Advanced e-commerce system with AI recommendations.',
          createdBy: 'Ahmed Hassan',
          batch: '2023',
          teamMembers: 'Ahmed Hassan, Zainab',
          dateCompleted: '2023-12-10',
          status: 'Completed',
          isStudent: false,
        ),
        CompletedProject(
          id: '3',
          title: 'Data Analytics Dashboard',
          abstraction:
              'Real-time analytics dashboard for visualizing business metrics and KPIs.',
          description:
              'Comprehensive analytics system with predictive features.',
          createdBy: 'Fatima Ali',
          batch: '2023',
          teamMembers: 'Fatima Ali, Omar',
          dateCompleted: '2023-11-20',
          status: 'Completed',
          isStudent: false,
        ),
      ];
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFE5A72E),
        elevation: 0,
        title: const Text(
          'Completed Projects',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.black,
          unselectedLabelColor: Colors.black54,
          labelColor: Colors.black,
          tabs: const [Tab(text: 'My Projects'), Tab(text: 'Projects')],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () => _loadProjects(),
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadProjects,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // My Projects Tab
                    _buildProjectsList(myProjects, isMyProjects: true),
                    // Senior Projects Tab
                    _buildProjectsList(seniorProjects, isMyProjects: false),
                  ],
                ),
              ),
    );
  }

  Widget _buildProjectsList(
    List<CompletedProject> projects, {
    required bool isMyProjects,
  }) {
    if (projects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isMyProjects ? Icons.folder_open : Icons.school,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              isMyProjects
                  ? 'No completed projects yet'
                  : 'No senior projects available',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        return _buildProjectCard(project);
      },
    );
  }

  Widget _buildProjectCard(CompletedProject project) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5A72E), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project Title
            Text(
              project.title,
              style: GoogleFonts.poppins(
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
            const SizedBox(height: 12),

            // Project Info Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'By: ${project.createdBy}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Batch: ${project.batch}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Team Members: ${project.teamMembers}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5A72E).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    project.status,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE5A72E),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Abstraction
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE5A72E).withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFE5A72E).withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Abstraction',
                    style: GoogleFonts.poppins(
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    project.abstraction,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                      height: 1.6,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Date and View Button Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  project.dateCompleted,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _showProjectDetails(context, project);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE5A72E),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text(
                    'View Details',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showProjectDetails(BuildContext context, CompletedProject project) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(project.title),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'By: ${project.createdBy}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text('Batch: ${project.batch}'),
                  const SizedBox(height: 8),
                  Text('Team Members: ${project.teamMembers}'),
                  const SizedBox(height: 8),
                  Text('Completed: ${project.dateCompleted}'),
                  const SizedBox(height: 16),
                  const Text(
                    'Abstraction:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(project.abstraction),
                ],
              ),
            ),
            actions: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _downloadProjectFile(project);
                },
                icon: const Icon(Icons.download),
                label: const Text('Download PDF'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }
}
