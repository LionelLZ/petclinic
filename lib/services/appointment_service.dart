import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment_model.dart';

class AppointmentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String collectionName = "appointments";

  // Add new appointment
  Future<void> addAppointment(Appointment appointment) async {
    final docRef = _db.collection(collectionName).doc();
    appointment.id = docRef.id;
    await docRef.set(appointment.toMap());
  }

  // Update existing appointment
  Future<void> updateAppointment(Appointment appointment) async {
    appointment.updatedAt = DateTime.now(); // update the updatedAt timestamp
    await _db.collection(collectionName).doc(appointment.id).update(appointment.toMap());
  }

  // Delete appointment
  Future<void> deleteAppointment(String id) async {
    await _db.collection(collectionName).doc(id).delete();
  }

  // Get single appointment by ID
  Future<Appointment?> getAppointment(String id) async {
    final doc = await _db.collection(collectionName).doc(id).get();
    if (doc.exists) {
      return Appointment.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  // Get all appointments as a stream (real-time updates)
  Stream<List<Appointment>> getAppointmentsStream() {
    return _db
        .collection(collectionName)
        .orderBy('appointmentDate')
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Appointment.fromMap(doc.data(), doc.id)).toList());
  }
}
