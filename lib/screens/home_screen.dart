import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'comments_screen.dart';
import 'notifications_screen.dart';
import 'stories_screen.dart';
import 'messages_screen.dart';
import 'user_profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String formatTime(dynamic createdAt) {
    if (createdAt == null) return "";

    final date = createdAt.toDate();
    return "${date.day}/${date.month}/${date.year}";
  }

  Future<void> toggleLike(
    String postId,
    List likes,
    String userId,
    String postOwnerId,
  ) async {
    final postRef = FirebaseFirestore.instance.collection("posts").doc(postId);

    if (likes.contains(userId)) {
      await postRef.update({
        "likes": FieldValue.arrayRemove([userId]),
      });
    } else {
      await postRef.update({
        "likes": FieldValue.arrayUnion([userId]),
      });

      final currentUserDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .get();

      final currentUserData = currentUserDoc.data();
      final currentUserName = currentUserData?["name"] ?? "Someone";

      if (userId != postOwnerId) {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(postOwnerId)
            .collection("notifications")
            .add({
              "type": "like",
              "message": "$currentUserName liked your post",
              "fromUserId": userId,
              "isRead": false,
              "createdAt": DateTime.now(),
            });
      }
    }
  }

  Future<void> toggleSave(String postId, List savedPosts, String userId) async {
    final userRef = FirebaseFirestore.instance.collection("users").doc(userId);

    if (savedPosts.contains(postId)) {
      await userRef.update({
        "savedPosts": FieldValue.arrayRemove([postId]),
      });
    } else {
      await userRef.update({
        "savedPosts": FieldValue.arrayUnion([postId]),
      });
    }
  }

  Future<void> deletePost(String postId) async {
    await FirebaseFirestore.instance.collection("posts").doc(postId).delete();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tunexa"),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MessagesScreen()),
              );
            },
            icon: const Icon(Icons.message),
          ),

          if (currentUser != null)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("users")
                  .doc(currentUser.uid)
                  .collection("notifications")
                  .where("isRead", isEqualTo: false)
                  .snapshots(),
              builder: (context, snapshot) {
                final unreadCount = snapshot.data?.docs.length ?? 0;

                return Stack(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.notifications),
                    ),

                    if (unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: CircleAvatar(
                          radius: 9,
                          backgroundColor: Colors.red,
                          child: Text(
                            "$unreadCount",
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
      body: currentUser == null
          ? const Center(child: Text("Please login first"))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("users")
                  .doc(currentUser.uid)
                  .snapshots(),
              builder: (context, userSnapshot) {
                final userData =
                    userSnapshot.data?.data() as Map<String, dynamic>?;

                final savedPosts = userData?["savedPosts"] ?? [];

                return Column(
                  children: [
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 8,
                        itemBuilder: (context, index) {
                          final storyUserName = "User ${index + 1}";

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      StoriesScreen(userName: storyUserName),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                children: [
                                  const CircleAvatar(
                                    radius: 30,
                                    backgroundColor: Colors.purple,
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(storyUserName),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const Divider(),

                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection("posts")
                            .orderBy("createdAt", descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return const Center(child: Text("No posts yet"));
                          }

                          final posts = snapshot.data!.docs;

                          return ListView.builder(
                            itemCount: posts.length,
                            itemBuilder: (context, index) {
                              final post = posts[index];
                              final data = post.data() as Map<String, dynamic>;

                              final likes = data["likes"] ?? [];
                              final imageUrl = (data["imageUrl"] ?? "")
                                  .toString();

                              final isLiked = likes.contains(currentUser.uid);

                              final isSaved = savedPosts.contains(post.id);

                              final isMyPost = data["uid"] == currentUser.uid;

                              return Card(
                                margin: const EdgeInsets.all(10),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ListTile(
                                        contentPadding: EdgeInsets.zero,

                                        leading: GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    UserProfileScreen(
                                                      userId: data["uid"],
                                                    ),
                                              ),
                                            );
                                          },
                                          child: const CircleAvatar(
                                            backgroundColor: Colors.purple,
                                            child: Icon(
                                              Icons.person,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),

                                        title: GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    UserProfileScreen(
                                                      userId: data["uid"],
                                                    ),
                                              ),
                                            );
                                          },
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                data["userName"] ?? "User",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                "@${data["username"] ?? "user"}",
                                                style: const TextStyle(
                                                  color: Colors.purple,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        subtitle: Text(
                                          formatTime(data["createdAt"]),
                                        ),

                                        trailing: isMyPost
                                            ? IconButton(
                                                onPressed: () {
                                                  deletePost(post.id);
                                                },
                                                icon: const Icon(
                                                  Icons.delete,
                                                  color: Colors.red,
                                                ),
                                              )
                                            : null,
                                      ),

                                      const SizedBox(height: 10),

                                      if (imageUrl.isNotEmpty)
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: Image.network(
                                            imageUrl,
                                            height: 250,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Container(
                                                    height: 150,
                                                    alignment: Alignment.center,
                                                    color: Colors.grey[900],
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

                                      const SizedBox(height: 10),

                                      Row(
                                        children: [
                                          IconButton(
                                            onPressed: () {
                                              toggleLike(
                                                post.id,
                                                likes,
                                                currentUser.uid,
                                                data["uid"],
                                              );
                                            },
                                            icon: Icon(
                                              isLiked
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color: isLiked
                                                  ? Colors.red
                                                  : null,
                                            ),
                                          ),

                                          Text("${likes.length}"),

                                          StreamBuilder<QuerySnapshot>(
                                            stream: FirebaseFirestore.instance
                                                .collection("posts")
                                                .doc(post.id)
                                                .collection("comments")
                                                .snapshots(),
                                            builder: (context, commentSnapshot) {
                                              final commentCount =
                                                  commentSnapshot
                                                      .data
                                                      ?.docs
                                                      .length ??
                                                  0;

                                              return Row(
                                                children: [
                                                  IconButton(
                                                    onPressed: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              CommentsScreen(
                                                                postId: post.id,
                                                              ),
                                                        ),
                                                      );
                                                    },
                                                    icon: const Icon(
                                                      Icons.comment_outlined,
                                                    ),
                                                  ),
                                                  Text("$commentCount"),
                                                ],
                                              );
                                            },
                                          ),

                                          IconButton(
                                            onPressed: () {},
                                            icon: const Icon(Icons.send),
                                          ),

                                          const Spacer(),

                                          IconButton(
                                            onPressed: () {
                                              toggleSave(
                                                post.id,
                                                savedPosts,
                                                currentUser.uid,
                                              );
                                            },
                                            icon: Icon(
                                              isSaved
                                                  ? Icons.bookmark
                                                  : Icons.bookmark_border,
                                              color: isSaved
                                                  ? Colors.purple
                                                  : null,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
