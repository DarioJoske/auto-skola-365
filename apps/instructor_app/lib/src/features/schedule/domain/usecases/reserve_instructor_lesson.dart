import '../../../../core/api/result.dart';
import '../entities/instructor_lesson.dart';
import '../entities/reserve_lesson.dart';
import '../repositories/instructor_lessons_repository.dart';

final class ReserveInstructorLesson {
  const ReserveInstructorLesson(this._repository);
  final InstructorLessonsRepository _repository;
  FutureEither<InstructorLesson> call({
    required String schoolId,
    required String accessToken,
    required ReserveLesson reservation,
  }) => _repository.reserve(
    schoolId: schoolId,
    accessToken: accessToken,
    reservation: reservation,
  );
}
