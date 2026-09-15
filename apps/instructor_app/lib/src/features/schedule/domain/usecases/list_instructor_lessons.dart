import '../../../../core/api/result.dart';
import '../entities/instructor_lesson.dart';
import '../entities/instructor_lesson_filters.dart';
import '../repositories/instructor_lessons_repository.dart';

class ListInstructorLessons {
  const ListInstructorLessons(this._repository);

  final InstructorLessonsRepository _repository;

  FutureEither<List<InstructorLesson>> call({
    required String schoolId,
    required String accessToken,
    required InstructorLessonFilters filters,
  }) {
    return _repository.list(
      schoolId: schoolId,
      accessToken: accessToken,
      filters: filters,
    );
  }
}
