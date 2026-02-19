import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_management/services/teacher_project_service.dart';
import 'package:project_management/views/students/settings.dart';
import 'package:project_management/views/teacher/upload.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ================== TEAM MODEL ==================
class TeamProject {
  final int id;
  final String groupNumber;
  final String groupMembers;
  final String projectName;
  final List<bool> completionStages; // 10 boolean values for each stage

  TeamProject({
    required this.id,
    required this.groupNumber,
    required this.groupMembers,
    required this.projectName,
    List<bool>? completionStages,
  }) : completionStages = completionStages ?? List.filled(10, false);

  int get completionPercentage {
    int completed = completionStages.where((item) => item).length;
    return ((completed / 10) * 100).toInt();
  }

  bool get isCompleted => completionPercentage == 100;

  // Deserialize from API JSON
  factory TeamProject.fromMap(Map<String, dynamic> map) {
    return TeamProject(
      id: map['id'] ?? 0,
      groupNumber: map['groupNumber'] ?? '',
      groupMembers: map['groupMembers'] ?? '',
      projectName: map['projectName'] ?? '',
      completionStages: List<bool>.from(
        map['completionStages'] ?? List.filled(10, false),
      ),
    );
  }
}

class TeacherHome extends StatefulWidget {
  const TeacherHome({Key? key}) : super(key: key);

  @override
  State<TeacherHome> createState() => _TeacherHomeState();
}

