import '../../../../core/api/result.dart';
import '../entities/instructor.dart';
import '../entities/save_instructor.dart';
import '../repositories/instructors_repository.dart';

class CreateInstructorUseCase {
  const CreateInstructorUseCase(this._repository);

  final InstructorsRepository _repository;

  FutureResult<Instructor> call({
    required String schoolId,
    required String accessToken,
    required SaveInstructor instructor,
  }) {
    return _repository.create(
      schoolId: schoolId,
      accessToken: accessToken,
      instructor: instructor,
    );
  }
}
