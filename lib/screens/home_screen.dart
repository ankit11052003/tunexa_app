import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'comments_screen.dart';
import 'notifications_screen.dart';
import 'stories_screen.dart';
import 'messages_screen.dart';
import 'user_profile_screen.dart';
import 'upload_story_screen.dart';

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

      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .get();

      final userName = userDoc.data()?["name"] ?? "Someone";

      if (userId != postOwnerId) {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(postOwnerId)
            .collection("notifications")
            .add({
              "type": "like",
              "message": "$userName liked your post",
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

  Future<void> reportPost(
    BuildContext context,
    String postId,
    String postOwnerId,
    String reporterId,
  ) async {
    await FirebaseFirestore.instance.collection("reports").add({
      "postId": postId,
      "postOwnerId": postOwnerId,
      "reporterId": reporterId,
      "reason": "Inappropriate content",
      "status": "pending",
      "createdAt": DateTime.now(),
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Post reported")));
  }

  void showShareSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) {
        return Wrap(
          children: const [
            ListTile(
              leading: Icon(Icons.copy, color: Colors.white),
              title: Text("Copy post link"),
            ),
            ListTile(
              leading: Icon(Icons.message, color: Colors.white),
              title: Text("Send in message"),
            ),
            ListTile(
              leading: Icon(Icons.share, color: Colors.white),
              title: Text("Share outside app"),
            ),
          ],
        );
      },
    );
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

                final blockedUsers = userData?["blockedUsers"] ?? [];

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),

                      child: SizedBox(
                        width: double.infinity,

                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const UploadStoryScreen(),
                              ),
                            );
                          },

                          icon: const Icon(Icons.add_circle),

                          label: const Text("Add Story"),
                        ),
                      ),
                    ),

                    SizedBox(
                      height: 105,

                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection("stories")
                            .where("expiresAt", isGreaterThan: DateTime.now())
                            .orderBy("expiresAt", descending: false)
                            .snapshots(),

                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final stories = snapshot.data!.docs;

                          if (stories.isEmpty) {
                            return const Center(child: Text("No stories yet"));
                          }

                          return ListView.builder(
                            scrollDirection: Axis.horizontal,

                            itemCount: stories.length,

                            itemBuilder: (context, index) {
                              final storyDoc = stories[index];

                              final storyData =
                                  storyDoc.data() as Map<String, dynamic>;

                              final name = storyData["userName"] ?? "User";

                              final photoUrl = (storyData["photoUrl"] ?? "")
                                  .toString();

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => StoriesScreen(
                                        storyId: storyDoc.id,

                                        userName: name,

                                        storyUrl: storyData["storyUrl"] ?? "",

                                        photoUrl: photoUrl,
                                      ),
                                    ),
                                  );
                                },

                                child: Padding(
                                  padding: const EdgeInsets.all(8),

                                  child: Column(
                                    children: [
                                      CircleAvatar(
                                        radius: 30,

                                        backgroundColor: Colors.purple,

                                        backgroundImage: photoUrl.isNotEmpty
                                            ? NetworkImage(photoUrl)
                                            : null,

                                        child: photoUrl.isEmpty
                                            ? const Icon(
                                                Icons.person,
                                                color: Colors.white,
                                              )
                                            : null,
                                      ),

                                      const SizedBox(height: 5),

                                      SizedBox(
                                        width: 65,

                                        child: Text(
                                          name,

                                          overflow: TextOverflow.ellipsis,

                                          textAlign: TextAlign.center,
                                        ),
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

                    const Divider(),

                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection("posts")
                            .orderBy("createdAt", descending: true)
                            .snapshots(),

                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final posts = snapshot.data!.docs.where((post) {
                            final data = post.data() as Map<String, dynamic>;

                            return !blockedUsers.contains(data["uid"]);
                          }).toList();

                          if (posts.isEmpty) {
                            return const Center(child: Text("No posts yet"));
                          }

                          return ListView.builder(
                            itemCount: posts.length,

                            itemBuilder: (context, index) {
                              final post = posts[index];

                              final data = post.data() as Map<String, dynamic>;

                              final likes = data["likes"] ?? [];

                              final imageUrl = (data["imageUrl"] ?? "")
                                  .toString();

                              final photoUrl = (data["photoUrl"] ?? "")
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

                                          child: CircleAvatar(
                                            backgroundColor: Colors.purple,

                                            backgroundImage: photoUrl.isNotEmpty
                                                ? NetworkImage(photoUrl)
                                                : null,

                                            child: photoUrl.isEmpty
                                                ? const Icon(
                                                    Icons.person,
                                                    color: Colors.white,
                                                  )
                                                : null,
                                          ),
                                        ),

                                        title: Text(
                                          data["userName"] ?? "User",

                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),

                                        subtitle: Text(
                                          "@${data["username"] ?? "user"} • ${formatTime(data["createdAt"])}",
                                        ),
                                      ),

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
                                          ),
                                        ),

                                      const SizedBox(height: 10),

                                      Text(data["caption"] ?? ""),

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

                                            icon: const Icon(Icons.comment),
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
