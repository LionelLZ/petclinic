import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String? name; // <-- added name
  final String? email;
  final String? phone;

  // Profile info (optional at first)
  final String? nric;
  final String? address;

  // System fields
  final bool profileComplete;
  final String role;

  final Timestamp createdAt;
  final Timestamp updatedAt;

  AppUser({
    required this.uid,
    this.name,
    this.email,
    this.phone,
    this.nric,
    this.address,
    required this.profileComplete,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  // Firestore → AppUser
  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      name: data['name'], // <-- added
      email: data['email'],
      phone: data['phone'],
      nric: data['nric'],
      address: data['address'],
      profileComplete: data['profileComplete'] ?? false,
      role: data['role'] ?? 'owner',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
    );
  }

  // AppUser → Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name, // <-- added
      'email': email,
      'phone': phone,
      'nric': nric,
      'address': address,
      'profileComplete': profileComplete,
      'role': role,
      'createdAt': createdAt,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
