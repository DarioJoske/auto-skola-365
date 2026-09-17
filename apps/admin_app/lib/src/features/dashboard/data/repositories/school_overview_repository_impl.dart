import '../../../../core/api/result.dart';
import '../../../../core/api/failure.dart';
import '../../domain/entities/school_overview.dart';
import '../../domain/repositories/school_overview_repository.dart';
import '../datasources/school_overview_remote_data_source.dart';

final class SchoolOverviewRepositoryImpl implements SchoolOverviewRepository {
  const SchoolOverviewRepositoryImpl(this._source);
  final SchoolOverviewRemoteDataSource _source;
  @override
  FutureResult<SchoolOverview> load({
    required String schoolId,
    required String accessToken,
  }) async {
    try {
      return success(
        (await _source.load(
          schoolId: schoolId,
          accessToken: accessToken,
        )).entity,
      );
    } catch (error) {
      return failure(Failure.fromException(error));
    }
  }
}
