import '../../../../core/api/api_client.dart';
import '../models/progress_model.dart';

class ProgressRemoteDataSource {
  const ProgressRemoteDataSource(this._api);
  final ApiClient _api;
  Future<ProgressModel> load({
    required String schoolId,
    required String accessToken,
    required String resource,
    required String id,
  }) async => ProgressModel.fromJson(
    await _api.getJson(
          '/api/schools/$schoolId/$resource/$id/progress',
          accessToken: accessToken,
        )
        as Map<String, dynamic>,
  );
}
