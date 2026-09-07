class LessonFilters {
  const LessonFilters({
    required this.from,
    required this.to,
    this.instructorId,
    this.candidateId,
    this.status,
  });

  final DateTime from;
  final DateTime to;
  final String? instructorId;
  final String? candidateId;
  final String? status;

  LessonFilters copyWith({
    DateTime? from,
    DateTime? to,
    String? instructorId,
    String? candidateId,
    String? status,
    bool clearInstructor = false,
    bool clearCandidate = false,
    bool clearStatus = false,
  }) {
    return LessonFilters(
      from: from ?? this.from,
      to: to ?? this.to,
      instructorId: clearInstructor ? null : instructorId ?? this.instructorId,
      candidateId: clearCandidate ? null : candidateId ?? this.candidateId,
      status: clearStatus ? null : status ?? this.status,
    );
  }
}
