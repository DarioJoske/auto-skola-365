import '../../../../core/api/result.dart';
import '../entities/candidate_progress.dart';
import '../repositories/progress_repository.dart';

class SaveProgress {
  const SaveProgress(this._repository);
  final ProgressRepository _repository;
  FutureEither<CandidateProgress> call({
    required String schoolId,
    required String accessToken,
    required String lessonId,
    required Map<String, String> assessments,
  }) => _repository.save(
    schoolId: schoolId,
    accessToken: accessToken,
    lessonId: lessonId,
    assessments: assessments,
  );
}
