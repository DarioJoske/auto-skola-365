import 'package:dartz/dartz.dart';
import '../../../../core/api/result.dart';
import '../../../../core/api/failure.dart';
import '../../domain/entities/candidate_progress.dart';
import '../../domain/repositories/progress_repository.dart';
import '../datasources/progress_remote_data_source.dart';

class ProgressRepositoryImpl implements ProgressRepository {
  const ProgressRepositoryImpl(this._remote);
  final ProgressRemoteDataSource _remote;
  @override
  FutureEither<CandidateProgress> load({
    required String schoolId,
    required String accessToken,
    required String resource,
    required String id,
  }) async {
    try {
      return Right(
        (await _remote.load(
          schoolId: schoolId,
          accessToken: accessToken,
          resource: resource,
          id: id,
        )).toEntity(),
      );
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  FutureEither<CandidateProgress> save({
    required String schoolId,
    required String accessToken,
    required String lessonId,
    required Map<String, String> assessments,
  }) async {
    try {
      return Right(
        (await _remote.save(
          schoolId: schoolId,
          accessToken: accessToken,
          lessonId: lessonId,
          assessments: assessments,
        )).toEntity(),
      );
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }
}
