import 'package:flutter/material.dart';
import '../models/appointment_model.dart';
import '../services/appointment_service.dart';

class AppointmentViewModel extends ChangeNotifier {
  final AppointmentService _service = AppointmentService();

  List<Appointment> _appointments = [];
  List<Appointment> get appointments => _appointments;

  bool _loading = false;
  bool get loading => _loading;

  AppointmentViewModel() {
    loadAppointments(); // automatically load appointments when ViewModel is created
  }

  // Load all appointments as a stream
  void loadAppointments() {
    _loading = true;
    notifyListeners();

    _service.getAppointmentsStream().listen((data) {
      _appointments = data;
      _loading = false;
      notifyListeners();
    });
  }

  // Add a new appointment
  Future<void> addAppointment(Appointment appointment) async {
    _loading = true;
    notifyListeners();

    await _service.addAppointment(appointment);

    _loading = false;
    notifyListeners();
  }

  // Update an existing appointment
  Future<void> updateAppointment(Appointment appointment) async {
    _loading = true;
    notifyListeners();

    await _service.updateAppointment(appointment);

    _loading = false;
    notifyListeners();
  }

  // Delete an appointment
  Future<void> deleteAppointment(String id) async {
    _loading = true;
    notifyListeners();

    await _service.deleteAppointment(id);

    _loading = false;
    notifyListeners();
  }

  // Optional: Get a single appointment by ID
  Future<Appointment?> getAppointment(String id) async {
    return await _service.getAppointment(id);
  }
}
