import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:project_management/config/api_config.dart';

class AdminTrendingProjectsPage extends StatefulWidget {
  const AdminTrendingProjectsPage({super.key});

  @override
  State<AdminTrendingProjectsPage> createState() =>
      _AdminTrendingProjectsPageState();
}

class _AdminTrendingProjectsPageState extends State<AdminTrendingProjectsPage> {
  List<dynamic> trendingProjects = [];
  bool isLoading = true;
  String? errorMessage;

  // Form fields
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _abstractionController = TextEditingController();
  bool showAddForm = false;

  // PDF file pick state
  String? _pickedFileName;
  Uint8List? _pickedFileBytes;

  @override
  void initState() {
    super.initState();
    fetchTrendingProjects();
  }

  Future<void> fetchTrendingProjects() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/admin/standalone-trending-projects'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          trendingProjects = data['projects'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load trending projects';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  Future<void> deleteTrendingProject(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/admin/standalone-trending-projects/$id'),
    );
    if (response.statusCode == 200) {
      fetchTrendingProjects();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to remove trending project')),
      );
    }
  }

  Future<void> _pickPdfFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx'],
      withData: true,
    );
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _pickedFileName = result.files.single.name;
        _pickedFileBytes = result.files.single.bytes;
      });
    }
  }

  void _clearPickedFile() {
    setState(() {
      _pickedFileName = null;
      _pickedFileBytes = null;
    });
  }

  Future<void> addTrendingProject() async {
    final title = _titleController.text.trim();
    final abstraction = _abstractionController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Title is required')));
      return;
    }

    if (abstraction.isEmpty && _pickedFileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Provide an abstraction or upload a PDF file'),
        ),
      );
      return;
    }

    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/admin/standalone-trending-projects',
      );
      final request = http.MultipartRequest('POST', uri);

      request.fields['title'] = title;
      if (abstraction.isNotEmpty) {
        request.fields['abstraction'] = abstraction;
      }

      if (_pickedFileBytes != null && _pickedFileName != null) {
        final extension = _pickedFileName!.split('.').last.toLowerCase();
        final mimeType =
            extension == 'pdf'
                ? MediaType('application', 'pdf')
                : MediaType(
                  'application',
                  'vnd.openxmlformats-officedocument.wordprocessingml.document',
                );

        request.files.add(
          http.MultipartFile.fromBytes(
            'File',
            _pickedFileBytes!,
            filename: _pickedFileName!,
            contentType: mimeType,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        setState(() {
          showAddForm = false;
          _titleController.clear();
          _abstractionController.clear();
          _clearPickedFile();
        });
        fetchTrendingProjects();
      } else {
        final body = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(body['message'] ?? 'Failed to add trending project'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Trending Projects',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      showAddForm = !showAddForm;
                      if (!showAddForm) {
                        _titleController.clear();
                        _abstractionController.clear();
                        _clearPickedFile();
                      }
                    });
                  },
                  child: Text(
                    showAddForm ? 'Cancel' : 'Add New Trending Project',
                  ),
                ),
              ],
            ),
          ),
          if (showAddForm)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Project Title',
                    ),
                  ),
                  TextField(
                    controller: _abstractionController,
                    decoration: const InputDecoration(
                      labelText:
                          'Project Abstraction (optional if PDF uploaded)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickPdfFile,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Upload PDF / DOCX'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (_pickedFileName != null)
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.picture_as_pdf,
                                color: Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  _pickedFileName!,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  size: 18,
                                  color: Colors.red,
                                ),
                                onPressed: _clearPickedFile,
                                tooltip: 'Remove file',
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: addTrendingProject,
                    child: const Text('Add Project'),
                  ),
                ],
              ),
            ),
          Expanded(
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : errorMessage != null
                    ? Center(child: Text(errorMessage!))
                    : ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: trendingProjects.length,
                      itemBuilder: (context, index) {
                        final project = trendingProjects[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(project['title'] ?? ''),
                            subtitle: Text(project['abstraction'] ?? ''),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.remove_circle,
                                color: Colors.red,
                              ),
                              tooltip: 'Remove from Trending',
                              onPressed:
                                  () => deleteTrendingProject(project['id']),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
