import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Widget featureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.purple),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("About"), backgroundColor: Colors.black),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Icon(Icons.flash_on, color: Colors.purple, size: 90),
            ),

            const SizedBox(height: 20),

            const Center(
              child: Text(
                "Tunexa",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ),

            const SizedBox(height: 10),

            const Center(
              child: Text(
                "Connect. Share. Create.",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "About this app",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            const Text(
              "Tunexa is a modern social media demo app built with Flutter and Firebase. It includes posts, likes, comments, profiles, messaging, notifications, search, saved posts and more.",
              style: TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 25),

            const Text(
              "Features",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            featureItem(Icons.login, "Firebase Authentication"),
            featureItem(Icons.article, "Text and image URL posts"),
            featureItem(Icons.favorite, "Likes and comments"),
            featureItem(Icons.person_add, "Follow system"),
            featureItem(Icons.message, "Real-time messages"),
            featureItem(Icons.notifications, "Notifications"),
            featureItem(Icons.bookmark, "Saved posts"),
            featureItem(Icons.search, "User search"),
            featureItem(Icons.video_library, "Reels UI"),
          ],
        ),
      ),
    );
  }
}
