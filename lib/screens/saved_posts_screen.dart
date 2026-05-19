import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SavedPostsScreen extends StatelessWidget {
  const SavedPostsScreen({super.key});

  String formatTime(dynamic createdAt) {
    if (createdAt == null) return "";

    final date = createdAt.toDate();
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Saved Posts"),
        backgroundColor: Colors.black,
      ),
      body: currentUser == null
          ? const Center(child: Text("Please login first"))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("users")
                  .doc(currentUser.uid)
                  .snapshots(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final userData =
                    userSnapshot.data!.data() as Map<String, dynamic>?;

                final savedPosts = userData?["savedPosts"] ?? [];

                if (savedPosts.isEmpty) {
                  return const Center(child: Text("No saved posts yet"));
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("posts")
                      .orderBy("createdAt", descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final filteredPosts = snapshot.data!.docs.where((post) {
                      return savedPosts.contains(post.id);
                    }).toList();

                    if (filteredPosts.isEmpty) {
                      return const Center(
                        child: Text("Saved post no longer exists"),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(10),
                      itemCount: filteredPosts.length,
                      itemBuilder: (context, index) {
                        final data =
                            filteredPosts[index].data() as Map<String, dynamic>;

                        final imageUrl = (data["imageUrl"] ?? "").toString();

                        return Card(
                          color: Colors.grey[900],
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const CircleAvatar(
                                    backgroundColor: Colors.purple,
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.white,
                                    ),
                                  ),
                                  title: Text(data["userName"] ?? "User"),
                                  subtitle: Text(
                                    "@${data["username"] ?? "user"} • ${formatTime(data["createdAt"])}",
                                  ),
                                ),

                                if (imageUrl.isNotEmpty)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.network(
                                      imageUrl,
                                      height: 220,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              height: 140,
                                              alignment: Alignment.center,
                                              color: Colors.black,
                                              child: const Text(
                                                "Image failed to load",
                                              ),
                                            );
                                          },
                                    ),
                                  ),

                                if (imageUrl.isNotEmpty)
                                  const SizedBox(height: 10),

                                Text(
                                  data["caption"] ?? "",
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
