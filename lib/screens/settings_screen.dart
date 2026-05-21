import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'login_screen.dart';
import 'about_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> logoutUser(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  Future<void> unblockUser(String currentUserId, String blockedUserId) async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(currentUserId)
        .update({
          "blockedUsers": FieldValue.arrayRemove([blockedUserId]),
        });
  }

  void openBlockedUsers(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) {
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection("users")
              .doc(currentUser.uid)
              .snapshots(),
          builder: (context, snapshot) {
            final userData = snapshot.data?.data() as Map<String, dynamic>?;

            final blockedUsers = userData?["blockedUsers"] ?? [];

            if (blockedUsers.isEmpty) {
              return const SizedBox(
                height: 180,
                child: Center(child: Text("No blocked users")),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: blockedUsers.length,
              itemBuilder: (context, index) {
                final blockedUserId = blockedUsers[index];

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection("users")
                      .doc(blockedUserId)
                      .get(),
                  builder: (context, userSnapshot) {
                    final blockedUserData =
                        userSnapshot.data?.data() as Map<String, dynamic>?;

                    return Card(
                      color: Colors.black,
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.purple,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(blockedUserData?["name"] ?? "Blocked User"),
                        subtitle: Text(
                          "@${blockedUserData?["username"] ?? "user"}",
                        ),
                        trailing: TextButton(
                          onPressed: () {
                            unblockUser(currentUser.uid, blockedUserId);
                          },
                          child: const Text("Unblock"),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.black,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Account"),
            subtitle: const Text("Manage your profile information"),
            onTap: () {},
          ),

          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text("Privacy"),
            subtitle: const Text("Blocked users and privacy settings"),
            onTap: () {
              openBlockedUsers(context);
            },
          ),

          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text("Notifications"),
            subtitle: const Text("Manage notification preferences"),
            onTap: () {},
          ),

          ListTile(
            leading: const Icon(Icons.info),
            title: const Text("About"),
            subtitle: const Text("Demo App Project"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutScreen()),
              );
            },
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout", style: TextStyle(color: Colors.red)),
            onTap: () {
              logoutUser(context);
            },
          ),
        ],
      ),
    );
  }
}
