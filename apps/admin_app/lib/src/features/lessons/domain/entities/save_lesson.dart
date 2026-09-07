class SaveLesson {
  const SaveLesson({
    required this.candidateId,
    required this.instructorId,
    required this.lessonType,
    required this.status,
    required this.startAt,
    required this.endAt,
    required this.notes,
  });

  final String candidateId;
  final String instructorId;
  final String lessonType;
  final String status;
  final DateTime startAt;
  final DateTime endAt;
  final String? notes;
}
