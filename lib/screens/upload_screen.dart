import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final captionController = TextEditingController();

  final imageUrlController = TextEditingController();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    imageUrlController.addListener(() {
      setState(() {});
    });
  }

  Future<void> uploadPost() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return;
    }

    if (captionController.text.trim().isEmpty &&
        imageUrlController.text.trim().isEmpty) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(currentUser.uid)
          .get();

      final userData = userDoc.data();

      await FirebaseFirestore.instance.collection("posts").add({
        "caption": captionController.text.trim(),

        "imageUrl": imageUrlController.text.trim(),

        "uid": currentUser.uid,

        "userName": userData?["name"] ?? "User",

        "username": userData?["username"] ?? "user",

        "photoUrl": userData?["photoUrl"] ?? "",

        "likes": [],

        "edited": false,

        "createdAt": DateTime.now(),
      });

      captionController.clear();
      imageUrlController.clear();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Post uploaded")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    captionController.dispose();
    imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload"),
        backgroundColor: Colors.black,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              "Create Post",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: captionController,

              maxLines: 4,

              decoration: InputDecoration(
                hintText: "Write a caption...",

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: imageUrlController,

              decoration: InputDecoration(
                hintText: "Paste image URL...",

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (imageUrlController.text.trim().isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Preview",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),

                    child: Image.network(
                      imageUrlController.text.trim(),

                      height: 220,

                      width: double.infinity,

                      fit: BoxFit.cover,

                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) {
                          return child;
                        }

                        return Container(
                          height: 220,
                          alignment: Alignment.center,
                          color: Colors.grey[900],
                          child: const CircularProgressIndicator(),
                        );
                      },

                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 220,
                          alignment: Alignment.center,
                          color: Colors.grey[900],
                          child: const Text("Invalid image URL"),
                        );
                      },
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,

              height: 50,

              child: ElevatedButton(
                onPressed: isLoading ? null : uploadPost,

                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text("Upload Post"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
