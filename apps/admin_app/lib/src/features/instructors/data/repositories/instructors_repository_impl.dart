import '../../../../core/api/failure.dart';
import '../../../../core/api/result.dart';
import '../../domain/entities/instructor.dart';
import '../../domain/entities/instructor_filters.dart';
import '../../domain/entities/save_instructor.dart';
import '../../domain/repositories/instructors_repository.dart';
import '../datasources/instructors_remote_data_source.dart';
import '../models/save_instructor_model.dart';

class InstructorsRepositoryImpl implements InstructorsRepository {
  const InstructorsRepositoryImpl(this._remoteDataSource);

  final InstructorsRemoteDataSource _remoteDataSource;

  @override
  FutureResult<List<Instructor>> list({
    required String schoolId,
    required String accessToken,
    InstructorFilters filters = const InstructorFilters(),
  }) async {
    try {
      final instructors = await _remoteDataSource.list(
        schoolId: schoolId,
        accessToken: accessToken,
        filters: filters,
      );
      return success(
        instructors.map((instructor) => instructor.toEntity()).toList(),
      );
    } catch (error) {
      return failure(Failure.fromException(error));
    }
  }

  @override
  FutureResult<Instructor> create({
    required String schoolId,
    required String accessToken,
    required SaveInstructor instructor,
  }) async {
    try {
      final created = await _remoteDataSource.create(
        schoolId: schoolId,
        accessToken: accessToken,
        instructor: SaveInstructorModel.fromEntity(instructor),
      );
      return success(created.toEntity());
    } catch (error) {
      return failure(Failure.fromException(error));
    }
  }

  @override
  FutureResult<Instructor> update({
    required String schoolId,
    required String accessToken,
    required String instructorId,
    required SaveInstructor instructor,
  }) async {
    try {
      final updated = await _remoteDataSource.update(
        schoolId: schoolId,
        accessToken: accessToken,
        instructorId: instructorId,
        instructor: SaveInstructorModel.fromEntity(instructor),
      );
      return success(updated.toEntity());
    } catch (error) {
      return failure(Failure.fromException(error));
    }
  }
}
