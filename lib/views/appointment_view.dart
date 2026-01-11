import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/appointment_model.dart';
import '../viewmodels/appointment_viewmodel.dart';
import '../models/pet_model.dart';
import '../models/doctor_model.dart';
import 'home_view.dart';

class BookVisitView extends StatefulWidget {
  const BookVisitView({super.key});

  @override
  State<BookVisitView> createState() => _BookVisitViewState();
}

class _BookVisitViewState extends State<BookVisitView> {
  List<Pet> pets = [];
  List<Doctor> doctors = [];

  Pet? selectedPet;
  Doctor? selectedDoctor;

  final List<String> services = [
    "General Checkup",
    "Vaccination",
    "Surgery Consultation",
    "Dental Care",
    "Grooming",
    "Emergency",
  ];

  String selectedService = "General Checkup";

  DateTime selectedDate = DateTime.now();
  TimeOfDay? selectedTime;
  List<TimeOfDay> bookedTimes = [];

  final TextEditingController notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadPets();
    loadDoctors();
  }

  Future<void> loadPets() async {
    final user = FirebaseAuth.instance.currentUser;

    print("🔥 Current user UID: ${user?.uid}");

    if (user == null) {
      print("❌ User is NULL");
      setState(() {
        pets = [];
        selectedPet = null;
      });
      return;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('pets')
        .where('owner_id', isEqualTo: user.uid)
        .get();

    print("🐶 Pets found: ${snapshot.docs.length}");

    final data = snapshot.docs
        .map((doc) => Pet.fromJson(doc.data(), doc.id))
        .toList();

    setState(() {
      pets = data;
      selectedPet = pets.isNotEmpty ? pets.first : null;
    });
  }



  Future<void> loadDoctors() async {
    final snapshot =
    await FirebaseFirestore.instance.collection('doctors').get();

    final data = snapshot.docs.map((doc) {
      return Doctor.fromMap({
        'id': doc.id,
        'name': doc['name'],
        'photoUrl': doc['photoUrl'] ??
            'https://i.pravatar.cc/150?img=3',
        'workStart': doc['workStart'] ?? 9,
        'workEnd': doc['workEnd'] ?? 17,
      });
    }).toList();

    setState(() {
      doctors = data;
      if (doctors.isNotEmpty) selectedDoctor = doctors.first;
    });

    await loadBookedTimes();
  }

  Future<void> loadBookedTimes() async {
    if (selectedDoctor == null) return;

    final start = DateTime(
        selectedDate.year, selectedDate.month, selectedDate.day, 0, 0);
    final end = DateTime(
        selectedDate.year, selectedDate.month, selectedDate.day, 23, 59);

    final snapshot = await FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: selectedDoctor!.id)
        .where('appointmentDate', isGreaterThanOrEqualTo: start)
        .where('appointmentDate', isLessThanOrEqualTo: end)
        .get();

    bookedTimes = snapshot.docs.map((doc) {
      final dt = (doc['appointmentDate'] as Timestamp).toDate();
      return TimeOfDay(hour: dt.hour, minute: dt.minute);
    }).toList();

    if (selectedTime != null &&
        bookedTimes.any((t) =>
        t.hour == selectedTime!.hour &&
            t.minute == selectedTime!.minute)) {
      selectedTime = null;
    }

    setState(() {});
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
      await loadBookedTimes();
    }
  }

  List<TimeOfDay> generateTimeSlots() {
    if (selectedDoctor == null) return [];

    List<TimeOfDay> slots = [];
    for (int h = selectedDoctor!.workStart; h < selectedDoctor!.workEnd; h++) {
      slots.add(TimeOfDay(hour: h, minute: 0));
      slots.add(TimeOfDay(hour: h, minute: 15));
      slots.add(TimeOfDay(hour: h, minute: 30));
      slots.add(TimeOfDay(hour: h, minute: 45));
    }
    return slots;
  }

  bool isSlotBooked(TimeOfDay slot) {
    return bookedTimes.any(
            (t) => t.hour == slot.hour && t.minute == slot.minute);
  }

  void showConfirmationDialog() async {
    if (selectedPet == null ||
        selectedDoctor == null ||
        selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all required fields")),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Appointment"),
        content: Text(
          "Pet: ${selectedPet!.name}\n"
              "Service: $selectedService\n"
              "Doctor: ${selectedDoctor!.name}\n"
              "Date: ${DateFormat('dd/MM/yyyy').format(selectedDate)}\n"
              "Time: ${selectedTime!.format(context)}",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Confirm"),
          ),
        ],
      ),
    ) ?? false;

    if (!confirmed) return;

    final appointmentDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    final conflict = await FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: selectedDoctor!.id)
        .where('appointmentDate', isEqualTo: appointmentDateTime)
        .get();

    if (conflict.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("This slot is already booked")),
      );
      return;
    }

    final appointment = Appointment(
      petId: selectedPet!.id,
      petName: selectedPet!.name,
      ownerId: selectedPet!.ownerId,
      doctorId: selectedDoctor!.id,
      doctorName: selectedDoctor!.name,
      appointmentDate: appointmentDateTime,
      service: selectedService,
      notes: notesController.text,
      ownerName: '',
    );

    await Provider.of<AppointmentViewModel>(context, listen: false)
        .addAppointment(appointment);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Appointment booked successfully")),
    );

    // ✅ Navigate to HomeView after booking
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeView()), // replace with your HomeView
          (route) => false,
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Book a Visit"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            _title("Select Pet"),
            SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: pets.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final pet = pets[i];
                  final selected = selectedPet?.id == pet.id;

                  return GestureDetector(
                    onTap: () => setState(() => selectedPet = pet),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(
                        color:
                        selected ? Colors.deepPurple : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        pet.name,
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            _title("Service"),
            _card(
              DropdownButtonFormField<String>(
                value: selectedService,
                decoration: const InputDecoration(border: InputBorder.none),
                items: services
                    .map((s) =>
                    DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => selectedService = v!),
              ),
            ),

            const SizedBox(height: 20),

            _title("Veterinarian"),
            _card(
              DropdownButtonFormField<String>(
                value: selectedDoctor?.id,
                decoration: const InputDecoration(border: InputBorder.none),
                items: doctors.map((doc) {
                  return DropdownMenuItem(
                    value: doc.id,
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: NetworkImage(doc.photoUrl),
                        ),
                        const SizedBox(width: 10),
                        Text(doc.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (v) async {
                  setState(() {
                    selectedDoctor =
                        doctors.firstWhere((d) => d.id == v);
                  });
                  await loadBookedTimes();
                },
              ),
            ),

            const SizedBox(height: 20),

            _title("Date"),
            _card(
              ListTile(
                title:
                Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: pickDate,
              ),
            ),

            const SizedBox(height: 20),

            _title("Time"),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: generateTimeSlots().length,
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.8,
              ),
              itemBuilder: (_, i) {
                final slot = generateTimeSlots()[i];
                final booked = isSlotBooked(slot);
                final selected = selectedTime?.hour == slot.hour &&
                    selectedTime?.minute == slot.minute;

                return GestureDetector(
                  onTap:
                  booked ? null : () => setState(() => selectedTime = slot),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: booked
                          ? Colors.grey.shade300
                          : selected
                          ? Colors.deepPurple
                          : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected
                            ? Colors.deepPurple
                            : Colors.grey.shade400,
                      ),
                    ),
                    child: Text(
                      slot.format(context),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: booked
                            ? Colors.grey
                            : selected
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            _title("Notes"),
            _card(
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: "Symptoms or special care needs...",
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: showConfirmationDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "Confirm Visit",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _title(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _card(Widget child) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: child,
    );
  }
}
