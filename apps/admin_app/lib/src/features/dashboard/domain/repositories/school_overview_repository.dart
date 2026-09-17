import '../../../../core/api/result.dart';
import '../entities/school_overview.dart';

abstract interface class SchoolOverviewRepository {
  FutureResult<SchoolOverview> load({
    required String schoolId,
    required String accessToken,
  });
}
