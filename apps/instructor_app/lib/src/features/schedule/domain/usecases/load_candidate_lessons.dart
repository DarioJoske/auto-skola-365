import '../../../../core/api/result.dart';
import '../entities/instructor_lesson.dart';
import '../repositories/instructor_lessons_repository.dart';

final class LoadCandidateLessons {
  const LoadCandidateLessons(this._repository);
  final InstructorLessonsRepository _repository;
  FutureEither<List<InstructorLesson>> call({
    required String schoolId,
    required String accessToken,
    required String candidateId,
  }) => _repository.history(
    schoolId: schoolId,
    accessToken: accessToken,
    candidateId: candidateId,
  );
}
