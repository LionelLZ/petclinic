class Doctor {
  final String id;
  final String name;
  final String photoUrl; // URL to the doctor's photo
  final int workStart;    // starting hour of work (0-23)
  final int workEnd;      // ending hour of work (0-23)

  Doctor({
    required this.id,
    required this.name,
    required this.photoUrl,
    this.workStart = 9,  // default 9 AM
    this.workEnd = 17,   // default 5 PM
  });

  factory Doctor.fromMap(Map<String, dynamic> map) {
    return Doctor(
      id: map['id'].toString(),
      name: map['name'] ?? '',
      photoUrl: map['photoUrl'] ?? 'https://i.pravatar.cc/150?img=1',
      workStart: map['workStart'] ?? 9,
      workEnd: map['workEnd'] ?? 17,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'photoUrl': photoUrl,
      'workStart': workStart,
      'workEnd': workEnd,
    };
  }
}
