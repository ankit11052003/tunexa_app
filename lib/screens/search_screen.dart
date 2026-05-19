import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final searchController = TextEditingController();

  String searchText = "";

  Future<void> followUser(String targetUserId) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null || currentUser.uid == targetUserId) {
      return;
    }

    final currentUserDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(currentUser.uid)
        .get();

    final currentUserName = currentUserDoc.data()?["name"] ?? "Someone";

    await FirebaseFirestore.instance
        .collection("users")
        .doc(currentUser.uid)
        .update({
          "following": FieldValue.arrayUnion([targetUserId]),
        });

    await FirebaseFirestore.instance
        .collection("users")
        .doc(targetUserId)
        .update({
          "followers": FieldValue.arrayUnion([currentUser.uid]),
        });

    await FirebaseFirestore.instance
        .collection("users")
        .doc(targetUserId)
        .collection("notifications")
        .add({
          "type": "follow",
          "message": "$currentUserName started following you",
          "fromUserId": currentUser.uid,
          "isRead": false,
          "createdAt": DateTime.now(),
        });
  }

  Future<void> unfollowUser(String targetUserId) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null || currentUser.uid == targetUserId) {
      return;
    }

    await FirebaseFirestore.instance
        .collection("users")
        .doc(currentUser.uid)
        .update({
          "following": FieldValue.arrayRemove([targetUserId]),
        });

    await FirebaseFirestore.instance
        .collection("users")
        .doc(targetUserId)
        .update({
          "followers": FieldValue.arrayRemove([currentUser.uid]),
        });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Search Users"),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() {
                  searchText = value.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: "Search username, name or email...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchText.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          searchController.clear();

                          setState(() {
                            searchText = "";
                          });
                        },
                        icon: const Icon(Icons.close),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("users")
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No users in database"));
                }

                final allUsers = snapshot.data!.docs;

                final users = allUsers.where((doc) {
                  if (currentUser != null && doc.id == currentUser.uid) {
                    return false;
                  }

                  final data = doc.data() as Map<String, dynamic>;

                  final name = (data["name"] ?? "").toString().toLowerCase();

                  final username = (data["username"] ?? "")
                      .toString()
                      .toLowerCase();

                  final email = (data["email"] ?? "").toString().toLowerCase();

                  if (searchText.isEmpty) {
                    return true;
                  }

                  return name.contains(searchText) ||
                      username.contains(searchText) ||
                      email.contains(searchText);
                }).toList();

                if (users.isEmpty) {
                  return Center(
                    child: Text(
                      allUsers.length <= 1
                          ? "Create another account to search users"
                          : "No matching users found",
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final doc = users[index];

                    final data = doc.data() as Map<String, dynamic>;

                    final targetUserId = doc.id;

                    final followers = data["followers"] ?? [];

                    final isFollowing = currentUser != null
                        ? followers.contains(currentUser.uid)
                        : false;

                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.purple,
                        child: Icon(Icons.person, color: Colors.white),
                      ),

                      title: Text(data["name"] ?? "User"),

                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "@${data["username"] ?? "user"}",
                            style: const TextStyle(
                              color: Colors.purple,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          Text(data["email"] ?? ""),
                        ],
                      ),

                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                UserProfileScreen(userId: targetUserId),
                          ),
                        );
                      },

                      trailing: ElevatedButton(
                        onPressed: () {
                          if (isFollowing) {
                            unfollowUser(targetUserId);
                          } else {
                            followUser(targetUserId);
                          }
                        },
                        child: Text(isFollowing ? "Unfollow" : "Follow"),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
