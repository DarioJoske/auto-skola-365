class CreateCandidate {
  const CreateCandidate({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.oib,
    required this.status,
    required this.categoryCode,
    required this.assignedInstructorId,
    required this.notes,
    this.requiredDrivingHours,
    this.loginPassword,
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
  final int? requiredDrivingHours;
  final String? loginPassword;
}
