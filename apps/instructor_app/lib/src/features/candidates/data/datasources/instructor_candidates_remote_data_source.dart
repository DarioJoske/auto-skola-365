import '../../../../core/api/api_client.dart';
import '../../domain/entities/instructor_candidate_filters.dart';
import '../models/instructor_candidate_model.dart';

class InstructorCandidatesRemoteDataSource {
  const InstructorCandidatesRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<List<InstructorCandidateModel>> list({
    required String schoolId,
    required String accessToken,
    required InstructorCandidateFilters filters,
  }) async {
    final json =
        await _apiClient.getJson(
              '/api/schools/$schoolId/candidates/instructor',
              accessToken: accessToken,
              queryParameters: {
                if (_hasValue(filters.query)) 'q': filters.query,
                if (_hasValue(filters.status)) 'status': filters.status,
                if (_hasValue(filters.categoryCode))
                  'categoryCode': filters.categoryCode,
              },
            )
            as List<dynamic>;

    return json
        .map(
          (item) =>
              InstructorCandidateModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  bool _hasValue(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}
