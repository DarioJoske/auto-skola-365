import '../../../../core/api/api_client.dart';
import '../models/instructor_overview_model.dart';

final class InstructorOverviewRemoteDataSource {
  const InstructorOverviewRemoteDataSource(this._api);
  final ApiClient _api;
  Future<InstructorOverviewModel> load({
    required String schoolId,
    required String accessToken,
    String query = '',
    bool? active,
  }) async {
    final json = await _api.getJson(
      '/api/schools/$schoolId/instructors/overview',
      accessToken: accessToken,
      queryParameters: {'query': query, if (active != null) 'active': active},
    );
    return InstructorOverviewModel.fromJson(json as Map<String, dynamic>);
  }
}
