import '../../domain/entities/save_lesson.dart';

class SaveLessonModel {
  const SaveLessonModel({
    required this.candidateId,
    required this.instructorId,
    required this.lessonType,
    required this.status,
    required this.startAt,
    required this.endAt,
    required this.notes,
  });

  factory SaveLessonModel.fromEntity(SaveLesson lesson) {
    return SaveLessonModel(
      candidateId: lesson.candidateId,
      instructorId: lesson.instructorId,
      lessonType: lesson.lessonType,
      status: lesson.status,
      startAt: lesson.startAt,
      endAt: lesson.endAt,
      notes: lesson.notes,
    );
  }

  final String candidateId;
  final String instructorId;
  final String lessonType;
  final String status;
  final DateTime startAt;
  final DateTime endAt;
  final String? notes;

  Map<String, dynamic> toJson() {
    return {
      'candidateId': candidateId,
      'instructorId': instructorId,
      'lessonType': lessonType,
      'status': status,
      'startAt': startAt.toUtc().toIso8601String(),
      'endAt': endAt.toUtc().toIso8601String(),
      'notes': notes,
    };
  }
}
