import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'home_screen.dart';
import 'search_screen.dart';
import 'upload_screen.dart';
import 'profile_screen.dart';
import 'reels_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectedIndex = 0;

  final List<Widget> screens = const [
    HomeScreen(),
    SearchScreen(),
    ReelsScreen(),
    UploadScreen(),
    ProfileScreen(),
  ];

  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  Stream<int> unreadMessageCount() async* {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      yield 0;
      return;
    }

    yield* FirebaseFirestore.instance
        .collectionGroup("messages")
        .snapshots()
        .map((snapshot) {
          int count = 0;

          for (final doc in snapshot.docs) {
            final data = doc.data();

            if (data["receiverId"] == currentUser.uid &&
                data["isSeen"] == false) {
              count++;
            }
          }

          return count;
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[selectedIndex],

      bottomNavigationBar: StreamBuilder<int>(
        stream: unreadMessageCount(),
        builder: (context, snapshot) {
          final unreadCount = snapshot.data ?? 0;

          return BottomNavigationBar(
            currentIndex: selectedIndex,
            onTap: onItemTapped,
            type: BottomNavigationBarType.fixed,

            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: "Home",
              ),

              const BottomNavigationBarItem(
                icon: Icon(Icons.search),
                label: "Search",
              ),

              BottomNavigationBarItem(
                icon: Stack(
                  children: [
                    const Icon(Icons.video_library),

                    if (unreadCount > 0)
                      Positioned(
                        right: 0,
                        child: CircleAvatar(
                          radius: 8,
                          backgroundColor: Colors.red,
                          child: Text(
                            unreadCount > 9 ? "9+" : "$unreadCount",
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                label: "Reels",
              ),

              const BottomNavigationBarItem(
                icon: Icon(Icons.add_box),
                label: "Upload",
              ),

              const BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: "Profile",
              ),
            ],
          );
        },
      ),
    );
  }
}
