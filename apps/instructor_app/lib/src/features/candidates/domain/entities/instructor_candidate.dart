class InstructorCandidate {
  const InstructorCandidate({
    this.completedDrivingHours = 0,
    required this.id,
    required this.schoolId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.oib,
    required this.status,
    required this.categoryCode,
    required this.categoryName,
    required this.assignedInstructorId,
    required this.assignedInstructorName,
    required this.notes,
  });

  final int completedDrivingHours;
  final String id;
  final String schoolId;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final String? oib;
  final String status;
  final String categoryCode;
  final String categoryName;
  final String? assignedInstructorId;
  final String? assignedInstructorName;
  final String? notes;

  String get fullName => '$firstName $lastName';
}
