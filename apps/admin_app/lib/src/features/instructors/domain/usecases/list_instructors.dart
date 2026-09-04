import '../../../../core/api/result.dart';
import '../entities/instructor.dart';
import '../entities/instructor_filters.dart';
import '../repositories/instructors_repository.dart';

class ListInstructors {
  const ListInstructors(this._repository);

  final InstructorsRepository _repository;

  FutureResult<List<Instructor>> call({
    required String schoolId,
    required String accessToken,
    InstructorFilters filters = const InstructorFilters(),
  }) {
    return _repository.list(
      schoolId: schoolId,
      accessToken: accessToken,
      filters: filters,
    );
  }
}
