import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:project_management/config/api_config.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({Key? key}) : super(key: key);

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
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
    _fetchPreviousYearProjects();
  }

  Future<void> _fetchPreviousYearProjects() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/projects/previous-year'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['projects'] as List;
        setState(() {
          allProjects = list.map((p) => Map<String, dynamic>.from(p)).toList();
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
      appBar: AppBar(
        leading: Padding(padding: const EdgeInsets.only(top: 15, left: 15)),
        title: Padding(
          padding: const EdgeInsets.only(left: 0, top: 15),
          child: const Text(
            "Previous Year Projects",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
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
                              onRefresh: _fetchPreviousYearProjects,
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

  // PROJECT CARD UI
  Widget _buildProjectCard(Map<String, dynamic> project) {
    final files = (project['files'] as List?) ?? [];
    final projectId = project['id'];
    final title = project['title'] ?? 'Untitled';
    final batch = project['batch'] ?? '';
    final createdBy = project['createdBy'] ?? '';
    final teamMembers = project['teamMembers'] ?? '';

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
                  leading: SvgPicture.asset(
                    'assets/icons/image.svg',
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
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