class _TeacherHomeState extends State<TeacherHome> {
  String teacherName = '';
  String firstName = '';
  String lastName = '';
  String teacherEmail = '';
  List<TeamProject> teams = [];
  String? selectedGroupNumber;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadTeacherInfo();
  }

  Future<void> loadTeacherInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      firstName = prefs.getString('firstName') ?? '';
      lastName = prefs.getString('lastName') ?? '';
      teacherName = '$firstName $lastName'.trim();
      teacherEmail = prefs.getString('email') ?? '';
    });
    if (teacherEmail.isNotEmpty) {
      loadProjects();
    }
  }

  Future<void> loadProjects() async {
    setState(() => isLoading = true);
    try {
      final projectsList = await TeacherProjectService.getProjects(
        teacherEmail,
      );
      setState(() {
        teams =
            projectsList
                .map(
                  (item) => TeamProject.fromMap(item as Map<String, dynamic>),
                )
                .toList();
      });
    } catch (e) {
      print('Error loading projects: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  int get totalGroups => teams.length;
  int get completedGroups => teams.where((t) => t.isCompleted).length;
  int get ongoingGroups => teams.where((t) => !t.isCompleted).length;

  void _addNewProject() {
    selectedGroupNumber = null; // Reset selection
    int? selectedMemberCount = null;
    List<TextEditingController> memberControllers = [];
    final projectNameController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: const Text('Add New Project'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<String>(
                          value: selectedGroupNumber,
                          hint: const Text('Select Group Number'),
                          decoration: InputDecoration(
                            labelText: 'Group Number',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          items: List.generate(
                            55,
                            (index) => DropdownMenuItem(
                              value: (index + 1).toString(),
                              child: Text('Group ${index + 1}'),
                            ),
                          ),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedGroupNumber = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          value: selectedMemberCount,
                          hint: const Text(' Number of Members'),
                          decoration: InputDecoration(
                            labelText: 'Number of Members',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          items: List.generate(
                            4,
                            (index) => DropdownMenuItem(
                              value: index + 1,
                              child: Text(
                                '${index + 1} Member${index + 1 > 1 ? 's' : ''}',
                              ),
                            ),
                          ),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedMemberCount = value;
                              // Create new controllers based on selected count
                              memberControllers.clear();
                              for (int i = 0; i < (value ?? 0); i++) {
                                memberControllers.add(TextEditingController());
                              }
                            });
                          },
                        ),
                        if (selectedMemberCount != null) ...[
                          const SizedBox(height: 16),
                          ...List.generate(
                            selectedMemberCount ?? 0,
                            (index) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: TextField(
                                controller: memberControllers[index],
                                decoration: InputDecoration(
                                  labelText: 'Member ${index + 1} Name',
                                  hintText: 'Enter member name',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        TextField(
                          controller: projectNameController,
                          decoration: InputDecoration(
                            labelText: 'Project Name',
                            hintText: 'e.g., AI Chatbot',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[700],
                      ),
                      onPressed: () async {
                        if (selectedGroupNumber == null ||
                            selectedMemberCount == null ||
                            memberControllers.any((c) => c.text.isEmpty) ||
                            projectNameController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please fill all fields'),
                            ),
                          );
                          return;
                        }

                        final groupMembers = memberControllers
                            .map((c) => c.text)
                            .join(', ');

                        Navigator.pop(context);

                        final result =
                            await TeacherProjectService.createProject(
                              teacherEmail: teacherEmail,
                              groupNumber: selectedGroupNumber!,
                              groupMembers: groupMembers,
                              projectName: projectNameController.text,
                            );

                        if (result != null) {
                          setState(() {
                            teams.add(TeamProject.fromMap(result));
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Project created successfully'),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to create project'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: const Text('Create'),
                    ),
                  ],
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            teacherName.isEmpty ? 'Hello' : 'Hello, $teacherName',
            style: GoogleFonts.poppins(
              textStyle: const TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Cards
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'No of Groups',
                      totalGroups.toString(),
                      Colors.amber[700]!,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      'Ongoing\nProjects',
                      ongoingGroups.toString(),
                      Colors.amber[700]!,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      'Completed\nProjects',
                      completedGroups.toString(),
                      Colors.amber[700]!,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Heading with counter
              if (teams.isNotEmpty) ...[
                const Text(
                  'On-going Projects',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Progress Items
                ...teams
                    .map(
                      (team) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => ProjectDetailsPage(
                                      team: team,
                                      onUpdate: (updatedTeam) {
                                        setState(() {
                                          final index = teams.indexWhere(
                                            (t) => t.id == updatedTeam.id,
                                          );
                                          if (index != -1) {
                                            teams[index] = updatedTeam;
                                          }
                                        });
                                        // Save stages to database
                                        TeacherProjectService.updateStages(
                                          updatedTeam.id,
                                          updatedTeam.completionStages,
                                        );
                                      },
                                      onDelete: (teamId) async {
                                        final success =
                                            await TeacherProjectService.deleteProject(
                                              teamId,
                                            );
                                        if (success) {
                                          setState(() {
                                            teams.removeWhere(
                                              (t) => t.id == teamId,
                                            );
                                          });
                                          Navigator.pop(context);
                                        }
                                      },
                                    ),
                              ),
                            );
                          },
                          child: _buildProgressItem(
                            team.groupNumber,
                            team.projectName,
                            team.completionPercentage / 100,
                            isCompleted: team.isCompleted,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ] else ...[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.folder_open,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No current projects here',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewProject,
        backgroundColor: Colors.amber[700],
        child: const Icon(Icons.group_add, color: Colors.white),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String count, Color color) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem(
    String teamName,
    String projectName,
    double progress, {
    bool isCompleted = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.green.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? Colors.green : Colors.grey[300]!,
          width: isCompleted ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        teamName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isCompleted) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Completed',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    projectName,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                isCompleted ? Colors.green : Colors.amber[700]!,
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

// ================== PROJECT DETAILS PAGE ==================
class ProjectDetailsPage extends StatefulWidget {
  final TeamProject team;
  final Function(TeamProject) onUpdate;
  final Function(int)? onDelete;

  const ProjectDetailsPage({
    Key? key,
    required this.team,
    required this.onUpdate,
    this.onDelete,
  }) : super(key: key);

  @override
  State<ProjectDetailsPage> createState() => _ProjectDetailsPageState();
}

class _ProjectDetailsPageState extends State<ProjectDetailsPage> {
  late TeamProject team;

  final List<String> stageTitles = [
    'Idea Approved',
    'DFD Submitted',
    'Form Design Submitted',
    'First Review Attempted',
    'Table Design Submitted',
    'Third Review Attempted',
    'Demo Run Submitted',
    'Mock Viva Attempted',
    'Documentation',
    'Project Submitted',
  ];

  @override
  void initState() {
    super.initState();
    team = widget.team;
  }

  void _updateStage(int index, bool value) {
    setState(() {
      team.completionStages[index] = value;
      widget.onUpdate(team);
    });
  }

  void _deleteProject() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Project'),
            content: const Text(
              'Are you sure you want to delete this project? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE5A72E),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  widget.onDelete?.call(team.id);
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber[700],
        title: Text(team.projectName),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: _deleteProject,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Project Information
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Group: ${team.groupNumber}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Members:',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber[700],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${team.completionPercentage}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:
                          team.groupMembers
                              .split(',')
                              .map(
                                (member) => Padding(
                                  padding: const EdgeInsets.only(
                                    left: 16,
                                    bottom: 4,
                                  ),
                                  child: Text(
                                    '• ${member.trim()}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: team.completionPercentage / 100,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                        minHeight: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Completion Stages Checkboxes
              const Text(
                'Project Completion Stages',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              ...List.generate(stageTitles.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CheckboxListTile(
                    title: Text(stageTitles[index]),
                    value: team.completionStages[index],
                    onChanged: (value) {
                      _updateStage(index, value ?? false);
                    },
                    activeColor: Colors.green,
                    checkColor: Colors.white,
                    contentPadding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    tileColor:
                        team.completionStages[index]
                            ? Colors.green.withOpacity(0.1)
                            : Colors.white,
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
