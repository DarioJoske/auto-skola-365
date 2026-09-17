import '../../../../core/api/result.dart';
import '../repositories/portal_repository.dart';

final class RequestLesson {
  const RequestLesson(this._repository);
  final PortalRepository _repository;
  FutureEither<void> call({
    required String schoolId,
    required String accessToken,
    required DateTime startAt,
    String? notes,
  }) => _repository.requestLesson(
    schoolId: schoolId,
    accessToken: accessToken,
    startAt: startAt,
    notes: notes,
  );
}
