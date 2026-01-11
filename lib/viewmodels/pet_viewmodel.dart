import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/pet_model.dart';
import '../services/pet_service.dart';

class PetViewModel extends ChangeNotifier {
  final PetService _petService = PetService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Pet> _pets = [];
  bool _hasLoaded = false;

  List<Pet> get pets => _pets;

  /// Always returns current logged-in user's UID
  String get _ownerId {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    return user.uid;
  }

  /// Load pets for current user only
  Future<void> loadPets() async {
    if (_hasLoaded) return;

    _hasLoaded = true;
    _pets = await _petService.getPetsByOwner(_ownerId);
    notifyListeners();
  }

  /// Add pet → ownerId assigned automatically
  Future<Pet> addPet(Pet pet) async {
    // Add pet via service and get the saved pet with ID
    final savedPet = await _petService.addPet(
      pet.copyWith(
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    // Add to local list so UI updates immediately
    _pets.add(savedPet);
    notifyListeners();

    return savedPet;
  }

  /// Update pet (ownerId unchanged)
  Future<void> updatePet(Pet pet) async {
    final updatedPet = pet.copyWith(
      updatedAt: DateTime.now(),
    );

    await _petService.updatePet(updatedPet);

    final index = _pets.indexWhere((p) => p.id == pet.id);
    if (index != -1) {
      _pets[index] = updatedPet;
      notifyListeners();
    }
  }

  /// Delete pet
  Future<void> deletePet(String petId) async {
    await _petService.deletePet(petId);
    _pets.removeWhere((p) => p.id == petId);
    notifyListeners();
  }

  /// Call this on logout
  void reset() {
    _pets = [];
    _hasLoaded = false;
    notifyListeners();
  }
}
