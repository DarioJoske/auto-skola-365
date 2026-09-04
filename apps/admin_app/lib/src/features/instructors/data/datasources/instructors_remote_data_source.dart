import '../../../../core/api/api_client.dart';
import '../../domain/entities/instructor_filters.dart';
import '../models/instructor_model.dart';
import '../models/save_instructor_model.dart';

class InstructorsRemoteDataSource {
  const InstructorsRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<List<InstructorModel>> list({
    required String schoolId,
    required String accessToken,
    required InstructorFilters filters,
  }) async {
    final json =
        await _apiClient.getJson(
              '/api/schools/$schoolId/instructors',
              accessToken: accessToken,
              queryParameters: {
                if (filters.active != null) 'active': filters.active,
                if (_hasValue(filters.categoryCode))
                  'categoryCode': filters.categoryCode,
              },
            )
            as List<dynamic>;

    return json
        .map((item) => InstructorModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<InstructorModel> create({
    required String schoolId,
    required String accessToken,
    required SaveInstructorModel instructor,
  }) async {
    final json =
        await _apiClient.postJson(
              '/api/schools/$schoolId/instructors',
              accessToken: accessToken,
              body: instructor.toJson(),
            )
            as Map<String, dynamic>;

    return InstructorModel.fromJson(json);
  }

  Future<InstructorModel> update({
    required String schoolId,
    required String accessToken,
    required String instructorId,
    required SaveInstructorModel instructor,
  }) async {
    final json =
        await _apiClient.putJson(
              '/api/schools/$schoolId/instructors/$instructorId',
              accessToken: accessToken,
              body: instructor.toJson(),
            )
            as Map<String, dynamic>;

    return InstructorModel.fromJson(json);
  }

  bool _hasValue(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}
