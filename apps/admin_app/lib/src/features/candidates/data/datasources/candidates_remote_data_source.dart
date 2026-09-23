import '../../../../core/api/api_client.dart';
import '../../domain/entities/candidate_filters.dart';
import '../models/candidate_model.dart';
import '../models/create_candidate_model.dart';
import '../models/update_candidate_model.dart';

class CandidatesRemoteDataSource {
  const CandidatesRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<CandidateModel> get({
    required String schoolId,
    required String accessToken,
    required String candidateId,
  }) async {
    final json =
        await _apiClient.getJson(
              '/api/schools/$schoolId/candidates/$candidateId',
              accessToken: accessToken,
            )
            as Map<String, dynamic>;
    return CandidateModel.fromJson(json);
  }

  Future<List<CandidateModel>> list({
    required String schoolId,
    required String accessToken,
    required CandidateFilters filters,
  }) async {
    final json =
        await _apiClient.getJson(
              '/api/schools/$schoolId/candidates',
              accessToken: accessToken,
              queryParameters: {
                if (_hasValue(filters.status)) 'status': filters.status,
                if (_hasValue(filters.categoryCode))
                  'categoryCode': filters.categoryCode,
                if (_hasValue(filters.assignedInstructorId))
                  'assignedInstructorId': filters.assignedInstructorId,
                if (filters.withoutInstructor) 'withoutInstructor': true,
                if (_hasValue(filters.query)) 'q': filters.query,
              },
            )
            as List<dynamic>;

    return json
        .map((item) => CandidateModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<CandidateModel> create({
    required String schoolId,
    required String accessToken,
    required CreateCandidateModel candidate,
  }) async {
    final json =
        await _apiClient.postJson(
              '/api/schools/$schoolId/candidates',
              accessToken: accessToken,
              body: candidate.toJson(),
            )
            as Map<String, dynamic>;

    return CandidateModel.fromJson(json);
  }

  Future<CandidateModel> update({
    required String schoolId,
    required String accessToken,
    required String candidateId,
    required UpdateCandidateModel candidate,
  }) async {
    final json =
        await _apiClient.putJson(
              '/api/schools/$schoolId/candidates/$candidateId',
              accessToken: accessToken,
              body: candidate.toJson(),
            )
            as Map<String, dynamic>;

    return CandidateModel.fromJson(json);
  }

  bool _hasValue(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}
