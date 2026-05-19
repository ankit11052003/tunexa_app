import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'search_screen.dart';
import 'upload_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;

  final List<Widget> screens = [
    const HomeScreen(),
    const SearchScreen(),
    const UploadScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[currentIndex],

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,

          onTap: (index) {
            setState(() {
              currentIndex = index;
            });
          },

          backgroundColor: Colors.black,

          selectedItemColor: Colors.purple,

          unselectedItemColor: Colors.grey,

          type: BottomNavigationBarType.fixed,

          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),

            BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),

            BottomNavigationBarItem(icon: Icon(Icons.add_box), label: "Upload"),

            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          ],
        ),
      ),
    );
  }
}
