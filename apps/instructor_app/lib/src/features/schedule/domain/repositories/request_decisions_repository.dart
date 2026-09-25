import '../../../../core/api/result.dart';
import '../entities/instructor_lesson.dart';

enum RequestDecision { confirm, reject, propose }

abstract interface class RequestDecisionsRepository {
  FutureEither<InstructorLesson> decide({
    required String schoolId,
    required String accessToken,
    required String lessonId,
    required RequestDecision decision,
    DateTime? startAt,
  });
}
