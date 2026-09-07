class CandidateFilters {
  const CandidateFilters({
    this.query,
    this.status,
    this.categoryCode,
    this.assignedInstructorId,
    this.withoutInstructor = false,
  });

  final String? query;
  final String? status;
  final String? categoryCode;
  final String? assignedInstructorId;
  final bool withoutInstructor;

  bool get isActive =>
      _hasValue(query) ||
      _hasValue(status) ||
      _hasValue(categoryCode) ||
      _hasValue(assignedInstructorId) ||
      withoutInstructor;

  CandidateFilters copyWith({
    String? query,
    String? status,
    String? categoryCode,
    String? assignedInstructorId,
    bool? withoutInstructor,
  }) {
    return CandidateFilters(
      query: query ?? this.query,
      status: status ?? this.status,
      categoryCode: categoryCode ?? this.categoryCode,
      assignedInstructorId: assignedInstructorId ?? this.assignedInstructorId,
      withoutInstructor: withoutInstructor ?? this.withoutInstructor,
    );
  }

  CandidateFilters clear() {
    return const CandidateFilters();
  }

  bool _hasValue(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}
