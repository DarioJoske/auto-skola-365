class CandidateFilters {
  const CandidateFilters({this.query, this.status, this.categoryCode});

  final String? query;
  final String? status;
  final String? categoryCode;

  bool get isActive =>
      _hasValue(query) || _hasValue(status) || _hasValue(categoryCode);

  CandidateFilters copyWith({
    String? query,
    String? status,
    String? categoryCode,
  }) {
    return CandidateFilters(
      query: query ?? this.query,
      status: status ?? this.status,
      categoryCode: categoryCode ?? this.categoryCode,
    );
  }

  CandidateFilters clear() {
    return const CandidateFilters();
  }

  bool _hasValue(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}
