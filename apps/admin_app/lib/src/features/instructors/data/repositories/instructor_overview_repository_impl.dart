import '../../../../core/api/result.dart';
import '../../../../core/api/failure.dart';
import '../../domain/entities/instructor_overview.dart';
import '../../domain/repositories/instructor_overview_repository.dart';
import '../datasources/instructor_overview_remote_data_source.dart';

final class InstructorOverviewRepositoryImpl
    implements InstructorOverviewRepository {
  const InstructorOverviewRepositoryImpl(this._source);
  final InstructorOverviewRemoteDataSource _source;
  @override
  FutureResult<InstructorOverview> load({
    required String schoolId,
    required String accessToken,
    String query = '',
    bool? active,
  }) async {
    try {
      return success(
        (await _source.load(
          schoolId: schoolId,
          accessToken: accessToken,
          query: query,
          active: active,
        )).entity,
      );
    } catch (error) {
      return failure(Failure.fromException(error));
    }
  }
}
