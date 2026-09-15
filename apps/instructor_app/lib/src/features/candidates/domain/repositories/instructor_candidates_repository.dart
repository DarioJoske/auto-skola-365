import '../../../../core/api/result.dart';
import '../entities/instructor_candidate.dart';
import '../entities/instructor_candidate_filters.dart';

abstract interface class InstructorCandidatesRepository {
  FutureEither<List<InstructorCandidate>> list({
    required String schoolId,
    required String accessToken,
    required InstructorCandidateFilters filters,
  });
}
