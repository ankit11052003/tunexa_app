import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;

  const CommentsScreen({super.key, required this.postId});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final commentController = TextEditingController();

  Future<void> addComment() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    if (commentController.text.trim().isEmpty) return;

    final userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    final userData = userDoc.data();

    final currentUserName = userData?["name"] ?? "Someone";

    final postDoc = await FirebaseFirestore.instance
        .collection("posts")
        .doc(widget.postId)
        .get();

    final postData = postDoc.data();

    final postOwnerId = postData?["uid"];

    await FirebaseFirestore.instance
        .collection("posts")
        .doc(widget.postId)
        .collection("comments")
        .add({
          "comment": commentController.text.trim(),
          "userName": currentUserName,
          "uid": user.uid,
          "createdAt": DateTime.now(),
        });

    if (postOwnerId != null && postOwnerId != user.uid) {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(postOwnerId)
          .collection("notifications")
          .add({
            "type": "comment",
            "message": "$currentUserName commented on your post",
            "fromUserId": user.uid,
            "postId": widget.postId,
            "isRead": false,
            "createdAt": DateTime.now(),
          });
    }

    commentController.clear();
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  String formatTime(dynamic createdAt) {
    if (createdAt == null) return "";

    final date = createdAt.toDate();
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Comments"),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("posts")
                  .doc(widget.postId)
                  .collection("comments")
                  .orderBy("createdAt", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No comments yet"));
                }

                final comments = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final data = comments[index].data() as Map<String, dynamic>;

                    return Card(
                      color: Colors.grey[900],
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.purple,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(data["userName"] ?? "User"),
                        subtitle: Text(data["comment"] ?? ""),
                        trailing: Text(
                          formatTime(data["createdAt"]),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.black,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: commentController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Write a comment...",
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                CircleAvatar(
                  backgroundColor: Colors.purple,
                  child: IconButton(
                    onPressed: addComment,
                    icon: const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
