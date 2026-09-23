class Lesson {
  const Lesson({
    required this.id,
    required this.schoolId,
    required this.candidateId,
    required this.candidateName,
    required this.instructorId,
    required this.instructorName,
    required this.categoryCode,
    required this.categoryName,
    required this.branchId,
    required this.branchName,
    required this.lessonType,
    required this.status,
    required this.startAt,
    required this.endAt,
    required this.confirmedAt,
    required this.cancelledAt,
    required this.notes,
    required this.createdByRole,
    this.completionNote,
  });

  final String id;
  final String schoolId;
  final String candidateId;
  final String candidateName;
  final String instructorId;
  final String instructorName;
  final String categoryCode;
  final String categoryName;
  final String? branchId;
  final String? branchName;
  final String lessonType;
  final String status;
  final DateTime startAt;
  final DateTime endAt;
  final DateTime? confirmedAt;
  final DateTime? cancelledAt;
  final String? notes;
  final String createdByRole;
  final String? completionNote;
}
