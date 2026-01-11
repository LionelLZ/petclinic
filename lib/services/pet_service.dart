import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import '../models/pet_model.dart';

class PetService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _collection = 'pets';

  // 🔹 Add a new pet (guarantees owner_id is saved)
  Future<Pet> addPet(Pet pet) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    // Create a document reference with auto-generated ID
    final docRef = _db.collection(_collection).doc();

    // Assign ownerId and doc ID
    final petWithOwner = pet.copyWith(
      id: docRef.id,
      ownerId: user.uid,
    );

    // Save to Firestore
    await docRef.set(petWithOwner.toJson());

    debugPrint('Pet saved: ${petWithOwner.name}, owner_id: ${user.uid}');

    // Return the saved pet
    return petWithOwner;
  }


  // 🔹 Update an existing pet
  Future<void> updatePet(Pet pet) async {
    if (pet.id.isEmpty) throw Exception('Pet ID is empty');

    await _db
        .collection(_collection)
        .doc(pet.id)
        .update(pet.toJson(isUpdate: true));

    debugPrint('Pet updated: ${pet.name}');
  }

  // 🔹 Delete a pet
  Future<void> deletePet(String petId) async {
    await _db.collection(_collection).doc(petId).delete();
    debugPrint('Pet deleted: $petId');
  }

  // 🔹 Get all pets for a specific owner
  Future<List<Pet>> getPetsByOwner(String ownerId) async {
    final snapshot = await _db
        .collection(_collection)
        .where('owner_id', isEqualTo: ownerId)
        .orderBy('created_at', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Pet.fromJson(doc.data(), doc.id))
        .toList();
  }

  // 🔹 Get all pets for the currently logged-in user
  Future<List<Pet>> getPetsForCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    return getPetsByOwner(user.uid);
  }

  // 🔹 Get a single pet by ID
  Future<Pet?> getPetById(String petId) async {
    final doc = await _db.collection(_collection).doc(petId).get();

    if (!doc.exists) return null;

    return Pet.fromJson(doc.data()!, doc.id);
  }

  // 🔹 Real-time stream of pets for a specific owner
  Stream<List<Pet>> streamPetsByOwner(String ownerId) {
    return _db
        .collection(_collection)
        .where('owner_id', isEqualTo: ownerId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => Pet.fromJson(doc.data(), doc.id))
          .toList(),
    );
  }

  // 🔹 Real-time stream of pets for the currently logged-in user
  Stream<List<Pet>> streamPetsForCurrentUser() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return streamPetsByOwner(user.uid);
  }
}
