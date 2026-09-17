import '../../../../core/api/result.dart';
import '../entities/instructor_overview.dart';
import '../repositories/instructor_overview_repository.dart';

final class LoadInstructorOverview {
  const LoadInstructorOverview(this._repository);
  final InstructorOverviewRepository _repository;
  FutureResult<InstructorOverview> call({
    required String schoolId,
    required String accessToken,
    String query = '',
    bool? active,
  }) => _repository.load(
    schoolId: schoolId,
    accessToken: accessToken,
    query: query,
    active: active,
  );
}
