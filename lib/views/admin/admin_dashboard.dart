import 'package:flutter/material.dart';
import 'package:project_management/services/admin_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AdminService _adminService = AdminService();
  Map<String, dynamic>? stats;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => isLoading = true);
    final data = await _adminService.getDashboardStats();
    if (mounted) {
      setState(() {
        stats = data;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE5A72E)),
      );
    }

    if (stats == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Failed to load dashboard data',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadStats,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE5A72E),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStats,
      color: const Color(0xFFE5A72E),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================== OVERVIEW CARDS ====================
            const Text(
              'Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1E2D),
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount =
                    constraints.maxWidth > 1000
                        ? 4
                        : constraints.maxWidth > 600
                        ? 3
                        : 2;
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.6,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStatCard(
                      'Total Users',
                      '${stats!['totalUsers'] ?? 0}',
                      Icons.people_rounded,
                      const Color(0xFF6C63FF),
                    ),
                    _buildStatCard(
                      'Students',
                      '${stats!['totalStudents'] ?? 0}',
                      Icons.school_rounded,
                      const Color(0xFF00BFA6),
                    ),
                    _buildStatCard(
                      'Teachers',
                      '${stats!['totalTeachers'] ?? 0}',
                      Icons.person_rounded,
                      const Color(0xFFFF6B6B),
                    ),
                    _buildStatCard(
                      'Total Projects',
                      '${stats!['totalProjects'] ?? 0}',
                      Icons.folder_rounded,
                      const Color(0xFFE5A72E),
                    ),
                    _buildStatCard(
                      'Completed',
                      '${stats!['completedProjects'] ?? 0}',
                      Icons.check_circle_rounded,
                      const Color(0xFF4CAF50),
                    ),
                    _buildStatCard(
                      'Ongoing',
                      '${stats!['ongoingProjects'] ?? 0}',
                      Icons.pending_rounded,
                      const Color(0xFFFF9800),
                    ),
                    _buildStatCard(
                      'Total Files',
                      '${stats!['totalFiles'] ?? 0}',
                      Icons.insert_drive_file_rounded,
                      const Color(0xFF2196F3),
                    ),
                    _buildStatCard(
                      'Notifications',
                      '${stats!['totalNotifications'] ?? 0}',
                      Icons.notifications_rounded,
                      const Color(0xFF9C27B0),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),

            // ==================== RECENT ACTIVITY ====================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
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
                      const Icon(
                        Icons.trending_up_rounded,
                        color: Color(0xFFE5A72E),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Quick Summary',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E1E2D),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryRow(
                    'New registrations (last 7 days)',
                    '${stats!['recentUsers'] ?? 0}',
                    Icons.person_add_rounded,
                    const Color(0xFF6C63FF),
                  ),
                  const Divider(height: 24),
                  _buildSummaryRow(
                    'Project completion rate',
                    _getCompletionRate(),
                    Icons.pie_chart_rounded,
                    const Color(0xFF4CAF50),
                  ),
                  const Divider(height: 24),
                  _buildSummaryRow(
                    'Student to Teacher ratio',
                    _getStudentTeacherRatio(),
                    Icons.balance_rounded,
                    const Color(0xFFFF9800),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCompletionRate() {
    final total = stats!['totalProjects'] ?? 0;
    final completed = stats!['completedProjects'] ?? 0;
    if (total == 0) return '0%';
    return '${((completed / total) * 100).toStringAsFixed(1)}%';
  }

  String _getStudentTeacherRatio() {
    final students = stats!['totalStudents'] ?? 0;
    final teachers = stats!['totalTeachers'] ?? 0;
    if (teachers == 0) return '$students : 0';
    return '$students : $teachers';
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E1E2D),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
