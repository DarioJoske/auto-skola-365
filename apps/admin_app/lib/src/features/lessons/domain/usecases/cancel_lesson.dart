import '../../../../core/api/result.dart';
import '../entities/lesson.dart';
import '../repositories/lessons_repository.dart';

class CancelLessonUseCase {
  const CancelLessonUseCase(this._repository);

  final LessonsRepository _repository;

  FutureResult<Lesson> call({
    required String schoolId,
    required String accessToken,
    required String lessonId,
  }) {
    return _repository.cancel(
      schoolId: schoolId,
      accessToken: accessToken,
      lessonId: lessonId,
    );
  }
}
