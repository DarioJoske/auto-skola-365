import '../../../../core/api/result.dart';
import '../entities/candidate_portal.dart';
import '../repositories/portal_repository.dart';

final class LoadPortal {
  const LoadPortal(this._repository);
  final PortalRepository _repository;
  FutureEither<CandidatePortal> call({
    required String schoolId,
    required String accessToken,
  }) => _repository.load(schoolId: schoolId, accessToken: accessToken);
}
