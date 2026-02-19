import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:project_management/services/admin_service.dart';

class AdminProjectsPage extends StatefulWidget {
  const AdminProjectsPage({super.key});

  @override
  State<AdminProjectsPage> createState() => _AdminProjectsPageState();
}

class _AdminProjectsPageState extends State<AdminProjectsPage> {
  final AdminService _adminService = AdminService();
  List<dynamic> projects = [];
  List<dynamic> filteredProjects = [];
  bool isLoading = true;
  String searchQuery = '';
  String filterStatus = 'All';

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() => isLoading = true);
    final data = await _adminService.getAllProjects();
    if (mounted) {
      setState(() {
        projects = data;
        _applyFilters();
        isLoading = false;
      });
    }
  }

  void _applyFilters() {
    filteredProjects =
        projects.where((project) {
          final matchesSearch =
              searchQuery.isEmpty ||
              (project['title'] ?? '').toString().toLowerCase().contains(
                searchQuery.toLowerCase(),
              ) ||
              (project['createdBy'] ?? '').toString().toLowerCase().contains(
                searchQuery.toLowerCase(),
              );

          final matchesStatus =
              filterStatus == 'All' || project['status'] == filterStatus;

          return matchesSearch && matchesStatus;
        }).toList();
  }

  Future<void> _deleteProject(int projectId, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Project'),
            content: Text(
              'Are you sure you want to delete "$title" and all its files? This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      final success = await _adminService.deleteProject(projectId);
      if (success) {
        _loadProjects();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Project deleted'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // ==================== ADD PROJECT DIALOG ====================
  void _showAddProjectDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final abstractCtrl = TextEditingController();
    final batchCtrl = TextEditingController();
    final createdByCtrl = TextEditingController();
    final teamCtrl = TextEditingController();
    PlatformFile? selectedFile;
    bool uploading = false;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    width: 550,
                    padding: const EdgeInsets.all(24),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.add_circle_rounded,
                                color: Color(0xFFE5A72E),
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Add Previous Year Project',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          _dialogField(
                            'Project Title *',
                            titleCtrl,
                            'Enter project title',
                          ),
                          const SizedBox(height: 12),
                          _dialogField(
                            'Description',
                            descCtrl,
                            'Enter project description',
                            maxLines: 3,
                          ),
                          const SizedBox(height: 12),
                          _dialogField(
                            'Abstract',
                            abstractCtrl,
                            'Enter project abstract',
                            maxLines: 3,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _dialogField(
                                  'Batch/Year *',
                                  batchCtrl,
                                  'e.g. 2024',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _dialogField(
                                  'Created By',
                                  createdByCtrl,
                                  'Student name',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _dialogField(
                            'Team Members',
                            teamCtrl,
                            'e.g. John, Jane, Mike',
                          ),
                          const SizedBox(height: 16),
                          // File picker
                          InkWell(
                            onTap: () async {
                              final result = await FilePicker.platform
                                  .pickFiles(
                                    type: FileType.any,
                                    withData: true,
                                  );
                              if (result != null && result.files.isNotEmpty) {
                                setDialogState(
                                  () => selectedFile = result.files.first,
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  style: BorderStyle.solid,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.grey.shade50,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    selectedFile != null
                                        ? Icons.insert_drive_file_rounded
                                        : Icons.cloud_upload_outlined,
                                    color:
                                        selectedFile != null
                                            ? Colors.green
                                            : Colors.grey,
                                    size: 32,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          selectedFile != null
                                              ? selectedFile!.name
                                              : 'Attach Project File (Optional)',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color:
                                                selectedFile != null
                                                    ? Colors.black
                                                    : Colors.grey.shade600,
                                          ),
                                        ),
                                        if (selectedFile != null)
                                          Text(
                                            '${(selectedFile!.size / 1024).toStringAsFixed(1)} KB',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (selectedFile != null)
                                    IconButton(
                                      onPressed:
                                          () => setDialogState(
                                            () => selectedFile = null,
                                          ),
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE5A72E),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed:
                                  uploading
                                      ? null
                                      : () async {
                                        if (titleCtrl.text.trim().isEmpty) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Project title is required',
                                              ),
                                            ),
                                          );
                                          return;
                                        }
                                        setDialogState(() => uploading = true);
                                        final success = await _adminService
                                            .uploadProject(
                                              title: titleCtrl.text.trim(),
                                              description: descCtrl.text.trim(),
                                              abstraction:
                                                  abstractCtrl.text.trim(),
                                              batch:
                                                  batchCtrl.text.trim().isEmpty
                                                      ? DateTime.now.year
                                                          .toString()
                                                      : batchCtrl.text.trim(),
                                              createdBy:
                                                  createdByCtrl.text
                                                          .trim()
                                                          .isEmpty
                                                      ? 'Previous Student'
                                                      : createdByCtrl.text
                                                          .trim(),
                                              teamMembers: teamCtrl.text.trim(),
                                              fileBytes: selectedFile?.bytes,
                                              fileName: selectedFile?.name,
                                            );
                                        setDialogState(() => uploading = false);
                                        if (success) {
                                          Navigator.pop(context);
                                          _loadProjects();
                                          if (mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Project added successfully!',
                                                ),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          }
                                        } else {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Failed to add project',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      },
                              child:
                                  uploading
                                      ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : const Text(
                                        'Add Project',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ),
    );
  }

  Widget _dialogField(
    String label,
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
        ),
      ],
    );
  }

  void _viewProjectDetails(Map<String, dynamic> project) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.folder_rounded,
                          color: Color(0xFFE5A72E),
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            project['title'] ?? 'Untitled',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _detailRow('Status', project['status'] ?? '-'),
                    _detailRow('Created By', project['createdBy'] ?? '-'),
                    _detailRow('Batch', project['batch'] ?? '-'),
                    _detailRow('Team Members', project['teamMembers'] ?? '-'),
                    _detailRow('Files', '${project['fileCount'] ?? 0}'),
                    _detailRow('Created', _formatDate(project['createdAt'])),
                    _detailRow(
                      'Completed',
                      _formatDate(project['dateCompleted']),
                    ),
                    if (project['description'] != null &&
                        project['description'].toString().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(project['description'] ?? ''),
                    ],
                    if (project['abstraction'] != null &&
                        project['abstraction'].toString().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Abstract',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(project['abstraction'] ?? ''),
                    ],
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE5A72E)),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // ==================== SEARCH & FILTER ====================
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  onChanged: (val) {
                    setState(() {
                      searchQuery = val;
                      _applyFilters();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by title or creator...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: filterStatus,
                    items:
                        ['All', 'Completed', 'In Progress']
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                    onChanged: (val) {
                      setState(() {
                        filterStatus = val ?? 'All';
                        _applyFilters();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: _loadProjects,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Refresh',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _showAddProjectDialog,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Project'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE5A72E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${filteredProjects.length} projects found',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          const SizedBox(height: 12),

          // ==================== PROJECTS GRID ====================
          Expanded(
            child:
                filteredProjects.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_off_rounded,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No projects found',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                    : LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount =
                            constraints.maxWidth > 1000
                                ? 3
                                : constraints.maxWidth > 600
                                ? 2
                                : 1;
                        return GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 1.8,
                              ),
                          itemCount: filteredProjects.length,
                          itemBuilder: (context, index) {
                            final project = filteredProjects[index];
                            return _buildProjectCard(project);
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> project) {
    final isCompleted = project['status'] == 'Completed';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isCompleted
                  ? Colors.green.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                  project['title'] ?? 'Untitled',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      isCompleted
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  project['status'] ?? '-',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isCompleted ? Colors.green : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'By: ${project['createdBy'] ?? '-'}',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          Text(
            'Batch: ${project['batch'] ?? '-'}  |  Files: ${project['fileCount'] ?? 0}',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed:
                    () =>
                        _viewProjectDetails(Map<String, dynamic>.from(project)),
                icon: const Icon(Icons.visibility_rounded, size: 16),
                label: const Text('View'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFE5A72E),
                ),
              ),
              TextButton.icon(
                onPressed:
                    () => _deleteProject(
                      project['projectId'],
                      project['title'] ?? 'Untitled',
                    ),
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                label: const Text('Delete'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr.toString());
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return '-';
    }
  }
}

extension on DateTime Function() {
  get year => null;
}
