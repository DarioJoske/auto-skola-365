import '../../domain/entities/candidate.dart';
import '../../domain/entities/candidate_filters.dart';

enum CandidatesStatus { initial, loading, loaded, failure }

class CandidatesState {
  const CandidatesState({
    required this.status,
    this.candidates = const [],
    this.filters = const CandidateFilters(),
    this.errorMessage,
    this.errorStatusCode,
    this.isSubmitting = false,
  });

  const CandidatesState.initial() : this(status: CandidatesStatus.initial);

  final CandidatesStatus status;
  final List<Candidate> candidates;
  final CandidateFilters filters;
  final String? errorMessage;
  final int? errorStatusCode;
  final bool isSubmitting;

  CandidatesState copyWith({
    CandidatesStatus? status,
    List<Candidate>? candidates,
    CandidateFilters? filters,
    String? errorMessage,
    int? errorStatusCode,
    bool? isSubmitting,
  }) {
    return CandidatesState(
      status: status ?? this.status,
      candidates: candidates ?? this.candidates,
      filters: filters ?? this.filters,
      errorMessage: errorMessage,
      errorStatusCode: errorStatusCode,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}
