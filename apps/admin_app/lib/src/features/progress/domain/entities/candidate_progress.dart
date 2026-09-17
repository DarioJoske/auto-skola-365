final class CandidateProgress {
  const CandidateProgress({
    required this.candidateId,
    required this.candidateName,
    required this.categoryCode,
    required this.completedDrivingHours,
    required this.requiredDrivingHours,
  });

  final String candidateId;
  final String candidateName;
  final String categoryCode;
  final int completedDrivingHours;
  final int? requiredDrivingHours;
}
