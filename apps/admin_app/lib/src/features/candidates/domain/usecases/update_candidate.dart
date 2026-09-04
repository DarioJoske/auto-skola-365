import '../../../../core/api/result.dart';
import '../entities/candidate.dart';
import '../entities/update_candidate.dart';
import '../repositories/candidates_repository.dart';

class UpdateCandidateUseCase {
  const UpdateCandidateUseCase(this._repository);

  final CandidatesRepository _repository;

  FutureResult<Candidate> call({
    required String schoolId,
    required String accessToken,
    required String candidateId,
    required UpdateCandidate candidate,
  }) {
    return _repository.update(
      schoolId: schoolId,
      accessToken: accessToken,
      candidateId: candidateId,
      candidate: candidate,
    );
  }
}
