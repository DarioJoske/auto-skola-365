import '../../domain/entities/instructor_candidate.dart';

class InstructorCandidateModel {
  const InstructorCandidateModel({
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

  factory InstructorCandidateModel.fromJson(Map<String, dynamic> json) {
    return InstructorCandidateModel(
      completedDrivingHours: (json['completedDrivingHours'] as num).toInt(),
      id: json['id'] as String,
      schoolId: json['schoolId'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      oib: json['oib'] as String?,
      status: json['status'] as String,
      categoryCode: json['categoryCode'] as String,
      categoryName: json['categoryName'] as String,
      assignedInstructorId: json['assignedInstructorId'] as String?,
      assignedInstructorName: json['assignedInstructorName'] as String?,
      notes: json['notes'] as String?,
    );
  }

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

  InstructorCandidate toEntity() {
    return InstructorCandidate(
      completedDrivingHours: completedDrivingHours,
      id: id,
      schoolId: schoolId,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      oib: oib,
      status: status,
      categoryCode: categoryCode,
      categoryName: categoryName,
      assignedInstructorId: assignedInstructorId,
      assignedInstructorName: assignedInstructorName,
      notes: notes,
    );
  }
}
