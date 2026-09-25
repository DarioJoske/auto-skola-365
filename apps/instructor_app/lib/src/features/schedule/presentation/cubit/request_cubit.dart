import 'package:bloc/bloc.dart';
import '../../../../core/api/result_extensions.dart';
import '../../domain/usecases/get_instructor_lesson.dart';
import '../../domain/usecases/decide_request.dart';
import 'lesson_detail_state.dart';

class RequestCubit extends Cubit<LessonDetailState> {
  RequestCubit({
    required GetInstructorLesson load,
    required DecideRequest decide,
    required String schoolId,
    required String accessToken,
    required String lessonId,
  }) : _load = load,
       _decide = decide,
       _schoolId = schoolId,
       _accessToken = accessToken,
       _lessonId = lessonId,
       super(LessonDetailState.initial());
  final GetInstructorLesson _load;
  final DecideRequest _decide;
  final String _schoolId, _accessToken, _lessonId;
  int _generation = 0;
  Future<void> load() async {
    if (isClosed || state.actionInProgress) return;
    final generation = ++_generation;
    emit(
      state.copyWith(
        status: LessonDetailStatus.loading,
        errorMessage: null,
        successMessage: null,
      ),
    );
    final result = await _load(
      schoolId: _schoolId,
      accessToken: _accessToken,
      lessonId: _lessonId,
    );
    if (isClosed || generation != _generation) return;
    result.resolveWithFailure(
      onFailure: (f) => emit(
        state.copyWith(
          status: LessonDetailStatus.failure,
          clearLesson: [401, 403, 404].contains(f.statusCode),
          errorMessage: f.message,
          errorStatusCode: f.statusCode,
          errorEventId: state.errorEventId + 1,
        ),
      ),
      onSuccess: (lesson) => emit(
        state.copyWith(
          status: LessonDetailStatus.loaded,
          lesson: lesson,
          errorMessage: null,
          errorStatusCode: null,
        ),
      ),
    );
  }

  Future<void> decide(RequestDecision decision, {DateTime? startAt}) async {
    if (isClosed ||
        state.actionInProgress ||
        state.lesson?.status != 'REQUESTED') {
      return;
    }
    ++_generation;
    emit(
      state.copyWith(
        actionInProgress: true,
        errorMessage: null,
        successMessage: null,
      ),
    );
    final result = await _decide(
      schoolId: _schoolId,
      accessToken: _accessToken,
      lessonId: _lessonId,
      decision: decision,
      startAt: startAt,
    );
    if (isClosed) return;
    result.resolveWithFailure(
      onFailure: (f) => emit(
        state.copyWith(
          status: LessonDetailStatus.loaded,
          actionInProgress: false,
          errorMessage: f.message,
          errorStatusCode: f.statusCode,
          errorEventId: state.errorEventId + 1,
        ),
      ),
      onSuccess: (lesson) => emit(
        state.copyWith(
          status: LessonDetailStatus.loaded,
          lesson: lesson,
          actionInProgress: false,
          errorStatusCode: null,
          successEventId: state.successEventId + 1,
          successMessage: switch (decision) {
            RequestDecision.confirm => 'Termin je potvrđen.',
            RequestDecision.reject => 'Zahtjev je odbijen.',
            RequestDecision.propose => 'Prijedlog čeka odgovor kandidata.',
          },
        ),
      ),
    );
  }
}
