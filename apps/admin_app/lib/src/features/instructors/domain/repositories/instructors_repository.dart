import '../../../../core/api/result.dart';
import '../entities/instructor.dart';
import '../entities/instructor_filters.dart';
import '../entities/save_instructor.dart';

abstract interface class InstructorsRepository {
  FutureResult<List<Instructor>> list({
    required String schoolId,
    required String accessToken,
    InstructorFilters filters,
  });

  FutureResult<Instructor> create({
    required String schoolId,
    required String accessToken,
    required SaveInstructor instructor,
  });

  FutureResult<Instructor> update({
    required String schoolId,
    required String accessToken,
    required String instructorId,
    required SaveInstructor instructor,
  });
}
