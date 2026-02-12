import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:project_management/views/students/about_page.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isDarkMode = false;

  Future<void> _sendEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'smrtlng746@gmail.com',
      queryParameters: {'subject': 'Support - Project Management App'},
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not launch email: $e')));
    }
  }

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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AboutPage(),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 10),
                    _buildBoxItem(
                      icon: Icons.info_outline,
                      title: 'About',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AboutPage(),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 10),
                    _buildBoxItem(
                      icon: Icons.help_outline,
                      title: 'Help',
                      onTap: () {
                        _sendEmail();
                      },
                    ),
                    SizedBox(height: 10),
                    _buildThemeToggleBox(),
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

  Widget _buildThemeToggleBox() {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Color(0xFFE5A72E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE8D89A)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isDarkMode ? Icons.dark_mode : Icons.light_mode,
                size: 24,
                color: Colors.black87,
              ),
              const SizedBox(width: 16),
              Text(
                'Change Theme',
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                isDarkMode = !isDarkMode;
              });
              // You can add theme provider integration here
            },
            child: Container(
              width: 50,
              height: 28,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.black87 : Colors.white70,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black87, width: 1),
              ),
              child: Stack(
                alignment:
                    isDarkMode ? Alignment.centerRight : Alignment.centerLeft,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(2),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.white : Colors.yellow,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isDarkMode ? Icons.nightlight_round : Icons.wb_sunny,
                        size: 14,
                        color: isDarkMode ? Colors.black : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
