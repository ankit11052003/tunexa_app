import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'signup_screen.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();

  final passwordController = TextEditingController();

  bool isLoading = false;

  Future<void> loginUser() async {
    if (emailController.text.trim().isEmpty ||
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

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

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
      ).showSnackBar(SnackBar(content: Text(e.message ?? "Login failed")));
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  InputDecoration inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,

      hintStyle: const TextStyle(color: Colors.grey),

      prefixIcon: Icon(icon, color: Colors.purple),

      filled: true,

      fillColor: Colors.grey[900],

      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
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
                "Welcome Back",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "Login to continue Tunexa",
                style: TextStyle(color: Colors.grey, fontSize: 15),
              ),

              const SizedBox(height: 40),

              TextField(
                controller: emailController,

                style: const TextStyle(color: Colors.white),

                keyboardType: TextInputType.emailAddress,

                decoration: inputDecoration("Email", Icons.email),
              ),

              const SizedBox(height: 18),

              TextField(
                controller: passwordController,

                style: const TextStyle(color: Colors.white),

                obscureText: true,

                decoration: inputDecoration("Password", Icons.lock),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : loginUser,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),

                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Login",
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignupScreen(),
                    ),
                  );
                },

                child: const Text(
                  "Don't have an account? Sign Up",
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
