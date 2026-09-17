class InstructorCandidateFilters {
  const InstructorCandidateFilters({
    this.query,
    this.status,
    this.categoryCode,
  });

  final String? query;
  final String? status;
  final String? categoryCode;

  bool get isActive =>
      _hasValue(query) || _hasValue(status) || _hasValue(categoryCode);

  InstructorCandidateFilters copyWith({
    String? query,
    bool clearQuery = false,
    String? status,
    bool clearStatus = false,
    String? categoryCode,
    bool clearCategory = false,
  }) {
    return InstructorCandidateFilters(
      query: clearQuery ? null : query ?? this.query,
      status: clearStatus ? null : status ?? this.status,
      categoryCode: clearCategory ? null : categoryCode ?? this.categoryCode,
    );
  }

  InstructorCandidateFilters clear() {
    return const InstructorCandidateFilters();
  }

  bool _hasValue(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}
