import 'package:project_management/views/students/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:project_management/views/students/notfication_std.dart';
import 'package:project_management/views/students/profile.dart';
import 'package:project_management/views/students/projects.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int currentIndex = 0;

  final List<Widget> screens = [
    Homepage(),
    UploadScreen(),
    NotificationsScreen(),
    StudentProfile(),
  ];

  final Duration animDuration = Duration(milliseconds: 300);

  @override
  Widget build(BuildContext context) {
    // ******** MEDIA QUERY ********
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    // *****************************

    double itemWidth = width / 4;
    double circleSize = width * 0.12; // 12% of screen width
    double iconSize = width * 0.06; // 6% of width

    return Scaffold(
      body: screens[currentIndex],

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 255, 255, 255),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        height: height * 0.10, // 10% of screen height

        child: Stack(
          children: [
            // ********* SLIDING CIRCLE *********
            AnimatedPositioned(
              duration: animDuration,
              curve: Curves.easeOutBack,
              left:
                  currentIndex * itemWidth + (itemWidth / 2) - (circleSize / 2),
              top: (height * 0.10) / 2 - (circleSize / 2),
              child: Container(
                height: circleSize,
                width: circleSize,
                decoration: BoxDecoration(
                  color: Color(0xFFE5A72E),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // ********** ICON ROW **********
            Row(
              children: [
                navItem(Icons.home_sharp, 0, itemWidth, iconSize),
                navItem(Icons.folder_rounded, 1, itemWidth, iconSize),
                navItem(Icons.notifications_rounded, 2, itemWidth, iconSize),
                navItem(Icons.person, 3, itemWidth, iconSize),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ********** NAV ITEM WITH SCALE **********
  Widget navItem(IconData icon, int index, double width, double iconSize) {
    bool isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          currentIndex = index;
        });
      },
      child: SizedBox(
        width: width,
        height: 90,
        child: Center(
          child: AnimatedScale(
            scale: isSelected ? 1.5 : 1.0,
            duration: animDuration,
            curve: Curves.easeOutBack,
            child: Icon(
              icon,
              size: iconSize,
              color: isSelected ? Colors.white : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}
