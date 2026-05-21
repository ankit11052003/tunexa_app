import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UploadStoryScreen extends StatefulWidget {
  const UploadStoryScreen({super.key});

  @override
  State<UploadStoryScreen> createState() => _UploadStoryScreenState();
}

class _UploadStoryScreenState extends State<UploadStoryScreen> {
  final storyUrlController = TextEditingController();
  bool isLoading = false;

  Future<void> uploadStory() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;
    if (storyUrlController.text.trim().isEmpty) return;

    setState(() {
      isLoading = true;
    });

    final userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    final userData = userDoc.data();

    await FirebaseFirestore.instance.collection("stories").add({
      "uid": user.uid,
      "userName": userData?["name"] ?? "User",
      "username": userData?["username"] ?? "user",
      "photoUrl": userData?["photoUrl"] ?? "",
      "storyUrl": storyUrlController.text.trim(),
      "createdAt": DateTime.now(),
      "expiresAt": DateTime.now().add(const Duration(hours: 24)),
    });

    storyUrlController.clear();

    setState(() {
      isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Story uploaded")));

      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    storyUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storyUrl = storyUrlController.text.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload Story"),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: storyUrlController,
              onChanged: (_) {
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: "Paste story image URL",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (storyUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  storyUrl,
                  height: 400,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : uploadStory,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text("Upload Story"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
