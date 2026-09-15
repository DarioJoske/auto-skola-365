class InstructorLessonFilters {
  const InstructorLessonFilters({
    required this.from,
    required this.to,
    this.status,
  });

  final DateTime from;
  final DateTime to;
  final String? status;

  InstructorLessonFilters copyWith({
    DateTime? from,
    DateTime? to,
    String? status,
    bool clearStatus = false,
  }) {
    return InstructorLessonFilters(
      from: from ?? this.from,
      to: to ?? this.to,
      status: clearStatus ? null : status ?? this.status,
    );
  }
}
