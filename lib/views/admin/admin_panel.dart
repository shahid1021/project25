import 'package:flutter/material.dart';
import 'package:project_management/views/admin/admin_dashboard.dart';
import 'package:project_management/views/admin/admin_users.dart';
import 'package:project_management/views/admin/admin_projects.dart';
import 'package:project_management/views/admin/admin_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_management/views/auth/login_screen.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  int _selectedIndex = 0;
  String adminName = '';

  final List<Widget> _pages = const [
    AdminDashboard(),
    AdminUsersPage(),
    AdminProjectsPage(),
    AdminNotificationsPage(),
  ];

  final List<String> _titles = [
    'Dashboard',
    'User Management',
    'Project Management',
    'Notifications',
  ];

  final List<IconData> _icons = [
    Icons.dashboard_rounded,
    Icons.people_rounded,
    Icons.folder_rounded,
    Icons.notifications_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _loadAdminName();
  }

  Future<void> _loadAdminName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final first = prefs.getString('firstName') ?? '';
      final last = prefs.getString('lastName') ?? '';
      adminName = '$first $last'.trim();
      if (adminName.isEmpty) adminName = 'Admin';
    });
  }

  void _showLogoutPopup(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Logout"),
            content: const Text("Are you sure you want to logout?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE5A72E),
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (_) => false,
                  );
                },
                child: const Text("Logout"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Row(
        children: [
          // ==================== SIDEBAR ====================
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isWide ? 260 : 72,
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E2D),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Logo/Title
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  child:
                      isWide
                          ? Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE5A72E),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.admin_panel_settings,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Admin Panel',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          )
                          : Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5A72E),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.admin_panel_settings,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                ),

                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 10),

                // Nav items
                ...List.generate(_titles.length, (index) {
                  final isSelected = _selectedIndex == index;
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => setState(() => _selectedIndex = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(
                            horizontal: isWide ? 16 : 12,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? const Color(0xFFE5A72E).withOpacity(0.15)
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border:
                                isSelected
                                    ? Border.all(
                                      color: const Color(
                                        0xFFE5A72E,
                                      ).withOpacity(0.3),
                                    )
                                    : null,
                          ),
                          child:
                              isWide
                                  ? Row(
                                    children: [
                                      Icon(
                                        _icons[index],
                                        color:
                                            isSelected
                                                ? const Color(0xFFE5A72E)
                                                : Colors.white54,
                                        size: 22,
                                      ),
                                      const SizedBox(width: 14),
                                      Text(
                                        _titles[index],
                                        style: TextStyle(
                                          color:
                                              isSelected
                                                  ? Colors.white
                                                  : Colors.white54,
                                          fontWeight:
                                              isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  )
                                  : Tooltip(
                                    message: _titles[index],
                                    child: Icon(
                                      _icons[index],
                                      color:
                                          isSelected
                                              ? const Color(0xFFE5A72E)
                                              : Colors.white54,
                                      size: 22,
                                    ),
                                  ),
                        ),
                      ),
                    ),
                  );
                }),

                const Spacer(),

                // Admin info & Logout
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Divider(color: Colors.white24, height: 1),
                      const SizedBox(height: 12),
                      if (isWide)
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: const Color(0xFFE5A72E),
                              child: Text(
                                adminName.isNotEmpty
                                    ? adminName[0].toUpperCase()
                                    : 'A',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                adminName,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 12),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => _showLogoutPopup(context),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.logout_rounded,
                                  color: Colors.redAccent,
                                  size: 18,
                                ),
                                if (isWide) ...[
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Logout',
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ==================== MAIN CONTENT ====================
          Expanded(
            child: Column(
              children: [
                // Top bar
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Text(
                        _titles[_selectedIndex],
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E1E2D),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Welcome, $adminName',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 16),
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFFE5A72E),
                        child: Text(
                          adminName.isNotEmpty
                              ? adminName[0].toUpperCase()
                              : 'A',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Page content
                Expanded(child: _pages[_selectedIndex]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
