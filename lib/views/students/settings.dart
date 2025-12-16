import 'package:flutter/material.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(top: 15, left: 15),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black, size: 30),
            onPressed: () {
              Navigator.pop(context); // Go back to previous page
            },
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(left: 0, top: 15),
          child: const Text(
            "Settings",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 30,
            ),
          ),
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(padding: EdgeInsets.all(16.0)),
              Container(
                child: Column(
                  children: [
                    _buildBoxItem(
                      icon: Icons.share_outlined,
                      title: 'Share',
                      onTap: () {
                        // Handle share
                      },
                    ),
                    SizedBox(height: 10),
                    _buildBoxItem(
                      icon: Icons.info_outline,
                      title: 'About',
                      onTap: () {
                        // Handle about
                      },
                    ),
                    SizedBox(height: 10),
                    _buildBoxItem(
                      icon: Icons.help_outline,
                      title: 'Help',
                      onTap: () {
                        // Handle help
                      },
                    ),
                    SizedBox(height: 10),
                    _buildBoxItem(
                      icon: Icons.logout,
                      title: 'Logout',
                      onTap: () {
                        // Handle logout
                      },
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

  Widget _buildBoxItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12), // GAP BETWEEN ITEMS
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Color(0xFFE5A72E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFFE8D89A)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Colors.black87),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
