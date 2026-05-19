import 'package:flutter/material.dart';

class PostDetailScreen extends StatelessWidget {
  final String userName;
  final String username;
  final String caption;
  final String date;
  final String imageUrl;

  const PostDetailScreen({
    super.key,
    required this.userName,
    this.username = "user",
    required this.caption,
    required this.date,
    this.imageUrl = "",
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Post Detail"),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Colors.purple,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(userName),
                  subtitle: Text("@$username • $date"),
                ),

                const SizedBox(height: 15),

                if (imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),

                if (imageUrl.isNotEmpty) const SizedBox(height: 20),

                Text(caption, style: const TextStyle(fontSize: 18)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
