import '../../../../core/api/result.dart';
import '../entities/instructor_candidate.dart';
import '../repositories/instructor_candidates_repository.dart';

final class GetInstructorCandidate {
  const GetInstructorCandidate(this._repository);
  final InstructorCandidatesRepository _repository;
  FutureEither<InstructorCandidate> call({
    required String schoolId,
    required String accessToken,
    required String candidateId,
  }) => _repository.get(
    schoolId: schoolId,
    accessToken: accessToken,
    candidateId: candidateId,
  );
}
