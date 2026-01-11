import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Current logged-in user
  User? get currentUser => _auth.currentUser;
  FirebaseAuth getFirebaseAuth() => FirebaseAuth.instance;

  // ================= REGISTER =================
  Future<void> registerWithEmail({
    required String name, // <-- added
    required String email,
    required String password,
  }) async {
    final UserCredential cred =
    await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = cred.user!.uid;

    // Save user to Firestore
    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'name': name, // <-- added
      'email': email,
      'profileComplete': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ================= LOGIN =================
  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    // Check if user exists in Firestore
    final query = await _db.collection('users').where('email', isEqualTo: email).get();
    if (query.docs.isEmpty) {
      throw Exception('User not registered. Please register first.');
    }

    // User exists → proceed to login
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // ================= LOGOUT =================
  Future<void> logout() async {
    await _auth.signOut();
  }

  // ================= CHECK PROFILE =================
  Future<bool> isProfileComplete(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();

    if (!doc.exists) return false;

    return doc.data()?['profileComplete'] == true;
  }

  // ================= GET USER DATA =================
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists ? doc.data() : null;
  }

  // ================= UPDATE PROFILE =================
  Future<void> updateProfile({
    required String uid,
    String? name,
    required String nric,
    required String address,
  }) async {
    final updateData = {
      'nric': nric,
      'address': address,
      'profileComplete': true,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (name != null) {
      updateData['name'] = name;
    }

    await _db.collection('users').doc(uid).set(
      updateData,
      SetOptions(merge: true),
    );
  }

  Stream<AppUser> streamUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map(
          (doc) => AppUser.fromMap(doc.id, doc.data()!),
    );
  }
}
