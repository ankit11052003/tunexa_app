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
          "username": userData?["username"] ?? "user",
          "photoUrl": userData?["photoUrl"] ?? "",
          "uid": user.uid,
          "createdAt": DateTime.now(),
          "edited": false,
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

  Future<void> deleteComment(String commentId) async {
    await FirebaseFirestore.instance
        .collection("posts")
        .doc(widget.postId)
        .collection("comments")
        .doc(commentId)
        .delete();
  }

  Future<void> editComment(String commentId, String oldComment) async {
    final editController = TextEditingController(text: oldComment);

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Edit Comment"),
          content: TextField(
            controller: editController,
            maxLines: 3,
            decoration: const InputDecoration(hintText: "Edit your comment"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                if (editController.text.trim().isEmpty) return;

                await FirebaseFirestore.instance
                    .collection("posts")
                    .doc(widget.postId)
                    .collection("comments")
                    .doc(commentId)
                    .update({
                      "comment": editController.text.trim(),
                      "edited": true,
                    });

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );

    editController.dispose();
  }

  void showCommentOptions(String commentId, String oldComment) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (sheetContext) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.white),
              title: const Text("Edit Comment"),
              onTap: () {
                Navigator.pop(sheetContext);
                editComment(commentId, oldComment);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                "Delete Comment",
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                Navigator.pop(sheetContext);
                await deleteComment(commentId);
              },
            ),
          ],
        );
      },
    );
  }

  String formatTime(dynamic createdAt) {
    if (createdAt == null) return "";

    final date = createdAt.toDate();

    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  void dispose() {
    commentController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

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
                    final commentDoc = comments[index];

                    final data = commentDoc.data() as Map<String, dynamic>;

                    final isMyComment =
                        currentUser != null && data["uid"] == currentUser.uid;

                    final edited = data["edited"] == true;

                    final photoUrl = (data["photoUrl"] ?? "").toString();

                    return Card(
                      color: Colors.grey[900],
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.purple,
                          backgroundImage: photoUrl.isNotEmpty
                              ? NetworkImage(photoUrl)
                              : null,
                          child: photoUrl.isEmpty
                              ? const Icon(Icons.person, color: Colors.white)
                              : null,
                        ),
                        title: Text(data["userName"] ?? "User"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "@${data["username"] ?? "user"}",
                              style: const TextStyle(
                                color: Colors.purple,
                                fontSize: 12,
                              ),
                            ),
                            Text(data["comment"] ?? ""),
                            if (edited)
                              const Text(
                                "edited",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                              ),
                            Text(
                              formatTime(data["createdAt"]),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        trailing: isMyComment
                            ? IconButton(
                                onPressed: () {
                                  showCommentOptions(
                                    commentDoc.id,
                                    data["comment"] ?? "",
                                  );
                                },
                                icon: const Icon(Icons.more_vert),
                              )
                            : null,
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
