import '../../../../core/api/result.dart';
import '../entities/candidate_portal.dart';

abstract interface class PortalRepository {
  FutureEither<CandidatePortal> load({
    required String schoolId,
    required String accessToken,
  });
  FutureEither<void> requestLesson({
    required String schoolId,
    required String accessToken,
    required DateTime startAt,
    String? notes,
  });
}
