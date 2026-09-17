import '../../../../core/api/result.dart';
import '../entities/instructor_lesson.dart';
import '../repositories/instructor_lessons_repository.dart';

class CancelInstructorLesson {
  const CancelInstructorLesson(this._repository);

  final InstructorLessonsRepository _repository;

  FutureEither<InstructorLesson> call({
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
