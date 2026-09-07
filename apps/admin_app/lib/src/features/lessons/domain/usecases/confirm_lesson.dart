import '../../../../core/api/result.dart';
import '../entities/lesson.dart';
import '../repositories/lessons_repository.dart';

class ConfirmLessonUseCase {
  const ConfirmLessonUseCase(this._repository);

  final LessonsRepository _repository;

  FutureResult<Lesson> call({
    required String schoolId,
    required String accessToken,
    required String lessonId,
  }) {
    return _repository.confirm(
      schoolId: schoolId,
      accessToken: accessToken,
      lessonId: lessonId,
    );
  }
}
