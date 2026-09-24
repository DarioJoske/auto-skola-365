import '../../../../core/api/result.dart';
import '../entities/instructor_candidate.dart';
import '../entities/instructor_candidate_filters.dart';

abstract interface class InstructorCandidatesRepository {
  FutureEither<InstructorCandidate> get({
    required String schoolId,
    required String accessToken,
    required String candidateId,
  });

  FutureEither<List<InstructorCandidate>> list({
    required String schoolId,
    required String accessToken,
    required InstructorCandidateFilters filters,
  });
}
