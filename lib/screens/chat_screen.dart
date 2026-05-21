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
  bool isTyping = false;

  String getChatId(String user1, String user2) {
    if (user1.hashCode <= user2.hashCode) {
      return "${user1}_$user2";
    } else {
      return "${user2}_$user1";
    }
  }

  void handleTyping(String value) {
    setState(() {
      isTyping = value.trim().isNotEmpty;
    });
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

  String formatLastSeen(dynamic lastSeen) {
    if (lastSeen == null) return "Offline";

    final date = lastSeen.toDate();
    String minute = date.minute.toString();

    if (minute.length == 1) {
      minute = "0$minute";
    }

    return "Last seen ${date.hour}:$minute";
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
          "edited": false,
          "isSeen": false,
        });

    messageController.clear();

    setState(() {
      isTyping = false;
    });
  }

  Future<void> deleteMessage(String messageId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final chatId = getChatId(currentUser.uid, widget.receiverId);

    await FirebaseFirestore.instance
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .doc(messageId)
        .delete();
  }

  Future<void> editMessage(String messageId, String oldMessage) async {
    final editController = TextEditingController(text: oldMessage);

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Edit Message"),
          content: TextField(
            controller: editController,
            maxLines: 3,
            decoration: const InputDecoration(hintText: "Edit message"),
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

                final currentUser = FirebaseAuth.instance.currentUser;
                if (currentUser == null) return;

                final chatId = getChatId(currentUser.uid, widget.receiverId);

                await FirebaseFirestore.instance
                    .collection("chats")
                    .doc(chatId)
                    .collection("messages")
                    .doc(messageId)
                    .update({
                      "message": editController.text.trim(),
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

  void showMessageOptions(String messageId, String oldMessage) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (sheetContext) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.white),
              title: const Text("Edit Message"),
              onTap: () {
                Navigator.pop(sheetContext);
                editMessage(messageId, oldMessage);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                "Delete Message",
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                deleteMessage(messageId);
              },
            ),
          ],
        );
      },
    );
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
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("users")
                  .doc(widget.receiverId)
                  .snapshots(),
              builder: (context, snapshot) {
                final userData = snapshot.data?.data() as Map<String, dynamic>?;

                final photoUrl = (userData?["photoUrl"] ?? "").toString();

                return CircleAvatar(
                  backgroundColor: Colors.purple,
                  backgroundImage: photoUrl.isNotEmpty
                      ? NetworkImage(photoUrl)
                      : null,
                  child: photoUrl.isEmpty
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                );
              },
            ),
            const SizedBox(width: 10),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("users")
                  .doc(widget.receiverId)
                  .snapshots(),
              builder: (context, snapshot) {
                final userData = snapshot.data?.data() as Map<String, dynamic>?;

                final isOnline = userData?["isOnline"] == true;
                final lastSeen = userData?["lastSeen"];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.receiverName),
                    if (isTyping)
                      const Text(
                        "Typing...",
                        style: TextStyle(fontSize: 12, color: Colors.green),
                      )
                    else
                      Text(
                        isOnline ? "Online" : formatLastSeen(lastSeen),
                        style: TextStyle(
                          fontSize: 12,
                          color: isOnline ? Colors.green : Colors.grey,
                        ),
                      ),
                  ],
                );
              },
            ),
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
                          final messageDoc = messages[index];
                          final data =
                              messageDoc.data() as Map<String, dynamic>;

                          final isMe = data["senderId"] == currentUser.uid;

                          final edited = data["edited"] == true;
                          final isSeen = data["isSeen"] == true;

                          if (!isMe && !isSeen) {
                            messageDoc.reference.update({"isSeen": true});
                          }

                          return GestureDetector(
                            onLongPress: isMe
                                ? () {
                                    showMessageOptions(
                                      messageDoc.id,
                                      data["message"] ?? "",
                                    );
                                  }
                                : null,
                            child: Align(
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
                                  color: isMe
                                      ? Colors.purple
                                      : Colors.grey[850],
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
                                      edited
                                          ? "${formatTime(data["createdAt"])} • edited"
                                          : formatTime(data["createdAt"]),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[300],
                                      ),
                                    ),
                                    if (isMe)
                                      Text(
                                        isSeen ? "Seen" : "Delivered",
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isSeen
                                              ? Colors.green
                                              : Colors.grey[400],
                                        ),
                                      ),
                                  ],
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
                          controller: messageController,
                          onChanged: handleTyping,
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
