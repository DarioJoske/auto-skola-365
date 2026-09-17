import 'package:dartz/dartz.dart';
import '../../../../core/api/failure.dart';
import '../../../../core/api/result.dart';
import '../../domain/entities/candidate_portal.dart';
import '../../domain/repositories/portal_repository.dart';
import '../datasources/portal_remote_data_source.dart';

final class PortalRepositoryImpl implements PortalRepository {
  const PortalRepositoryImpl(this._remote);
  final PortalRemoteDataSource _remote;
  @override
  FutureEither<CandidatePortal> load({
    required String schoolId,
    required String accessToken,
  }) async {
    try {
      return Right(
        (await _remote.load(
          schoolId: schoolId,
          accessToken: accessToken,
        )).toEntity(),
      );
    } catch (error) {
      return Left(Failure.fromException(error));
    }
  }

  @override
  FutureEither<void> requestLesson({
    required String schoolId,
    required String accessToken,
    required DateTime startAt,
    String? notes,
  }) async {
    try {
      await _remote.requestLesson(
        schoolId: schoolId,
        accessToken: accessToken,
        startAt: startAt,
        notes: notes,
      );
      return const Right(null);
    } catch (error) {
      return Left(Failure.fromException(error));
    }
  }
}
