import '../../domain/entities/lesson.dart';

class LessonModel {
  const LessonModel({
    this.proposedStartAt,
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

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      proposedStartAt: _parseOptionalDate(json['proposedStartAt']),
      id: json['id'] as String,
      schoolId: json['schoolId'] as String,
      candidateId: json['candidateId'] as String,
      candidateName: json['candidateName'] as String,
      instructorId: json['instructorId'] as String,
      instructorName: json['instructorName'] as String,
      categoryCode: json['categoryCode'] as String,
      categoryName: json['categoryName'] as String,
      branchId: json['branchId'] as String?,
      branchName: json['branchName'] as String?,
      lessonType: json['lessonType'] as String,
      status: json['status'] as String,
      startAt: DateTime.parse(json['startAt'] as String).toLocal(),
      endAt: DateTime.parse(json['endAt'] as String).toLocal(),
      confirmedAt: _parseOptionalDate(json['confirmedAt']),
      cancelledAt: _parseOptionalDate(json['cancelledAt']),
      notes: json['notes'] as String?,
      createdByRole: json['createdByRole'] as String,
      completionNote: json['completionNote'] as String?,
    );
  }

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
  final DateTime? proposedStartAt;
  final DateTime startAt;
  final DateTime endAt;
  final DateTime? confirmedAt;
  final DateTime? cancelledAt;
  final String? notes;
  final String createdByRole;
  final String? completionNote;

  Lesson toEntity() {
    return Lesson(
      proposedStartAt: proposedStartAt,
      id: id,
      schoolId: schoolId,
      candidateId: candidateId,
      candidateName: candidateName,
      instructorId: instructorId,
      instructorName: instructorName,
      categoryCode: categoryCode,
      categoryName: categoryName,
      branchId: branchId,
      branchName: branchName,
      lessonType: lessonType,
      status: status,
      startAt: startAt,
      endAt: endAt,
      confirmedAt: confirmedAt,
      cancelledAt: cancelledAt,
      notes: notes,
      createdByRole: createdByRole,
      completionNote: completionNote,
    );
  }

  static DateTime? _parseOptionalDate(dynamic value) {
    if (value is! String) {
      return null;
    }

    return DateTime.parse(value).toLocal();
  }
}
