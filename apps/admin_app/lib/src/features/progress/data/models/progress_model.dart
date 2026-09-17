import '../../domain/entities/candidate_progress.dart';

final class ProgressModel {
  const ProgressModel({
    required this.candidateId,
    required this.candidateName,
    required this.categoryCode,
    required this.completedDrivingHours,
    required this.requiredDrivingHours,
  });

  factory ProgressModel.fromJson(Map<String, dynamic> json) => ProgressModel(
    candidateId: json['candidateId'] as String,
    candidateName: json['candidateName'] as String,
    categoryCode: json['categoryCode'] as String,
    completedDrivingHours: json['completedDrivingHours'] as int,
    requiredDrivingHours: json['requiredDrivingHours'] as int?,
  );

  final String candidateId;
  final String candidateName;
  final String categoryCode;
  final int completedDrivingHours;
  final int? requiredDrivingHours;

  Map<String, dynamic> toJson() => {
    'candidateId': candidateId,
    'candidateName': candidateName,
    'categoryCode': categoryCode,
    'completedDrivingHours': completedDrivingHours,
    'requiredDrivingHours': requiredDrivingHours,
  };

  CandidateProgress toEntity() => CandidateProgress(
    candidateId: candidateId,
    candidateName: candidateName,
    categoryCode: categoryCode,
    completedDrivingHours: completedDrivingHours,
    requiredDrivingHours: requiredDrivingHours,
  );
}
