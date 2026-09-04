import '../../domain/entities/create_candidate.dart';

class CreateCandidateModel {
  const CreateCandidateModel({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.oib,
    required this.status,
    required this.categoryCode,
    required this.notes,
  });

  factory CreateCandidateModel.fromEntity(CreateCandidate candidate) {
    return CreateCandidateModel(
      firstName: candidate.firstName,
      lastName: candidate.lastName,
      email: candidate.email,
      phone: candidate.phone,
      oib: candidate.oib,
      status: candidate.status,
      categoryCode: candidate.categoryCode,
      notes: candidate.notes,
    );
  }

  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final String? oib;
  final String status;
  final String categoryCode;
  final String? notes;

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'oib': oib,
      'status': status,
      'categoryCode': categoryCode,
      'notes': notes,
    };
  }
}
