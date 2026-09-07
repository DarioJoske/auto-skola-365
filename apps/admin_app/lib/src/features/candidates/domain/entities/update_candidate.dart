class UpdateCandidate {
  const UpdateCandidate({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.oib,
    required this.status,
    required this.categoryCode,
    required this.assignedInstructorId,
    required this.notes,
  });

  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final String? oib;
  final String status;
  final String categoryCode;
  final String? assignedInstructorId;
  final String? notes;
}
