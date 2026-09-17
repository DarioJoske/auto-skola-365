import '../../../../core/api/api_client.dart';
import '../models/portal_model.dart';

final class PortalRemoteDataSource {
  const PortalRemoteDataSource(this._api);
  final ApiClient _api;
  Future<PortalModel> load({
    required String schoolId,
    required String accessToken,
  }) async => PortalModel.fromJson(
    await _api.getJson(
          '/api/schools/$schoolId/candidate-portal',
          accessToken: accessToken,
        )
        as Map<String, dynamic>,
  );
  Future<void> requestLesson({
    required String schoolId,
    required String accessToken,
    required DateTime startAt,
    String? notes,
  }) async {
    await _api.postJson(
      '/api/schools/$schoolId/lessons/candidate/reservations',
      accessToken: accessToken,
      body: {'startAt': startAt.toUtc().toIso8601String(), 'notes': notes},
    );
  }
}
