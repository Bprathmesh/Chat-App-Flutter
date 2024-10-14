import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'user_model.dart';
import 'login_page.dart';
class HomePage extends StatelessWidget {
  final AppUser user;  // Changed from User to AppUser
  HomePage({required this.user});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My chat Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Sign out from Firebase Auth
              await FirebaseAuth.instance.signOut();
              // Navigate back to login page
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome, ${user.name}!'),
            const SizedBox(height: 20),
            Text('Email: ${user.email}'),
            const SizedBox(height: 20),
            Text('Account created on: ${user.createdAt.toLocal()}'),
          ],
        ),
      ),
    );
  }
}