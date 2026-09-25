import '../../../../core/api/api_client.dart';
import '../models/availability_model.dart';

final class AvailabilityRemoteDataSource {
  const AvailabilityRemoteDataSource(this._api);
  final ApiClient _api;
  Future<AvailabilityModel> load(
    String schoolId,
    String token,
    String instructorId,
  ) async => AvailabilityModel.fromJson(
    await _api.getJson(
          '/api/schools/$schoolId/instructors/$instructorId/availability',
          accessToken: token,
        )
        as Map<String, dynamic>,
  );
  Future<AvailabilityModel> save(
    String schoolId,
    String token,
    String instructorId,
    AvailabilityModel model,
  ) async => AvailabilityModel.fromJson(
    await _api.putJson(
          '/api/schools/$schoolId/instructors/$instructorId/availability',
          accessToken: token,
          body: model.toJson(),
        )
        as Map<String, dynamic>,
  );
}
