import '../../../../core/api/result.dart';
import '../entities/instructor_lesson.dart';
import '../repositories/instructor_lessons_repository.dart';

class CompleteInstructorLesson {
  const CompleteInstructorLesson(this._repository);

  final InstructorLessonsRepository _repository;

  FutureEither<InstructorLesson> call({
    required String schoolId,
    required String accessToken,
    required String lessonId,
    String? note,
  }) {
    return _repository.complete(
      schoolId: schoolId,
      accessToken: accessToken,
      lessonId: lessonId,
      note: note,
    );
  }
}
