import 'package:dartz/dartz.dart';
import '../../../../core/api/result.dart';
import '../../../../core/api/failure.dart';
import '../../domain/entities/instructor_lesson.dart';
import '../../domain/repositories/request_decisions_repository.dart';
import '../datasources/instructor_lessons_remote_data_source.dart';

final class RequestDecisionsRepositoryImpl
    implements RequestDecisionsRepository {
  const RequestDecisionsRepositoryImpl(this._remote);
  final InstructorLessonsRemoteDataSource _remote;
  @override
  FutureEither<InstructorLesson> decide({
    required String schoolId,
    required String accessToken,
    required String lessonId,
    required RequestDecision decision,
    DateTime? startAt,
  }) async {
    try {
      return Right(
        (await _remote.decide(
          schoolId: schoolId,
          accessToken: accessToken,
          lessonId: lessonId,
          decision: decision.name,
          startAt: startAt,
        )).toEntity(),
      );
    } catch (error) {
      return Left(Failure.fromException(error));
    }
  }
}
