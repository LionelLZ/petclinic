import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/pet_model.dart';
import '../../viewmodels/pet_viewmodel.dart';

class PetView extends StatefulWidget {
  const PetView({Key? key}) : super(key: key);

  @override
  State<PetView> createState() => _PetViewState();
}

class _PetViewState extends State<PetView> {
  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PetViewModel>().loadPets();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "My Pets",
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF10B981),
        icon: const Icon(Icons.add),
        label: const Text("Add Pet"),
        onPressed: () => _showAddPetDialog(context),
      ),
      body: Consumer<PetViewModel>(
        builder: (_, vm, __) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _searchBar(),
                const SizedBox(height: 14),
                Text(
                  "${vm.pets.length} Pets total",
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: vm.pets.isEmpty
                      ? _emptyState()
                      : ListView.separated(
                    itemCount: vm.pets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (_, i) => _modernPetCard(vm.pets[i]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ===================== Modern Pet Card =====================
  Widget _modernPetCard(Pet pet) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 70,
              height: 70,
              child: Image(
                image: pet.imageUrl.startsWith('assets/')
                    ? AssetImage(pet.imageUrl)
                    : FileImage(File(pet.imageUrl)) as ImageProvider,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pet.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${pet.breed} • ${pet.age} years",
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _pill(pet.species, Colors.blue),
                    _pill(pet.gender, Colors.orange),
                    if (pet.vaccinated)
                      _pill("Vaccinated", const Color(0xFF10B981)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _confirmDeletePet(pet.id),
          ),
        ],
      ),
    );
  }

  // ===================== Delete Confirmation =====================
  void _confirmDeletePet(String petId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Pet"),
        content: const Text("Are you sure you want to delete this pet?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await context.read<PetViewModel>().deletePet(petId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Pet deleted successfully"),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // ===================== Pills =====================
  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ===================== Search Bar =====================
  Widget _searchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const TextField(
        decoration: InputDecoration(
          hintText: "Search by name, breed or species...",
          border: InputBorder.none,
          icon: Icon(Icons.search),
        ),
      ),
    );
  }

  // ===================== Empty State =====================
  Widget _emptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.pets, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text("No pets yet",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 6),
          Text("Add your furry friends", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // ===================== ADD PET DIALOG =====================
  void _showAddPetDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final breedCtrl = TextEditingController();
    final weightCtrl = TextEditingController(text: "1");

    DateTime? birthDate;
    String species = "Dog";
    String gender = "Male";
    bool vaccinated = false;
    _pickedImage = null;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      const Text(
                        "Create Pet Profile",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Image Picker
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 42,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: _pickedImage != null
                              ? FileImage(_pickedImage!)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () async {
                              final picked = await ImagePicker()
                                  .pickImage(source: ImageSource.gallery);
                              if (picked != null) {
                                setState(() {
                                  _pickedImage = File(picked.path);
                                });
                              }
                            },
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.white,
                              child: const Icon(Icons.camera_alt, size: 16),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Name & Breed
                  Row(
                    children: [
                      Expanded(child: _roundedInput(nameCtrl, "Pet Name")),
                      const SizedBox(width: 12),
                      Expanded(child: _roundedInput(breedCtrl, "Breed")),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Species & Weight
                  Row(
                    children: [
                      Expanded(
                        child: _roundedDropdown(
                          value: species,
                          items: const ["Dog", "Cat"],
                          onChanged: (v) => setState(() => species = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _roundedInput(
                          weightCtrl,
                          "Weight (kg)",
                          keyboard: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Birth Date
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                        initialDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => birthDate = picked);
                    },
                    child: _roundedContainer(
                      child: Row(
                        children: [
                          Text(
                            birthDate == null
                                ? "Date of Birth"
                                : "${birthDate!.day}/${birthDate!.month}/${birthDate!.year}",
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const Spacer(),
                          const Icon(Icons.calendar_today, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Gender Chips
                  Row(
                    children: [
                      Expanded(
                        child: _genderChip(
                          "Male",
                          gender,
                              () => setState(() => gender = "Male"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _genderChip(
                          "Female",
                          gender,
                              () => setState(() => gender = "Female"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Vaccinated
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9F9F1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xFF10B981)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text("Vaccinated",
                                  style:
                                  TextStyle(fontWeight: FontWeight.w600)),
                              SizedBox(height: 2),
                              Text("Is this pet up to date with shots?",
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        Switch(
                          value: vaccinated,
                          activeThumbColor: const Color(0xFF10B981),
                          onChanged: (v) => setState(() => vaccinated = v),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ===== SAVE PROFILE BUTTON =====
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: const BorderSide(color: Color(0xFF10B981)),
                      ),
                    ),
                    icon: const Icon(Icons.add, color: Color(0xFF10B981)),
                    label: const Text(
                      "Save Profile",
                      style: TextStyle(
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.w600),
                    ),
                    onPressed: () async {
                      if (nameCtrl.text.isEmpty ||
                          weightCtrl.text.isEmpty ||
                          birthDate == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please fill all required fields."),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return;
                      }

                      final age = DateTime.now().year - birthDate!.year;

                      final newPet = Pet(
                        id: '',
                        name: nameCtrl.text,
                        breed: breedCtrl.text,
                        species: species,
                        age: age,
                        weight: double.tryParse(weightCtrl.text) ?? 1.0,
                        gender: gender,
                        vaccinated: vaccinated,
                        imageUrl: _pickedImage?.path ?? "assets/dog.jpg",
                        ownerId: '',
                        birthDate: birthDate,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      );

                      // ✅ Confirmation dialog before saving
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Confirm Save"),
                          content: Text(
                              "Are you sure you want to save ${newPet.name}?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text("Yes"),
                            ),
                          ],
                        ),
                      );

                      if (confirm != true) return; // User canceled

                      try {
                        await context
                            .read<PetViewModel>()
                            .addPet(newPet);

                        Navigator.pop(context); // Close Add Pet dialog

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                            Text("${newPet.name} saved successfully!"),
                            backgroundColor: const Color(0xFF10B981),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Error saving pet: $e"),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================= HELPERS =================
  Widget _roundedInput(TextEditingController c, String hint,
      {TextInputType keyboard = TextInputType.text}) {
    return TextField(
      controller: c,
      keyboardType: keyboard,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _roundedDropdown(
      {required String value,
        required List<String> items,
        required ValueChanged<String?> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _roundedContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }

  Widget _genderChip(String text, String selected, VoidCallback onTap) {
    final isActive = text == selected;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF10B981) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
