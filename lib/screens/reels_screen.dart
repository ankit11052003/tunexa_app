import 'package:flutter/material.dart';

class ReelsScreen extends StatelessWidget {
  const ReelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reels = [
      {"caption": "Night vibes 🌙", "color": Colors.purple},
      {"caption": "Tunexa Reels 🔥", "color": Colors.blue},
      {"caption": "Travel moments ✈️", "color": Colors.orange},
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: reels.length,
        itemBuilder: (context, index) {
          final reel = reels[index];

          return Stack(
            children: [
              Container(color: reel["color"] as Color),

              Positioned(
                right: 15,
                bottom: 100,
                child: Column(
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),

                    const SizedBox(height: 20),

                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.comment,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),

                    const SizedBox(height: 20),

                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.share,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ),

              Positioned(
                left: 15,
                bottom: 50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Icon(Icons.person, color: Colors.black),
                        ),

                        SizedBox(width: 10),

                        Text(
                          "tunexa_user",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Text(
                      reel["caption"].toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
