import '../../../../core/api/result.dart';
import '../entities/candidate_progress.dart';

abstract interface class ProgressRepository {
  FutureEither<CandidateProgress> load({
    required String schoolId,
    required String accessToken,
    required String resource,
    required String id,
  });
}
