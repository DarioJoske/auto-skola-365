import '../../../../core/api/api_client.dart';
import '../../domain/entities/lesson_filters.dart';
import '../models/lesson_model.dart';
import '../models/save_lesson_model.dart';

class LessonsRemoteDataSource {
  const LessonsRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<List<LessonModel>> list({
    required String schoolId,
    required String accessToken,
    required LessonFilters filters,
  }) async {
    final json =
        await _apiClient.getJson(
              '/api/schools/$schoolId/lessons',
              accessToken: accessToken,
              queryParameters: {
                'from': filters.from.toUtc().toIso8601String(),
                'to': filters.to.toUtc().toIso8601String(),
                if (_hasValue(filters.instructorId))
                  'instructorId': filters.instructorId,
                if (_hasValue(filters.candidateId))
                  'candidateId': filters.candidateId,
                if (_hasValue(filters.status)) 'status': filters.status,
              },
            )
            as List<dynamic>;

    return json
        .map((item) => LessonModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<LessonModel> create({
    required String schoolId,
    required String accessToken,
    required SaveLessonModel lesson,
  }) async {
    final json =
        await _apiClient.postJson(
              '/api/schools/$schoolId/lessons',
              accessToken: accessToken,
              body: lesson.toJson(),
            )
            as Map<String, dynamic>;

    return LessonModel.fromJson(json);
  }

  Future<LessonModel> update({
    required String schoolId,
    required String accessToken,
    required String lessonId,
    required SaveLessonModel lesson,
  }) async {
    final json =
        await _apiClient.putJson(
              '/api/schools/$schoolId/lessons/$lessonId',
              accessToken: accessToken,
              body: lesson.toJson(),
            )
            as Map<String, dynamic>;

    return LessonModel.fromJson(json);
  }

  Future<LessonModel> confirm({
    required String schoolId,
    required String accessToken,
    required String lessonId,
  }) async {
    final json =
        await _apiClient.postJson(
              '/api/schools/$schoolId/lessons/$lessonId/confirm',
              accessToken: accessToken,
              body: const {},
            )
            as Map<String, dynamic>;

    return LessonModel.fromJson(json);
  }

  Future<LessonModel> cancel({
    required String schoolId,
    required String accessToken,
    required String lessonId,
  }) async {
    final json =
        await _apiClient.postJson(
              '/api/schools/$schoolId/lessons/$lessonId/cancel',
              accessToken: accessToken,
              body: const {},
            )
            as Map<String, dynamic>;

    return LessonModel.fromJson(json);
  }

  bool _hasValue(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}
