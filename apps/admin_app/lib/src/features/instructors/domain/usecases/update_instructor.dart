import '../../../../core/api/result.dart';
import '../entities/instructor.dart';
import '../entities/save_instructor.dart';
import '../repositories/instructors_repository.dart';

class UpdateInstructorUseCase {
  const UpdateInstructorUseCase(this._repository);

  final InstructorsRepository _repository;

  FutureResult<Instructor> call({
    required String schoolId,
    required String accessToken,
    required String instructorId,
    required SaveInstructor instructor,
  }) {
    return _repository.update(
      schoolId: schoolId,
      accessToken: accessToken,
      instructorId: instructorId,
      instructor: instructor,
    );
  }
}
