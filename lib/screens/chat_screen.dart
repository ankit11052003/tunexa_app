import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageController = TextEditingController();

  String getChatId(String user1, String user2) {
    if (user1.hashCode <= user2.hashCode) {
      return "${user1}_$user2";
    } else {
      return "${user2}_$user1";
    }
  }

  Future<void> sendMessage() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return;

    if (messageController.text.trim().isEmpty) return;

    final chatId = getChatId(currentUser.uid, widget.receiverId);

    await FirebaseFirestore.instance
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .add({
          "senderId": currentUser.uid,
          "receiverId": widget.receiverId,
          "message": messageController.text.trim(),
          "createdAt": DateTime.now(),
        });

    messageController.clear();
  }

  String formatTime(dynamic createdAt) {
    if (createdAt == null) return "";

    final date = createdAt.toDate();

    String minute = date.minute.toString();

    if (minute.length == 1) {
      minute = "0$minute";
    }

    return "${date.hour}:$minute";
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    final chatId = currentUser == null
        ? ""
        : getChatId(currentUser.uid, widget.receiverId);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.purple,
              child: Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text(widget.receiverName),
          ],
        ),
      ),
      body: currentUser == null
          ? const Center(child: Text("Please login first"))
          : Column(
              children: [
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("chats")
                        .doc(chatId)
                        .collection("messages")
                        .orderBy("createdAt", descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final messages = snapshot.data!.docs;

                      if (messages.isEmpty) {
                        return const Center(child: Text("No messages yet"));
                      }

                      return ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.all(10),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final data =
                              messages[index].data() as Map<String, dynamic>;

                          final isMe = data["senderId"] == currentUser.uid;

                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 5,
                              ),
                              padding: const EdgeInsets.all(12),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.72,
                              ),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.purple : Colors.grey[850],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data["message"] ?? "",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                    ),
                                  ),

                                  const SizedBox(height: 5),

                                  Text(
                                    formatTime(data["createdAt"]),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[300],
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

                Container(
                  padding: const EdgeInsets.all(10),
                  color: Colors.black,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: messageController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "Type a message...",
                            hintStyle: const TextStyle(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey[900],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      CircleAvatar(
                        backgroundColor: Colors.purple,
                        child: IconButton(
                          onPressed: sendMessage,
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
