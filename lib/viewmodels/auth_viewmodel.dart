import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  AuthViewModel(this._authService);

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get currentUser => _authService.currentUser;



  // ---------------- LOGIN ----------------
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapFirebaseError(e); // ✅ This works now
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ---------------- REGISTER ----------------
  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save display name in Auth
      await credential.user?.updateDisplayName(name);

      // ✅ Create Firestore document for the user
      final uid = credential.user?.uid;
      if (uid != null) {
        await _db.collection('users').doc(uid).set({
          'name': name,
          'email': email,
          'nric': '',      // optional, will be updated later
          'address': '',   // optional, will be updated later
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'profileComplete': false
        });
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapFirebaseError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Account not found. Please register.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'Email already registered. Please login.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Invalid email address.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  // ================= LOGOUT =================
  Future<void> logout() async {
    await _authService.logout();
    notifyListeners();
  }

  // ================= CHECK PROFILE =================
  Future<bool> checkProfileComplete() async {
    final uid = currentUser?.uid;
    if (uid == null) return false;
    return await _authService.isProfileComplete(uid);
  }

  // ================= UPDATE PROFILE =================
  Future<void> updateProfile({
    required String nric,
    required String address,
  }) async {
    final uid = currentUser?.uid; // ✅ get UID as string
    if (uid == null || uid.isEmpty) {
      _error = 'User not logged in';
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      await _db.collection('users').doc(uid).update({
        'nric': nric,
        'address': address,
        'profileComplete': true,
      });

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ================= GET USER DATA =================
  Future<Map<String, dynamic>?> getUserData() async {
    final uid = currentUser?.uid;
    if (uid == null) return null;
    return await _authService.getUserData(uid);
  }

  Stream<AppUser>? get userStream {
    final uid = currentUser?.uid;
    if (uid == null) return null;
    return _authService.streamUser(uid);
  }

  bool get isLoggedIn => _authService.currentUser != null;

  void clearError() {
    _error = null;
    notifyListeners();
  }
  
}
