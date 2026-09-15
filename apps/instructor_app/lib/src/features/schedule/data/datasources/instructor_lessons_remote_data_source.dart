import '../../../../core/api/api_client.dart';
import '../../domain/entities/instructor_lesson_filters.dart';
import '../models/instructor_lesson_model.dart';

class InstructorLessonsRemoteDataSource {
  const InstructorLessonsRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<List<InstructorLessonModel>> list({
    required String schoolId,
    required String accessToken,
    required InstructorLessonFilters filters,
  }) async {
    final json =
        await _apiClient.getJson(
              '/api/schools/$schoolId/lessons/instructor',
              accessToken: accessToken,
              queryParameters: {
                'from': filters.from.toUtc().toIso8601String(),
                'to': filters.to.toUtc().toIso8601String(),
                if (_hasValue(filters.status)) 'status': filters.status,
              },
            )
            as List<dynamic>;

    return json
        .map(
          (item) =>
              InstructorLessonModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<InstructorLessonModel> get({
    required String schoolId,
    required String accessToken,
    required String lessonId,
  }) async {
    final json =
        await _apiClient.getJson(
              '/api/schools/$schoolId/lessons/instructor/$lessonId',
              accessToken: accessToken,
            )
            as Map<String, dynamic>;

    return InstructorLessonModel.fromJson(json);
  }

  Future<InstructorLessonModel> confirm({
    required String schoolId,
    required String accessToken,
    required String lessonId,
  }) {
    return _runLessonAction(
      schoolId: schoolId,
      accessToken: accessToken,
      lessonId: lessonId,
      action: 'confirm',
    );
  }

  Future<InstructorLessonModel> complete({
    required String schoolId,
    required String accessToken,
    required String lessonId,
    String? note,
  }) => _runLessonAction(
    schoolId: schoolId,
    accessToken: accessToken,
    lessonId: lessonId,
    action: 'complete',
    body: {'note': note},
  );

  Future<InstructorLessonModel> cancel({
    required String schoolId,
    required String accessToken,
    required String lessonId,
  }) {
    return _runLessonAction(
      schoolId: schoolId,
      accessToken: accessToken,
      lessonId: lessonId,
      action: 'cancel',
    );
  }

  Future<InstructorLessonModel> _runLessonAction({
    required String schoolId,
    required String accessToken,
    required String lessonId,
    required String action,
    Map<String, dynamic> body = const {},
  }) async {
    final json =
        await _apiClient.postJson(
              '/api/schools/$schoolId/lessons/$lessonId/$action',
              accessToken: accessToken,
              body: body,
            )
            as Map<String, dynamic>;

    return InstructorLessonModel.fromJson(json);
  }

  bool _hasValue(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}
