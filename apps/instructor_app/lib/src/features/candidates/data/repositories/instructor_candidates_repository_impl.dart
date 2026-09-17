import 'package:dartz/dartz.dart';

import '../../../../core/api/failure.dart';
import '../../../../core/api/result.dart';
import '../../domain/entities/instructor_candidate.dart';
import '../../domain/entities/instructor_candidate_filters.dart';
import '../../domain/repositories/instructor_candidates_repository.dart';
import '../datasources/instructor_candidates_remote_data_source.dart';

class InstructorCandidatesRepositoryImpl
    implements InstructorCandidatesRepository {
  const InstructorCandidatesRepositoryImpl(this._remoteDataSource);

  final InstructorCandidatesRemoteDataSource _remoteDataSource;

  @override
  FutureEither<List<InstructorCandidate>> list({
    required String schoolId,
    required String accessToken,
    required InstructorCandidateFilters filters,
  }) async {
    try {
      final candidates = await _remoteDataSource.list(
        schoolId: schoolId,
        accessToken: accessToken,
        filters: filters,
      );
      return Right(
        candidates.map((candidate) => candidate.toEntity()).toList(),
      );
    } catch (error) {
      return Left(Failure.fromException(error));
    }
  }
}
