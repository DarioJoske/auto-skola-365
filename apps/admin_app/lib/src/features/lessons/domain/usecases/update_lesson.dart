import '../../../../core/api/result.dart';
import '../entities/lesson.dart';
import '../entities/save_lesson.dart';
import '../repositories/lessons_repository.dart';

class UpdateLessonUseCase {
  const UpdateLessonUseCase(this._repository);

  final LessonsRepository _repository;

  FutureResult<Lesson> call({
    required String schoolId,
    required String accessToken,
    required String lessonId,
    required SaveLesson lesson,
  }) {
    return _repository.update(
      schoolId: schoolId,
      accessToken: accessToken,
      lessonId: lessonId,
      lesson: lesson,
    );
  }
}
