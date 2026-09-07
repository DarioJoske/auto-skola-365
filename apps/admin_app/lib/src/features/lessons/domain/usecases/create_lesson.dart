import '../../../../core/api/result.dart';
import '../entities/lesson.dart';
import '../entities/save_lesson.dart';
import '../repositories/lessons_repository.dart';

class CreateLessonUseCase {
  const CreateLessonUseCase(this._repository);

  final LessonsRepository _repository;

  FutureResult<Lesson> call({
    required String schoolId,
    required String accessToken,
    required SaveLesson lesson,
  }) {
    return _repository.create(
      schoolId: schoolId,
      accessToken: accessToken,
      lesson: lesson,
    );
  }
}
