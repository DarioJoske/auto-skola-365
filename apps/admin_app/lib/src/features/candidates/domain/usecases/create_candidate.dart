import '../../../../core/api/result.dart';
import '../entities/candidate.dart';
import '../entities/create_candidate.dart';
import '../repositories/candidates_repository.dart';

class CreateCandidateUseCase {
  const CreateCandidateUseCase(this._repository);

  final CandidatesRepository _repository;

  FutureResult<Candidate> call({
    required String schoolId,
    required String accessToken,
    required CreateCandidate candidate,
  }) {
    return _repository.create(
      schoolId: schoolId,
      accessToken: accessToken,
      candidate: candidate,
    );
  }
}
