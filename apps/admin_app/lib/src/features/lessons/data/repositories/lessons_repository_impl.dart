import '../../../../core/api/failure.dart';
import '../../../../core/api/result.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/entities/lesson_filters.dart';
import '../../domain/entities/save_lesson.dart';
import '../../domain/repositories/lessons_repository.dart';
import '../datasources/lessons_remote_data_source.dart';
import '../models/save_lesson_model.dart';

class LessonsRepositoryImpl implements LessonsRepository {
  const LessonsRepositoryImpl(this._remoteDataSource);

  final LessonsRemoteDataSource _remoteDataSource;

  @override
  FutureResult<List<Lesson>> list({
    required String schoolId,
    required String accessToken,
    required LessonFilters filters,
  }) async {
    try {
      final lessons = await _remoteDataSource.list(
        schoolId: schoolId,
        accessToken: accessToken,
        filters: filters,
      );
      return success(lessons.map((lesson) => lesson.toEntity()).toList());
    } catch (error) {
      return failure(Failure.fromException(error));
    }
  }

  @override
  FutureResult<Lesson> create({
    required String schoolId,
    required String accessToken,
    required SaveLesson lesson,
  }) async {
    try {
      final created = await _remoteDataSource.create(
        schoolId: schoolId,
        accessToken: accessToken,
        lesson: SaveLessonModel.fromEntity(lesson),
      );
      return success(created.toEntity());
    } catch (error) {
      return failure(Failure.fromException(error));
    }
  }

  @override
  FutureResult<Lesson> update({
    required String schoolId,
    required String accessToken,
    required String lessonId,
    required SaveLesson lesson,
  }) async {
    try {
      final updated = await _remoteDataSource.update(
        schoolId: schoolId,
        accessToken: accessToken,
        lessonId: lessonId,
        lesson: SaveLessonModel.fromEntity(lesson),
      );
      return success(updated.toEntity());
    } catch (error) {
      return failure(Failure.fromException(error));
    }
  }

  @override
  FutureResult<Lesson> confirm({
    required String schoolId,
    required String accessToken,
    required String lessonId,
  }) async {
    try {
      final confirmed = await _remoteDataSource.confirm(
        schoolId: schoolId,
        accessToken: accessToken,
        lessonId: lessonId,
      );
      return success(confirmed.toEntity());
    } catch (error) {
      return failure(Failure.fromException(error));
    }
  }

  @override
  FutureResult<Lesson> cancel({
    required String schoolId,
    required String accessToken,
    required String lessonId,
  }) async {
    try {
      final cancelled = await _remoteDataSource.cancel(
        schoolId: schoolId,
        accessToken: accessToken,
        lessonId: lessonId,
      );
      return success(cancelled.toEntity());
    } catch (error) {
      return failure(Failure.fromException(error));
    }
  }
}
