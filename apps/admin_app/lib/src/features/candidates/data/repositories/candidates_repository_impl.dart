import '../../../../core/api/failure.dart';
import '../../../../core/api/result.dart';
import '../../domain/entities/candidate.dart';
import '../../domain/entities/candidate_filters.dart';
import '../../domain/entities/create_candidate.dart';
import '../../domain/entities/update_candidate.dart';
import '../../domain/repositories/candidates_repository.dart';
import '../datasources/candidates_remote_data_source.dart';
import '../models/create_candidate_model.dart';
import '../models/update_candidate_model.dart';

class CandidatesRepositoryImpl implements CandidatesRepository {
  const CandidatesRepositoryImpl(this._remoteDataSource);

  final CandidatesRemoteDataSource _remoteDataSource;

  @override
  FutureResult<Candidate> get({
    required String schoolId,
    required String accessToken,
    required String candidateId,
  }) async {
    try {
      final candidate = await _remoteDataSource.get(
        schoolId: schoolId,
        accessToken: accessToken,
        candidateId: candidateId,
      );
      return success(candidate.toEntity());
    } catch (error) {
      return failure(Failure.fromException(error));
    }
  }

  @override
  FutureResult<List<Candidate>> list({
    required String schoolId,
    required String accessToken,
    CandidateFilters filters = const CandidateFilters(),
  }) async {
    try {
      final candidates = await _remoteDataSource.list(
        schoolId: schoolId,
        accessToken: accessToken,
        filters: filters,
      );
      return success(
        candidates.map((candidate) => candidate.toEntity()).toList(),
      );
    } catch (error) {
      return failure(Failure.fromException(error));
    }
  }

  @override
  FutureResult<Candidate> create({
    required String schoolId,
    required String accessToken,
    required CreateCandidate candidate,
  }) async {
    try {
      final created = await _remoteDataSource.create(
        schoolId: schoolId,
        accessToken: accessToken,
        candidate: CreateCandidateModel.fromEntity(candidate),
      );
      return success(created.toEntity());
    } catch (error) {
      return failure(Failure.fromException(error));
    }
  }

  @override
  FutureResult<Candidate> update({
    required String schoolId,
    required String accessToken,
    required String candidateId,
    required UpdateCandidate candidate,
  }) async {
    try {
      final updated = await _remoteDataSource.update(
        schoolId: schoolId,
        accessToken: accessToken,
        candidateId: candidateId,
        candidate: UpdateCandidateModel.fromEntity(candidate),
      );
      return success(updated.toEntity());
    } catch (error) {
      return failure(Failure.fromException(error));
    }
  }
}
