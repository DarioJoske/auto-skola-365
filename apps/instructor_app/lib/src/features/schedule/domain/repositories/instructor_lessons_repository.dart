import '../entities/reserve_lesson.dart';
import '../../../../core/api/result.dart';
import '../entities/instructor_lesson.dart';
import '../entities/instructor_lesson_filters.dart';

abstract interface class InstructorLessonsRepository {
  FutureEither<List<InstructorLesson>> history({
    required String schoolId,
    required String accessToken,
    required String candidateId,
  });

  FutureEither<InstructorLesson> reserve({
    required String schoolId,
    required String accessToken,
    required ReserveLesson reservation,
  });

  FutureEither<List<InstructorLesson>> list({
    required String schoolId,
    required String accessToken,
    required InstructorLessonFilters filters,
  });

  FutureEither<InstructorLesson> get({
    required String schoolId,
    required String accessToken,
    required String lessonId,
  });

  FutureEither<InstructorLesson> complete({
    required String schoolId,
    required String accessToken,
    required String lessonId,
    String? note,
  });

  FutureEither<InstructorLesson> confirm({
    required String schoolId,
    required String accessToken,
    required String lessonId,
  });

  FutureEither<InstructorLesson> cancel({
    required String schoolId,
    required String accessToken,
    required String lessonId,
  });
}
