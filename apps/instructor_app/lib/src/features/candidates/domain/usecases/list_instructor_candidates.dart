import '../../../../core/api/result.dart';
import '../entities/instructor_candidate.dart';
import '../entities/instructor_candidate_filters.dart';
import '../repositories/instructor_candidates_repository.dart';

class ListInstructorCandidates {
  const ListInstructorCandidates(this._repository);

  final InstructorCandidatesRepository _repository;

  FutureEither<List<InstructorCandidate>> call({
    required String schoolId,
    required String accessToken,
    required InstructorCandidateFilters filters,
  }) {
    return _repository.list(
      schoolId: schoolId,
      accessToken: accessToken,
      filters: filters,
    );
  }
}
