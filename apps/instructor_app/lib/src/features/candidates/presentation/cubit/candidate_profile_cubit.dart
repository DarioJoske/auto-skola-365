import 'package:bloc/bloc.dart';
import '../../../../core/api/failure.dart';
import '../../../../core/api/result_extensions.dart';
import '../../../schedule/domain/entities/instructor_lesson.dart';
import '../../../schedule/domain/usecases/load_candidate_lessons.dart';
import '../../domain/entities/instructor_candidate.dart';
import '../../domain/usecases/get_instructor_candidate.dart';

final class CandidateProfileState {
  CandidateProfileState({
    this.candidate,
    List<InstructorLesson> lessons = const [],
    this.loading = false,
    this.failure,
    this.eventId = 0,
  }) : lessons = List.unmodifiable(lessons);
  final InstructorCandidate? candidate;
  final List<InstructorLesson> lessons;
  final bool loading;
  final Failure? failure;
  final int eventId;
}

class CandidateProfileCubit extends Cubit<CandidateProfileState> {
  CandidateProfileCubit({
    required GetInstructorCandidate getCandidate,
    required LoadCandidateLessons loadLessons,
    required String schoolId,
    required String accessToken,
    required String candidateId,
  }) : _getCandidate = getCandidate,
       _loadLessons = loadLessons,
       _schoolId = schoolId,
       _accessToken = accessToken,
       _candidateId = candidateId,
       super(CandidateProfileState());
  final GetInstructorCandidate _getCandidate;
  final LoadCandidateLessons _loadLessons;
  final String _schoolId, _accessToken, _candidateId;
  int _request = 0;
  Future<void> load() async {
    if (isClosed) return;
    final request = ++_request;
    emit(
      CandidateProfileState(
        candidate: state.candidate,
        lessons: state.lessons,
        loading: true,
        eventId: state.eventId,
      ),
    );
    final result = await _getCandidate(
      schoolId: _schoolId,
      accessToken: _accessToken,
      candidateId: _candidateId,
    );
    if (isClosed || request != _request) return;
    InstructorCandidate? candidate;
    Failure? failure;
    result.resolveWithFailure(
      onFailure: (value) => failure = value,
      onSuccess: (value) => candidate = value,
    );
    if (failure != null) {
      _failed(failure!);
      return;
    }
    final history = await _loadLessons(
      schoolId: _schoolId,
      accessToken: _accessToken,
      candidateId: _candidateId,
    );
    if (isClosed || request != _request) return;
    history.resolveWithFailure(
      onFailure: (value) => _failed(value, candidate: candidate),
      onSuccess: (lessons) => emit(
        CandidateProfileState(
          candidate: candidate,
          lessons: lessons,
          eventId: state.eventId,
        ),
      ),
    );
  }

  void _failed(Failure failure, {InstructorCandidate? candidate}) {
    final denied = [401, 403, 404].contains(failure.statusCode);
    emit(
      CandidateProfileState(
        candidate: denied ? null : candidate ?? state.candidate,
        lessons: denied ? const [] : state.lessons,
        failure: failure,
        eventId: state.eventId + 1,
      ),
    );
  }
}
