import '../../../../core/api/result.dart';
import '../entities/candidate.dart';
import '../entities/candidate_filters.dart';
import '../entities/create_candidate.dart';
import '../entities/update_candidate.dart';

abstract interface class CandidatesRepository {
  FutureResult<List<Candidate>> list({
    required String schoolId,
    required String accessToken,
    CandidateFilters filters,
  });

  FutureResult<Candidate> create({
    required String schoolId,
    required String accessToken,
    required CreateCandidate candidate,
  });

  FutureResult<Candidate> update({
    required String schoolId,
    required String accessToken,
    required String candidateId,
    required UpdateCandidate candidate,
  });
}
