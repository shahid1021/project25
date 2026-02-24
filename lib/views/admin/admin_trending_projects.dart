import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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

  Future<void> addTrendingProject() async {
    final title = _titleController.text.trim();
    final abstraction = _abstractionController.text.trim();
    if (title.isEmpty || abstraction.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and abstraction required')),
      );
      return;
    }
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/admin/standalone-trending-projects'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'title': title, 'abstraction': abstraction}),
    );
    if (response.statusCode == 200) {
      setState(() {
        showAddForm = false;
        _titleController.clear();
        _abstractionController.clear();
      });
      fetchTrendingProjects();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add trending project')),
      );
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
                      labelText: 'Project Abstraction',
                    ),
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
