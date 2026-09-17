import '../../../../core/api/api_client.dart';
import '../models/school_overview_model.dart';

final class SchoolOverviewRemoteDataSource {
  const SchoolOverviewRemoteDataSource(this._api);
  final ApiClient _api;
  Future<SchoolOverviewModel> load({
    required String schoolId,
    required String accessToken,
  }) async {
    final json = await _api.getJson(
      '/api/schools/$schoolId/overview',
      accessToken: accessToken,
    );
    return SchoolOverviewModel.fromJson(json as Map<String, dynamic>);
  }
}
