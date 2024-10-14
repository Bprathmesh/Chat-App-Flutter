import 'package:cloud_firestore/cloud_firestore.dart';
class AppUser {  // Changed from User to AppUser
  final String id;
  final String name;
  final String email;
  final DateTime createdAt;
  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
  });
  // Create an AppUser instance from a Firestore document
  factory AppUser.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
  // Convert AppUser instance to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}