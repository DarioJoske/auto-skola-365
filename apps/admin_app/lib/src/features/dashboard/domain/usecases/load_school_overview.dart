import '../../../../core/api/result.dart';
import '../entities/school_overview.dart';
import '../repositories/school_overview_repository.dart';

final class LoadSchoolOverview {
  const LoadSchoolOverview(this._repository);
  final SchoolOverviewRepository _repository;
  FutureResult<SchoolOverview> call({
    required String schoolId,
    required String accessToken,
  }) => _repository.load(schoolId: schoolId, accessToken: accessToken);
}
