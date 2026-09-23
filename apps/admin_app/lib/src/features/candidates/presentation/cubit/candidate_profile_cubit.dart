import 'package:bloc/bloc.dart';
import '../../../../core/api/failure.dart';
import '../../../../core/api/result_extensions.dart';
import '../../../lessons/domain/entities/lesson.dart';
import '../../../lessons/domain/entities/lesson_filters.dart';
import '../../../lessons/domain/usecases/list_lessons.dart';
import '../../domain/entities/candidate.dart';
import '../../domain/usecases/load_candidate.dart';

final class CandidateProfileState {
  CandidateProfileState({
    required this.month,
    this.candidate,
    List<Lesson> lessons = const [],
    this.loading = false,
    this.failure,
    this.eventId = 0,
  }) : lessons = List.unmodifiable(lessons);
  final DateTime month;
  final Candidate? candidate;
  final List<Lesson> lessons;
  final bool loading;
  final Failure? failure;
  final int eventId;
}

class CandidateProfileCubit extends Cubit<CandidateProfileState> {
  CandidateProfileCubit({
    required LoadCandidate loadCandidate,
    required ListLessons listLessons,
    required String schoolId,
    required String accessToken,
    required String candidateId,
    DateTime? month,
  }) : _loadCandidate = loadCandidate,
       _listLessons = listLessons,
       _schoolId = schoolId,
       _accessToken = accessToken,
       _candidateId = candidateId,
       super(
         CandidateProfileState(
           month: DateTime(
             (month ?? DateTime.now()).year,
             (month ?? DateTime.now()).month,
           ),
         ),
       );
  final LoadCandidate _loadCandidate;
  final ListLessons _listLessons;
  final String _schoolId, _accessToken, _candidateId;
  int _request = 0;

  Future<void> load({DateTime? month}) async {
    if (isClosed) return;
    final request = ++_request;
    final selectedMonth = month == null
        ? state.month
        : DateTime(month.year, month.month);
    final sameMonth = selectedMonth == state.month;
    emit(
      CandidateProfileState(
        month: selectedMonth,
        candidate: state.candidate,
        lessons: sameMonth ? state.lessons : const [],
        loading: true,
        eventId: state.eventId,
      ),
    );
    final candidate = await _loadCandidate(
      schoolId: _schoolId,
      accessToken: _accessToken,
      candidateId: _candidateId,
    );
    if (isClosed || request != _request) return;
    final failure = candidate.resolveWithFailure<Failure?>(
      onFailure: (f) => f,
      onSuccess: (_) => null,
    );
    if (failure != null) {
      _fail(failure);
      return;
    }
    final data = candidate.resolveWithFailure<Candidate?>(
      onFailure: (_) => null,
      onSuccess: (c) => c,
    )!;
    emit(
      CandidateProfileState(
        month: selectedMonth,
        candidate: data,
        lessons: state.lessons,
        loading: true,
        eventId: state.eventId,
      ),
    );
    final lessons = await _listLessons(
      schoolId: _schoolId,
      accessToken: _accessToken,
      filters: LessonFilters(
        from: selectedMonth,
        to: DateTime(selectedMonth.year, selectedMonth.month + 1),
        candidateId: _candidateId,
      ),
    );
    if (isClosed || request != _request) return;
    lessons.resolveWithFailure(
      onFailure: _fail,
      onSuccess: (items) => emit(
        CandidateProfileState(
          month: selectedMonth,
          candidate: data,
          lessons: items.where((l) => l.lessonType == 'DRIVING').toList()
            ..sort((a, b) => b.startAt.compareTo(a.startAt)),
          eventId: state.eventId,
        ),
      ),
    );
  }

  void _fail(Failure failure) {
    final hideData =
        failure.statusCode == 401 ||
        failure.statusCode == 403 ||
        failure.statusCode == 404;
    emit(
      CandidateProfileState(
        month: state.month,
        candidate: hideData ? null : state.candidate,
        lessons: hideData ? const [] : state.lessons,
        failure: failure,
        eventId: state.eventId + 1,
      ),
    );
  }
}
