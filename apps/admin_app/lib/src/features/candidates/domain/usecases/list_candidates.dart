import '../../../../core/api/result.dart';
import '../entities/candidate.dart';
import '../entities/candidate_filters.dart';
import '../repositories/candidates_repository.dart';

class ListCandidates {
  const ListCandidates(this._repository);

  final CandidatesRepository _repository;

  FutureResult<List<Candidate>> call({
    required String schoolId,
    required String accessToken,
    CandidateFilters filters = const CandidateFilters(),
  }) {
    return _repository.list(
      schoolId: schoolId,
      accessToken: accessToken,
      filters: filters,
    );
  }
}
