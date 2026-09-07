import '../../../../core/api/result.dart';
import '../entities/lesson.dart';
import '../entities/lesson_filters.dart';
import '../repositories/lessons_repository.dart';

class ListLessons {
  const ListLessons(this._repository);

  final LessonsRepository _repository;

  FutureResult<List<Lesson>> call({
    required String schoolId,
    required String accessToken,
    required LessonFilters filters,
  }) {
    return _repository.list(
      schoolId: schoolId,
      accessToken: accessToken,
      filters: filters,
    );
  }
}
