import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'chat_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  String getChatId(String user1, String user2) {
    if (user1.hashCode <= user2.hashCode) {
      return "${user1}_$user2";
    } else {
      return "${user2}_$user1";
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Messages"),
        backgroundColor: Colors.black,
      ),
      body: currentUser == null
          ? const Center(child: Text("Please login first"))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("users")
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No users found"));
                }

                final users = snapshot.data!.docs.where((doc) {
                  return doc.id != currentUser.uid;
                }).toList();

                if (users.isEmpty) {
                  return const Center(child: Text("No users to message"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final userDoc = users[index];
                    final userData = userDoc.data() as Map<String, dynamic>;

                    final receiverId = userDoc.id;
                    final receiverName = userData["name"] ?? "User";
                    final receiverUsername = userData["username"] ?? "user";

                    final chatId = getChatId(currentUser.uid, receiverId);

                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection("chats")
                          .doc(chatId)
                          .collection("messages")
                          .orderBy("createdAt", descending: true)
                          .limit(1)
                          .snapshots(),
                      builder: (context, messageSnapshot) {
                        String lastMessage = "Tap to start chatting";

                        if (messageSnapshot.hasData &&
                            messageSnapshot.data!.docs.isNotEmpty) {
                          final messageData =
                              messageSnapshot.data!.docs.first.data()
                                  as Map<String, dynamic>;

                          lastMessage = messageData["message"] ?? "Message";
                        }

                        return Card(
                          color: Colors.grey[900],
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.purple,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            title: Text(receiverName),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "@$receiverUsername",
                                  style: const TextStyle(
                                    color: Colors.purple,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  lastMessage,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    receiverId: receiverId,
                                    receiverName: receiverName,
                                  ),
                                ),
                              );
                            },
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
