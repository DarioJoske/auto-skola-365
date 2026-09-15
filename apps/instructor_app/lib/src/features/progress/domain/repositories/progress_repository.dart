import '../../../../core/api/result.dart';
import '../entities/candidate_progress.dart';

abstract interface class ProgressRepository {
  FutureEither<CandidateProgress> load({
    required String schoolId,
    required String accessToken,
    required String resource,
    required String id,
  });
  FutureEither<CandidateProgress> save({
    required String schoolId,
    required String accessToken,
    required String lessonId,
    required Map<String, String> assessments,
  });
}
