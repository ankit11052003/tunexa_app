import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'main_screen.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;

  InputDecoration inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.grey[900],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  Future<void> signupUser() async {
    if (nameController.text.trim().isEmpty ||
        usernameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      final username = usernameController.text.trim().toLowerCase();

      final usernameCheck = await FirebaseFirestore.instance
          .collection("users")
          .where("username", isEqualTo: username)
          .get();

      if (usernameCheck.docs.isNotEmpty) {
        setState(() {
          isLoading = false;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Username already taken")));
        return;
      }

      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      await FirebaseFirestore.instance
          .collection("users")
          .doc(credential.user!.uid)
          .set({
            "name": nameController.text.trim(),
            "username": username,
            "email": emailController.text.trim(),
            "bio": "",
            "followers": [],
            "following": [],
            "savedPosts": [],
            "createdAt": DateTime.now(),
          });

      setState(() {
        isLoading = false;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? "Signup failed")));
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.flash_on, color: Colors.purple, size: 95),

              const SizedBox(height: 20),

              const Text(
                "Create Account",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "Join Tunexa today",
                style: TextStyle(color: Colors.grey, fontSize: 15),
              ),

              const SizedBox(height: 35),

              TextField(
                controller: nameController,
                decoration: inputDecoration("Full Name", Icons.person),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: usernameController,
                decoration: inputDecoration("Username", Icons.alternate_email),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: inputDecoration("Email", Icons.email),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: inputDecoration("Password", Icons.lock),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : signupUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Sign Up",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                child: const Text(
                  "Already have an account? Login",
                  style: TextStyle(color: Colors.purple),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
