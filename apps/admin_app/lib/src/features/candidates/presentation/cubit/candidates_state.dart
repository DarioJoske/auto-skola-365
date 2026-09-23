import '../../domain/entities/candidate.dart';
import '../../domain/entities/candidate_filters.dart';
import '../../../instructors/domain/entities/instructor.dart';

enum CandidatesStatus { initial, loading, loaded, failure }

class CandidatesState {
  const CandidatesState({
    required this.status,
    this.candidates = const [],
    this.instructors = const [],
    this.filters = const CandidateFilters(),
    this.errorMessage,
    this.errorStatusCode,
    this.errorEventId = 0,
    this.isSubmitting = false,
    this.savedCandidate,
    this.saveEventId = 0,
  });

  const CandidatesState.initial() : this(status: CandidatesStatus.initial);

  final CandidatesStatus status;
  final List<Candidate> candidates;
  final List<Instructor> instructors;
  final CandidateFilters filters;
  final String? errorMessage;
  final int? errorStatusCode;
  final int errorEventId;
  final bool isSubmitting;
  final Candidate? savedCandidate;
  final int saveEventId;

  CandidatesState copyWith({
    CandidatesStatus? status,
    List<Candidate>? candidates,
    List<Instructor>? instructors,
    CandidateFilters? filters,
    String? errorMessage,
    int? errorStatusCode,
    int? errorEventId,
    bool? isSubmitting,
    Candidate? savedCandidate,
    int? saveEventId,
  }) {
    return CandidatesState(
      status: status ?? this.status,
      candidates: candidates ?? this.candidates,
      instructors: instructors ?? this.instructors,
      filters: filters ?? this.filters,
      errorMessage: errorMessage,
      errorStatusCode: errorStatusCode,
      errorEventId: errorEventId ?? this.errorEventId,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      savedCandidate: savedCandidate ?? this.savedCandidate,
      saveEventId: saveEventId ?? this.saveEventId,
    );
  }
}
