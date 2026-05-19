import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'about_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> logoutUser(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.black,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Account"),
            subtitle: const Text("Manage your profile information"),
            onTap: () {},
          ),

          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text("Privacy"),
            subtitle: const Text("Manage privacy settings"),
            onTap: () {},
          ),

          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text("Notifications"),
            subtitle: const Text("Manage notification preferences"),
            onTap: () {},
          ),

          ListTile(
            leading: const Icon(Icons.info),
            title: const Text("About"),
            subtitle: const Text("Demo App Project"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutScreen()),
              );
            },
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout", style: TextStyle(color: Colors.red)),
            onTap: () {
              logoutUser(context);
            },
          ),
        ],
      ),
    );
  }
}
