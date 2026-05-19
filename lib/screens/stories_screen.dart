import 'package:flutter/material.dart';

class StoriesScreen extends StatelessWidget {
  final String userName;

  const StoriesScreen({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.grey[900],
              child: const Icon(Icons.image, size: 120, color: Colors.white),
            ),
          ),

          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.purple,
                  child: Icon(Icons.person, color: Colors.white),
                ),

                const SizedBox(width: 10),

                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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
          ),
        ],
      ),
    );
  }
}
