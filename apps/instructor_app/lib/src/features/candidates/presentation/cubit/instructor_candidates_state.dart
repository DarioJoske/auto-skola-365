import '../../domain/entities/instructor_candidate.dart';
import '../../domain/entities/instructor_candidate_filters.dart';

enum InstructorCandidatesStatus { initial, loading, loaded, failure }

class InstructorCandidatesState {
  const InstructorCandidatesState({
    required this.status,
    required this.filters,
    this.candidates = const [],
    this.errorMessage,
    this.errorStatusCode,
    this.errorEventId = 0,
  });

  factory InstructorCandidatesState.initial() {
    return const InstructorCandidatesState(
      status: InstructorCandidatesStatus.initial,
      filters: InstructorCandidateFilters(),
    );
  }

  final InstructorCandidatesStatus status;
  final InstructorCandidateFilters filters;
  final List<InstructorCandidate> candidates;
  final String? errorMessage;
  final int? errorStatusCode;
  final int errorEventId;

  bool get isLoading =>
      status == InstructorCandidatesStatus.initial ||
      status == InstructorCandidatesStatus.loading;

  InstructorCandidatesState copyWith({
    InstructorCandidatesStatus? status,
    InstructorCandidateFilters? filters,
    List<InstructorCandidate>? candidates,
    String? errorMessage,
    int? errorStatusCode,
    int? errorEventId,
  }) {
    return InstructorCandidatesState(
      status: status ?? this.status,
      filters: filters ?? this.filters,
      candidates: candidates ?? this.candidates,
      errorMessage: errorMessage,
      errorStatusCode: errorStatusCode,
      errorEventId: errorEventId ?? this.errorEventId,
    );
  }
}
