import '../../../../core/api/result.dart';
import '../entities/lesson.dart';
import '../entities/lesson_filters.dart';
import '../entities/save_lesson.dart';

abstract interface class LessonsRepository {
  FutureResult<List<Lesson>> list({
    required String schoolId,
    required String accessToken,
    required LessonFilters filters,
  });

  FutureResult<Lesson> create({
    required String schoolId,
    required String accessToken,
    required SaveLesson lesson,
  });

  FutureResult<Lesson> update({
    required String schoolId,
    required String accessToken,
    required String lessonId,
    required SaveLesson lesson,
  });

  FutureResult<Lesson> confirm({
    required String schoolId,
    required String accessToken,
    required String lessonId,
  });

  FutureResult<Lesson> cancel({
    required String schoolId,
    required String accessToken,
    required String lessonId,
  });
}
