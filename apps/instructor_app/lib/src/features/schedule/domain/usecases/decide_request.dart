import '../../../../core/api/result.dart';
import '../entities/instructor_lesson.dart';
import '../repositories/request_decisions_repository.dart';
export '../repositories/request_decisions_repository.dart' show RequestDecision;

final class DecideRequest {
  const DecideRequest(this._repository);
  final RequestDecisionsRepository _repository;
  FutureEither<InstructorLesson> call({
    required String schoolId,
    required String accessToken,
    required String lessonId,
    required RequestDecision decision,
    DateTime? startAt,
  }) => _repository.decide(
    schoolId: schoolId,
    accessToken: accessToken,
    lessonId: lessonId,
    decision: decision,
    startAt: startAt,
  );
}
