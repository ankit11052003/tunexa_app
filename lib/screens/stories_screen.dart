import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StoriesScreen extends StatefulWidget {
  final String storyId;
  final String userName;
  final String storyUrl;
  final String photoUrl;

  const StoriesScreen({
    super.key,
    required this.storyId,
    required this.userName,
    required this.storyUrl,
    required this.photoUrl,
  });

  @override
  State<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<StoriesScreen> {
  Future<void> markStoryAsSeen() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return;

    await FirebaseFirestore.instance
        .collection("stories")
        .doc(widget.storyId)
        .update({
          "seenBy": FieldValue.arrayUnion([currentUser.uid]),
        });
  }

  @override
  void initState() {
    super.initState();

    markStoryAsSeen();

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      body: GestureDetector(
        onTap: () {
          Navigator.pop(context);
        },

        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                widget.storyUrl,
                fit: BoxFit.cover,

                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Text(
                      "Story image failed to load",
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                },
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),

                child: Column(
                  children: [
                    Container(
                      height: 4,
                      width: double.infinity,

                      decoration: BoxDecoration(
                        color: Colors.white,

                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    const SizedBox(height: 15),

                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.purple,

                          backgroundImage: widget.photoUrl.isNotEmpty
                              ? NetworkImage(widget.photoUrl)
                              : null,

                          child: widget.photoUrl.isEmpty
                              ? const Icon(Icons.person, color: Colors.white)
                              : null,
                        ),

                        const SizedBox(width: 10),

                        Text(
                          widget.userName,

                          style: const TextStyle(
                            color: Colors.white,

                            fontWeight: FontWeight.bold,

                            fontSize: 16,
                          ),
                        ),

                        const Spacer(),

                        IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },

                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
