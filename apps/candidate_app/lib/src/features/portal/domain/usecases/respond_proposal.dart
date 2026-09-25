import '../../../../core/api/result.dart';
import '../repositories/portal_repository.dart';

final class RespondProposal {
  const RespondProposal(this._repository);
  final PortalRepository _repository;
  FutureEither<void> call({
    required String schoolId,
    required String accessToken,
    required String lessonId,
    required DateTime startAt,
    required bool accept,
  }) => _repository.respondProposal(
    schoolId: schoolId,
    accessToken: accessToken,
    lessonId: lessonId,
    startAt: startAt,
    accept: accept,
  );
}
