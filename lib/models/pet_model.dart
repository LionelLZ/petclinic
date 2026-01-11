import 'package:cloud_firestore/cloud_firestore.dart';

class Pet {
  final String id;
  final String name;
  final String breed;
  final String species;
  final String gender;
  final int age; // in years
  final double weight; // kg
  final String imageUrl;
  final DateTime? birthDate;
  final String ownerId;
  final bool vaccinated;
  final DateTime? lastCheckup;

  // 🕒 timestamps
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Pet({
    required this.id,
    required this.name,
    required this.breed,
    required this.species,
    required this.gender,
    required this.age,
    required this.weight,
    required this.imageUrl,
    required this.ownerId,
    this.birthDate,
    this.lastCheckup,
    this.vaccinated = false,
    this.createdAt,
    this.updatedAt,
  });

  // 🔁 Firestore / JSON → Object
  factory Pet.fromJson(Map<String, dynamic> json, String id) {
    return Pet(
      id: id,
      name: json['name'],
      breed: json['breed'],
      species: json['species'],
      gender: json['gender'],
      age: json['age'],
      weight: (json['weight'] as num).toDouble(),
      imageUrl: json['image_url'],
      ownerId: json['owner_id'],
      vaccinated: json['vaccinated'] ?? false,
      birthDate: json['birth_date'] != null
          ? DateTime.parse(json['birth_date'])
          : null,
      lastCheckup: json['last_checkup'] != null
          ? DateTime.parse(json['last_checkup'])
          : null,

      // 🔥 timestamps
      createdAt: (json['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (json['updated_at'] as Timestamp?)?.toDate(),
    );
  }

  Pet copyWith({
    String? id,
    String? name,
    String? breed,
    String? species,
    String? gender,
    int? age,
    double? weight,
    String? imageUrl,
    String? ownerId,
    bool? vaccinated,
    DateTime? birthDate,
    DateTime? lastCheckup,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Pet(
      id: id ?? this.id,
      name: name ?? this.name,
      breed: breed ?? this.breed,
      species: species ?? this.species,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      imageUrl: imageUrl ?? this.imageUrl,
      ownerId: ownerId ?? this.ownerId,
      vaccinated: vaccinated ?? this.vaccinated,
      birthDate: birthDate ?? this.birthDate,
      lastCheckup: lastCheckup ?? this.lastCheckup,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // 🔁 Object → Firestore / JSON
  Map<String, dynamic> toJson({bool isUpdate = false}) {
    return {
      'name': name,
      'breed': breed,
      'species': species,
      'gender': gender,
      'age': age,
      'weight': weight,
      'image_url': imageUrl,
      'owner_id': ownerId,
      'vaccinated': vaccinated,
      'birth_date': birthDate?.toIso8601String(),
      'last_checkup': lastCheckup?.toIso8601String(),

      // 🔥 timestamps
      'created_at':
      isUpdate ? createdAt : FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
  }
}
