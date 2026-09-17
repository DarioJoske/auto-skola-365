import '../../domain/entities/reserve_lesson.dart';
import '../models/reserve_lesson_model.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/api/failure.dart';
import '../../../../core/api/result.dart';
import '../../domain/entities/instructor_lesson.dart';
import '../../domain/entities/instructor_lesson_filters.dart';
import '../../domain/repositories/instructor_lessons_repository.dart';
import '../datasources/instructor_lessons_remote_data_source.dart';
import '../models/instructor_lesson_model.dart';

class InstructorLessonsRepositoryImpl implements InstructorLessonsRepository {
  const InstructorLessonsRepositoryImpl(this._remoteDataSource);

  final InstructorLessonsRemoteDataSource _remoteDataSource;

  @override
  FutureEither<InstructorLesson> reserve({
    required String schoolId,
    required String accessToken,
    required ReserveLesson reservation,
  }) => _runLessonAction(
    action: () => _remoteDataSource.reserve(
      schoolId: schoolId,
      accessToken: accessToken,
      reservation: ReserveLessonModel(reservation),
    ),
  );

  @override
  FutureEither<List<InstructorLesson>> list({
    required String schoolId,
    required String accessToken,
    required InstructorLessonFilters filters,
  }) async {
    try {
      final lessons = await _remoteDataSource.list(
        schoolId: schoolId,
        accessToken: accessToken,
        filters: filters,
      );
      return Right(lessons.map((lesson) => lesson.toEntity()).toList());
    } catch (error) {
      return Left(Failure.fromException(error));
    }
  }

  @override
  FutureEither<InstructorLesson> get({
    required String schoolId,
    required String accessToken,
    required String lessonId,
  }) {
    return _runLessonAction(
      action: () => _remoteDataSource.get(
        schoolId: schoolId,
        accessToken: accessToken,
        lessonId: lessonId,
      ),
    );
  }

  @override
  FutureEither<InstructorLesson> complete({
    required String schoolId,
    required String accessToken,
    required String lessonId,
    String? note,
  }) {
    return _runLessonAction(
      action: () => _remoteDataSource.complete(
        schoolId: schoolId,
        accessToken: accessToken,
        lessonId: lessonId,
        note: note,
      ),
    );
  }

  @override
  FutureEither<InstructorLesson> confirm({
    required String schoolId,
    required String accessToken,
    required String lessonId,
  }) {
    return _runLessonAction(
      action: () => _remoteDataSource.confirm(
        schoolId: schoolId,
        accessToken: accessToken,
        lessonId: lessonId,
      ),
    );
  }

  @override
  FutureEither<InstructorLesson> cancel({
    required String schoolId,
    required String accessToken,
    required String lessonId,
  }) {
    return _runLessonAction(
      action: () => _remoteDataSource.cancel(
        schoolId: schoolId,
        accessToken: accessToken,
        lessonId: lessonId,
      ),
    );
  }

  FutureEither<InstructorLesson> _runLessonAction({
    required Future<InstructorLessonModel> Function() action,
  }) async {
    try {
      final lesson = await action();
      return Right(lesson.toEntity());
    } catch (error) {
      return Left(Failure.fromException(error));
    }
  }
}
