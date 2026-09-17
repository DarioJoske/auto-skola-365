import '../../../../core/api/result.dart';
import '../entities/instructor_overview.dart';

abstract interface class InstructorOverviewRepository {
  FutureResult<InstructorOverview> load({
    required String schoolId,
    required String accessToken,
    String query = '',
    bool? active,
  });
}
