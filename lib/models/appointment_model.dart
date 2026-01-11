import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  String? id; // Firestore document ID
  String petId;
  String petName;
  String ownerId;
  String ownerName;
  String doctorId;
  String doctorName;
  DateTime appointmentDate;
  String service; // e.g., "Vaccination", "Checkup", "Grooming"
  String status; // e.g., "Scheduled", "Completed", "Cancelled"
  String? notes;
  DateTime createdAt;
  DateTime updatedAt;

  Appointment({
    this.id,
    required this.petId,
    required this.petName,
    required this.ownerId,
    required this.ownerName,
    required this.doctorId,
    required this.doctorName,
    required this.appointmentDate,
    required this.service,
    this.status = "Scheduled",
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Convert Firestore document to Appointment object
  factory Appointment.fromMap(Map<String, dynamic> map, String id) {
    return Appointment(
      id: id,
      petId: map['petId'] ?? '',
      petName: map['petName'] ?? '',
      ownerId: map['ownerId'] ?? '',
      ownerName: map['ownerName'] ?? '',
      doctorId: map['doctorId'] ?? '',
      doctorName: map['doctorName'] ?? '',
      appointmentDate: (map['appointmentDate'] as Timestamp).toDate(),
      service: map['service'] ?? '',
      status: map['status'] ?? 'Scheduled',
      notes: map['notes'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Convert Appointment object to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'petId': petId,
      'petName': petName,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'appointmentDate': appointmentDate,
      'service': service,
      'status': status,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
