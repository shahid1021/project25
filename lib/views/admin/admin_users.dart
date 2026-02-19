import 'package:flutter/material.dart';
import 'package:project_management/services/admin_service.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final AdminService _adminService = AdminService();
  List<dynamic> users = [];
  List<dynamic> filteredUsers = [];
  bool isLoading = true;
  String searchQuery = '';
  String filterRole = 'All';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => isLoading = true);
    final data = await _adminService.getAllUsers();
    if (mounted) {
      setState(() {
        users = data;
        _applyFilters();
        isLoading = false;
      });
    }
  }

  void _applyFilters() {
    filteredUsers =
        users.where((user) {
          final matchesSearch =
              searchQuery.isEmpty ||
              '${user['firstName']} ${user['lastName']}'.toLowerCase().contains(
                searchQuery.toLowerCase(),
              ) ||
              (user['email'] ?? '').toString().toLowerCase().contains(
                searchQuery.toLowerCase(),
              );

          final matchesRole = filterRole == 'All' || user['role'] == filterRole;

          return matchesSearch && matchesRole;
        }).toList();
  }

  Future<void> _changeRole(int userId, String currentRole) async {
    final roles = ['Student', 'Teacher', 'Admin'];
    final newRole = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Change Role'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  roles
                      .map(
                        (role) => RadioListTile<String>(
                          title: Text(role),
                          value: role,
                          groupValue: currentRole,
                          activeColor: const Color(0xFFE5A72E),
                          onChanged: (val) => Navigator.pop(context, val),
                        ),
                      )
                      .toList(),
            ),
          ),
    );

    if (newRole != null && newRole != currentRole) {
      final success = await _adminService.updateUserRole(userId, newRole);
      if (success) {
        _loadUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Role updated to $newRole'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleApproval(int userId, bool isApproved) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(isApproved ? 'Block User?' : 'Unblock User?'),
            content: Text(
              isApproved
                  ? 'This user will no longer be able to login.'
                  : 'This user will be able to login again.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isApproved ? Colors.red : const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text(isApproved ? 'Block' : 'Unblock'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      final success = await _adminService.toggleUserApproval(userId);
      if (success) {
        _loadUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isApproved
                    ? 'User has been blocked'
                    : 'User has been unblocked',
              ),
              backgroundColor: isApproved ? Colors.red : Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Failed to update user status. Check API connection.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteUser(int userId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete User'),
            content: Text(
              'Are you sure you want to delete "$name"? This cannot be undone.',
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
      final success = await _adminService.deleteUser(userId);
      if (success) {
        _loadUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User deleted'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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
                    hintText: 'Search by name or email...',
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
                    value: filterRole,
                    items:
                        ['All', 'Student', 'Teacher', 'Admin']
                            .map(
                              (r) => DropdownMenuItem(value: r, child: Text(r)),
                            )
                            .toList(),
                    onChanged: (val) {
                      setState(() {
                        filterRole = val ?? 'All';
                        _applyFilters();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: _loadUsers,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Refresh',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Count
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${filteredUsers.length} users found',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          const SizedBox(height: 12),

          // ==================== USERS TABLE ====================
          Expanded(
            child: Container(
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: WidgetStateColor.resolveWith(
                        (_) => const Color(0xFF1E1E2D),
                      ),
                      headingTextStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      dataRowMinHeight: 56,
                      dataRowMaxHeight: 56,
                      columnSpacing: 32,
                      columns: const [
                        DataColumn(label: Text('ID')),
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Email')),
                        DataColumn(label: Text('Role')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Joined')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows:
                          filteredUsers.map((user) {
                            final name =
                                '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'
                                    .trim();
                            final isApproved = user['isApproved'] ?? true;
                            return DataRow(
                              cells: [
                                DataCell(Text('${user['id']}')),
                                DataCell(
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundColor: _roleColor(
                                          user['role'] ?? '',
                                        ),
                                        child: Text(
                                          name.isNotEmpty
                                              ? name[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    user['email'] ?? '',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _roleColor(
                                        user['role'] ?? '',
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      user['role'] ?? '',
                                      style: TextStyle(
                                        color: _roleColor(user['role'] ?? ''),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isApproved
                                              ? Colors.green.withOpacity(0.1)
                                              : Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      isApproved ? 'Active' : 'Blocked',
                                      style: TextStyle(
                                        color:
                                            isApproved
                                                ? Colors.green
                                                : Colors.red,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    _formatDate(user['createdAt']),
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _actionButton(
                                        Icons.swap_horiz_rounded,
                                        'Change Role',
                                        const Color(0xFF6C63FF),
                                        () => _changeRole(
                                          user['id'],
                                          user['role'] ?? 'Student',
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      _actionButton(
                                        isApproved
                                            ? Icons.block_rounded
                                            : Icons.check_circle_outline,
                                        isApproved ? 'Block' : 'Unblock',
                                        isApproved
                                            ? Colors.orange
                                            : Colors.green,
                                        () => _toggleApproval(
                                          user['id'],
                                          isApproved,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      _actionButton(
                                        Icons.delete_outline_rounded,
                                        'Delete',
                                        Colors.red,
                                        () => _deleteUser(user['id'], name),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    IconData icon,
    String tooltip,
    Color color,
    VoidCallback onTap,
  ) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'Admin':
        return const Color(0xFFE5A72E);
      case 'Teacher':
        return const Color(0xFFFF6B6B);
      case 'Student':
        return const Color(0xFF6C63FF);
      default:
        return Colors.grey;
    }
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr.toString());
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateStr.toString();
    }
  }
}
