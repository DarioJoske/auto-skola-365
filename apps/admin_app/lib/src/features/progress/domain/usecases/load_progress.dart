import '../../../../core/api/result.dart';
import '../entities/candidate_progress.dart';
import '../repositories/progress_repository.dart';

class LoadProgress {
  const LoadProgress(this._repository);
  final ProgressRepository _repository;
  FutureEither<CandidateProgress> call({
    required String schoolId,
    required String accessToken,
    required String resource,
    required String id,
  }) => _repository.load(
    schoolId: schoolId,
    accessToken: accessToken,
    resource: resource,
    id: id,
  );
}
