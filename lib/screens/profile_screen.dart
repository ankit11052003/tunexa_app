import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'login_screen.dart';
import 'saved_posts_screen.dart';
import 'post_detail_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> logoutUser(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  Future<void> editProfile(
    BuildContext context,
    String uid,
    String currentName,
    String currentUsername,
    String currentBio,
  ) async {
    final nameController = TextEditingController(text: currentName);
    final usernameController = TextEditingController(text: currentUsername);
    final bioController = TextEditingController(text: currentBio);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Profile"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(hintText: "Name"),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  hintText: "Username",
                  prefixText: "@",
                ),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: bioController,
                decoration: const InputDecoration(hintText: "Bio"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final newUsername = usernameController.text
                    .trim()
                    .toLowerCase();

                if (newUsername.isEmpty) {
                  return;
                }

                final usernameCheck = await FirebaseFirestore.instance
                    .collection("users")
                    .where("username", isEqualTo: newUsername)
                    .get();

                final usernameTaken = usernameCheck.docs.any(
                  (doc) => doc.id != uid,
                );

                if (usernameTaken) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Username already taken")),
                  );
                  return;
                }

                await FirebaseFirestore.instance
                    .collection("users")
                    .doc(uid)
                    .update({
                      "name": nameController.text.trim(),
                      "username": newUsername,
                      "bio": bioController.text.trim(),
                    });

                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Profile"),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            onPressed: () {
              logoutUser(context);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text("No user logged in"))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("users")
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final userData = snapshot.data!.data() as Map<String, dynamic>;

                final followers = userData["followers"] ?? [];
                final following = userData["following"] ?? [];

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.purple,
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 15),

                      Text(
                        userData["name"] ?? "Tunexa User",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        "@${userData["username"] ?? "user"}",
                        style: const TextStyle(
                          color: Colors.purple,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        userData["bio"] ?? "No bio yet",
                        style: const TextStyle(color: Colors.grey),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        userData["email"] ?? user.email ?? "No email",
                        style: const TextStyle(color: Colors.grey),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection("posts")
                                .where("uid", isEqualTo: user.uid)
                                .snapshots(),
                            builder: (context, postSnapshot) {
                              final postCount =
                                  postSnapshot.data?.docs.length ?? 0;

                              return Column(
                                children: [
                                  Text(
                                    "$postCount",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                  const Text("Posts"),
                                ],
                              );
                            },
                          ),

                          Column(
                            children: [
                              Text(
                                "${followers.length}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              const Text("Followers"),
                            ],
                          ),

                          Column(
                            children: [
                              Text(
                                "${following.length}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              const Text("Following"),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      ElevatedButton(
                        onPressed: () {
                          editProfile(
                            context,
                            user.uid,
                            userData["name"] ?? "",
                            userData["username"] ?? "",
                            userData["bio"] ?? "",
                          );
                        },
                        child: const Text("Edit Profile"),
                      ),

                      const SizedBox(height: 10),

                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SavedPostsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.bookmark),
                        label: const Text("Saved Posts"),
                      ),

                      const SizedBox(height: 20),

                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection("posts")
                            .where("uid", isEqualTo: user.uid)
                            .orderBy("createdAt", descending: true)
                            .snapshots(),
                        builder: (context, postSnapshot) {
                          if (!postSnapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final posts = postSnapshot.data!.docs;

                          if (posts.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(20),
                              child: Text("No posts yet"),
                            );
                          }

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(8),
                            itemCount: posts.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 4,
                                  mainAxisSpacing: 4,
                                ),
                            itemBuilder: (context, index) {
                              final data =
                                  posts[index].data() as Map<String, dynamic>;

                              final imageUrl = (data["imageUrl"] ?? "")
                                  .toString();

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PostDetailScreen(
                                        userName: userData["name"] ?? "User",
                                        username:
                                            userData["username"] ?? "user",
                                        caption: data["caption"] ?? "",
                                        date: "Post",
                                        imageUrl: imageUrl,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.purple[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: imageUrl.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.network(
                                            imageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return const Center(
                                                    child: Icon(
                                                      Icons.broken_image,
                                                    ),
                                                  );
                                                },
                                          ),
                                        )
                                      : Center(
                                          child: Padding(
                                            padding: const EdgeInsets.all(6),
                                            child: Text(
                                              data["caption"] ?? "",
                                              maxLines: 4,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
