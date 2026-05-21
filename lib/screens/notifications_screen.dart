import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool markedRead = false;

  String formatTime(dynamic createdAt) {
    if (createdAt == null) return "";

    final date = createdAt.toDate();

    return "${date.day}/${date.month}/${date.year}";
  }

  Future<void> markAllAsRead(String uid) async {
    if (markedRead) return;

    markedRead = true;

    final unreadNotifications = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("notifications")
        .where("isRead", isEqualTo: false)
        .get();

    for (final doc in unreadNotifications.docs) {
      await doc.reference.update({"isRead": true});
    }
  }

  Future<void> clearAllNotifications(String uid) async {
    final notifications = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("notifications")
        .get();

    for (final doc in notifications.docs) {
      await doc.reference.delete();
    }
  }

  IconData getIcon(String type) {
    if (type == "like") {
      return Icons.favorite;
    }

    if (type == "comment") {
      return Icons.comment;
    }

    if (type == "follow") {
      return Icons.person_add;
    }

    return Icons.notifications;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      markAllAsRead(currentUser.uid);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: Colors.black,

        actions: [
          if (currentUser != null)
            IconButton(
              onPressed: () {
                clearAllNotifications(currentUser.uid);
              },
              icon: const Icon(Icons.delete_sweep),
            ),
        ],
      ),

      body: currentUser == null
          ? const Center(child: Text("Please login first"))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("users")
                  .doc(currentUser.uid)
                  .collection("notifications")
                  .orderBy("createdAt", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No notifications yet"));
                }

                final notifications = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(10),

                  itemCount: notifications.length,

                  itemBuilder: (context, index) {
                    final data =
                        notifications[index].data() as Map<String, dynamic>;

                    final type = data["type"] ?? "";

                    return Card(
                      color: Colors.grey[900],

                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.purple,

                          child: Icon(getIcon(type), color: Colors.white),
                        ),

                        title: Text(data["message"] ?? ""),

                        subtitle: Text(formatTime(data["createdAt"])),

                        trailing: IconButton(
                          onPressed: () async {
                            await notifications[index].reference.delete();
                          },
                          icon: const Icon(Icons.close, color: Colors.red),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
