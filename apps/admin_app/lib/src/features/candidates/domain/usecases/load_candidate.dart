import '../../../../core/api/result.dart';
import '../entities/candidate.dart';
import '../repositories/candidates_repository.dart';

class LoadCandidate {
  const LoadCandidate(this._repository);

  final CandidatesRepository _repository;

  FutureResult<Candidate> call({
    required String schoolId,
    required String accessToken,
    required String candidateId,
  }) {
    return _repository.get(
      schoolId: schoolId,
      accessToken: accessToken,
      candidateId: candidateId,
    );
  }
}
