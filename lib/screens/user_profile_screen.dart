import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'post_detail_screen.dart';

class UserProfileScreen extends StatelessWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  Future<void> followUser(String currentUserId) async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(currentUserId)
        .update({
          "following": FieldValue.arrayUnion([userId]),
        });

    await FirebaseFirestore.instance.collection("users").doc(userId).update({
      "followers": FieldValue.arrayUnion([currentUserId]),
    });

    final currentUserDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(currentUserId)
        .get();

    final currentUserName = currentUserDoc.data()?["name"] ?? "Someone";

    await FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("notifications")
        .add({
          "type": "follow",
          "message": "$currentUserName started following you",
          "fromUserId": currentUserId,
          "isRead": false,
          "createdAt": DateTime.now(),
        });
  }

  Future<void> unfollowUser(String currentUserId) async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(currentUserId)
        .update({
          "following": FieldValue.arrayRemove([userId]),
        });

    await FirebaseFirestore.instance.collection("users").doc(userId).update({
      "followers": FieldValue.arrayRemove([currentUserId]),
    });
  }

  Future<void> blockUser(String currentUserId) async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(currentUserId)
        .update({
          "blockedUsers": FieldValue.arrayUnion([userId]),
        });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.black,
      ),

      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(userId)
            .snapshots(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>?;

          if (userData == null) {
            return const Center(child: Text("User not found"));
          }

          final followers = userData["followers"] ?? [];

          final following = userData["following"] ?? [];

          final photoUrl = (userData["photoUrl"] ?? "").toString();

          final isFollowing =
              currentUser != null && followers.contains(currentUser.uid);

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),

                CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.purple,

                  backgroundImage: photoUrl.isNotEmpty
                      ? NetworkImage(photoUrl)
                      : null,

                  child: photoUrl.isEmpty
                      ? const Icon(Icons.person, size: 55, color: Colors.white)
                      : null,
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

                if (currentUser != null && currentUser.uid != userId)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,

                    children: [
                      ElevatedButton(
                        onPressed: () {
                          if (isFollowing) {
                            unfollowUser(currentUser.uid);
                          } else {
                            followUser(currentUser.uid);
                          }
                        },

                        child: Text(isFollowing ? "Unfollow" : "Follow"),
                      ),

                      const SizedBox(width: 10),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),

                        onPressed: () async {
                          await blockUser(currentUser.uid);

                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        },

                        child: const Text("Block"),
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

                        final imageUrl = (data["imageUrl"] ?? "").toString();

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PostDetailScreen(
                                  userName: userData["name"] ?? "User",

                                  username: userData["username"] ?? "user",

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
                                    borderRadius: BorderRadius.circular(8),

                                    child: Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
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

                                        style: const TextStyle(fontSize: 12),
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
