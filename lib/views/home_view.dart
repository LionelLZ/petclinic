import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/pet_viewmodel.dart';
import '../views/pet/pet_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    // Load pets once after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PetViewModel>().loadPets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();

    // AUTH GUARD
    if (!authVM.isLoggedIn) return const SizedBox.shrink();

    final userStream = authVM.userStream;
    if (userStream == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<AppUser>(
      stream: userStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return const Center(child: Text("User data not found"));
        }

        final user = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            elevation: 0,
            backgroundColor: Colors.white,
            title: Row(
              children: [
                const Icon(Icons.pets, color: Color(0xFF10B981)),
                const SizedBox(width: 8),
                Text(
                  'Hi, ${user.name ?? 'Pet Lover'} 👋',
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.black),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.red),
                onPressed: () => _confirmLogout(context),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!user.profileComplete) _profileWarning(context),
                  const SizedBox(height: 16),
                  Text('Role: ${user.role}', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  _searchBar(),
                  const SizedBox(height: 20),
                  _appointmentCard(context),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "My Pets",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const PetView()));
                        },
                        child: const Text("Manage", style: TextStyle(color: Color(0xFF10B981))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _petPreview(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ================= UI HELPERS =================
  Widget _profileWarning(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: Colors.orange),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Please complete your profile to unlock all features.'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/complete-profile');
            },
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Material(
      child: TextField(
        decoration: InputDecoration(
          hintText: "Search for vets, services...",
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _appointmentCard(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final uid = authVM.currentUser?.uid;

    if (uid == null) return _emptyAppointmentCard();

    final now = DateTime.now();
    final nowRounded = DateTime(now.year, now.month, now.day, now.hour, now.minute);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('ownerId', isEqualTo: uid)
          .where('appointmentDate', isGreaterThanOrEqualTo: nowRounded)
          .orderBy('appointmentDate', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _loadingAppointmentCard();
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) return _emptyAppointmentCard();

        final appt = docs.first;
        final apptDate = (appt['appointmentDate'] as Timestamp).toDate();
        final doctorName = appt['doctorName'] ?? "Doctor";
        final service = appt['service'] ?? "Service";

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade400,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Next Appointment",
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                "$service with $doctorName",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                "On ${DateFormat('dd/MM/yyyy').format(apptDate)} at ${TimeOfDay.fromDateTime(apptDate).format(context)}",
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _emptyAppointmentCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade400,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Text(
        "No upcoming appointments",
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _loadingAppointmentCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade400,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  Widget _petPreview(BuildContext context) {
    final petVM = context.watch<PetViewModel>();

    if (petVM.pets.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: const Text("No pets added yet 🐾"),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: petVM.pets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, index) {
          final pet = petVM.pets[index];
          return Container(
            width: 110,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: (pet.imageUrl.isNotEmpty)
                      ? (pet.imageUrl.startsWith('assets/')
                      ? AssetImage(pet.imageUrl)
                      : FileImage(File(pet.imageUrl)) as ImageProvider)
                      : const AssetImage('assets/default_pet.png'),
                ),
                const SizedBox(height: 8),
                Text(pet.name, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                Text(pet.breed, style: const TextStyle(fontSize: 11, color: Colors.grey), overflow: TextOverflow.ellipsis),
              ],
            ),
          );
        },
      ),
    );
  }

  // ================= LOGOUT CONFIRMATION =================
  Future<void> _confirmLogout(BuildContext context) async {
    final authVM = context.read<AuthViewModel>();

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Confirm Logout", style: TextStyle(color: Colors.white)),
          content: const Text("Are you sure you want to log out?", style: TextStyle(color: Colors.white)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel", style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Logout", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await authVM.logout();
    }
  }
}
