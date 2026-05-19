import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';

class UserProfileScreen extends StatelessWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  String formatTime(dynamic createdAt) {
    if (createdAt == null) return "Post";

    final date = createdAt.toDate();
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Profile"),
        backgroundColor: Colors.black,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(userId)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!userSnapshot.data!.exists) {
            return const Center(child: Text("User not found"));
          }

          final userData = userSnapshot.data!.data() as Map<String, dynamic>;

          final followers = userData["followers"] ?? [];
          final following = userData["following"] ?? [];

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),

                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.purple,
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),

                const SizedBox(height: 15),

                Text(
                  userData["name"] ?? "User",
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
                  userData["email"] ?? "",
                  style: const TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 20),

                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          receiverId: userId,
                          receiverName: userData["name"] ?? "User",
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.message),
                  label: const Text("Message"),
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection("posts")
                          .where("uid", isEqualTo: userId)
                          .snapshots(),
                      builder: (context, postSnapshot) {
                        final postCount = postSnapshot.data?.docs.length ?? 0;

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

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("posts")
                      .where("uid", isEqualTo: userId)
                      .orderBy("createdAt", descending: true)
                      .snapshots(),
                  builder: (context, postSnapshot) {
                    if (!postSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final posts = postSnapshot.data!.docs;

                    if (posts.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text("No posts yet"),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final data =
                            posts[index].data() as Map<String, dynamic>;

                        final imageUrl = (data["imageUrl"] ?? "").toString();

                        return Card(
                          margin: const EdgeInsets.all(10),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (imageUrl.isNotEmpty)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      imageUrl,
                                      height: 220,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),

                                if (imageUrl.isNotEmpty)
                                  const SizedBox(height: 10),

                                Text(
                                  data["caption"] ?? "",
                                  style: const TextStyle(fontSize: 16),
                                ),

                                const SizedBox(height: 8),

                                Text(
                                  formatTime(data["createdAt"]),
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
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
