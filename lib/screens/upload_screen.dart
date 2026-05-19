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

  bool isUploading = false;

  void setSampleImage(int number) {
    setState(() {
      imageUrlController.text = "https://picsum.photos/400/400?random=$number";
    });
  }

  Future<void> uploadPost() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (captionController.text.trim().isEmpty &&
        imageUrlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Write caption or add image URL")),
      );
      return;
    }

    try {
      setState(() {
        isUploading = true;
      });

      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      final userData = userDoc.data();

      await FirebaseFirestore.instance.collection("posts").add({
        "uid": user.uid,
        "caption": captionController.text.trim(),
        "imageUrl": imageUrlController.text.trim(),
        "userName": userData?["name"] ?? "User",
        "username": userData?["username"] ?? "user",
        "likes": [],
        "createdAt": DateTime.now(),
      });

      captionController.clear();
      imageUrlController.clear();

      setState(() {
        isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Post uploaded successfully")),
      );
    } catch (e) {
      setState(() {
        isUploading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  void dispose() {
    captionController.dispose();
    imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = imageUrlController.text.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Post"),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.add_photo_alternate,
                    size: 70,
                    color: Colors.purple,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Create something new",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Add a caption and optional image URL",
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: captionController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "What's on your mind?",
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: imageUrlController,
              style: const TextStyle(color: Colors.white),
              onChanged: (_) {
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: "Paste image URL optional",
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.link, color: Colors.purple),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setSampleImage(1),
                    child: const Text("Sample 1"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setSampleImage(2),
                    child: const Text("Sample 2"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setSampleImage(3),
                    child: const Text("Sample 3"),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            if (imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl,
                  height: 240,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 140,
                      width: double.infinity,
                      alignment: Alignment.center,
                      color: Colors.grey[900],
                      child: const Text("Invalid image URL"),
                    );
                  },
                ),
              ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: isUploading ? null : uploadPost,
                icon: const Icon(Icons.upload),
                label: isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Upload Post"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
