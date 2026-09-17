import 'package:bloc/bloc.dart';

import '../../../../core/api/result.dart';
import '../../../../core/api/result_extensions.dart';
import '../../domain/entities/instructor_lesson.dart';
import '../../domain/usecases/cancel_instructor_lesson.dart';
import '../../domain/usecases/confirm_instructor_lesson.dart';
import '../../domain/usecases/complete_instructor_lesson.dart';
import '../../domain/usecases/get_instructor_lesson.dart';
import 'lesson_detail_state.dart';

class LessonDetailCubit extends Cubit<LessonDetailState> {
  LessonDetailCubit({
    required CompleteInstructorLesson completeInstructorLesson,
    required GetInstructorLesson getInstructorLesson,
    required ConfirmInstructorLesson confirmInstructorLesson,
    required CancelInstructorLesson cancelInstructorLesson,
    required String schoolId,
    required String accessToken,
    required String lessonId,
  }) : _completeInstructorLesson = completeInstructorLesson,
       _getInstructorLesson = getInstructorLesson,
       _confirmInstructorLesson = confirmInstructorLesson,
       _cancelInstructorLesson = cancelInstructorLesson,
       _schoolId = schoolId,
       _accessToken = accessToken,
       _lessonId = lessonId,
       super(LessonDetailState.initial());

  final CompleteInstructorLesson _completeInstructorLesson;
  final GetInstructorLesson _getInstructorLesson;
  final ConfirmInstructorLesson _confirmInstructorLesson;
  final CancelInstructorLesson _cancelInstructorLesson;
  final String _schoolId;
  final String _accessToken;
  final String _lessonId;

  int _loadRequestId = 0;

  Future<void> load() async {
    if (isClosed || state.actionInProgress) return;
    final requestId = ++_loadRequestId;
    emit(
      state.copyWith(
        status: LessonDetailStatus.loading,
        errorMessage: null,
        errorStatusCode: null,
      ),
    );

    final result = await _getInstructorLesson(
      schoolId: _schoolId,
      accessToken: _accessToken,
      lessonId: _lessonId,
    );

    if (isClosed || requestId != _loadRequestId) return;

    result.resolveWithFailure(
      onFailure: (failure) {
        emit(
          state.copyWith(
            status: LessonDetailStatus.failure,
            errorMessage: failure.message,
            errorStatusCode: failure.statusCode,
            errorEventId: state.errorEventId + 1,
          ),
        );
      },
      onSuccess: (lesson) {
        emit(
          state.copyWith(
            status: LessonDetailStatus.loaded,
            lesson: lesson,
            errorMessage: null,
            errorStatusCode: null,
          ),
        );
      },
    );
  }

  Future<void> completeLesson(String? note) => _runLessonAction(
    successMessage: 'Sat je označen kao odrađen.',
    action: () => _completeInstructorLesson(
      schoolId: _schoolId,
      accessToken: _accessToken,
      lessonId: _lessonId,
      note: note,
    ),
  );

  Future<void> confirmLesson() {
    return _runLessonAction(
      successMessage: 'Termin je potvrden.',
      action: () => _confirmInstructorLesson(
        schoolId: _schoolId,
        accessToken: _accessToken,
        lessonId: _lessonId,
      ),
    );
  }

  Future<void> cancelLesson() {
    return _runLessonAction(
      successMessage: 'Termin je otkazan.',
      action: () => _cancelInstructorLesson(
        schoolId: _schoolId,
        accessToken: _accessToken,
        lessonId: _lessonId,
      ),
    );
  }

  Future<void> _runLessonAction({
    required String successMessage,
    required FutureEither<InstructorLesson> Function() action,
  }) async {
    if (isClosed || state.actionInProgress) return;
    ++_loadRequestId;
    emit(
      state.copyWith(
        actionInProgress: true,
        errorMessage: null,
        errorStatusCode: null,
      ),
    );

    final result = await action();
    if (isClosed) return;
    result.resolveWithFailure(
      onFailure: (failure) {
        emit(
          state.copyWith(
            status: state.lesson == null
                ? LessonDetailStatus.failure
                : LessonDetailStatus.loaded,
            actionInProgress: false,
            errorMessage: failure.message,
            errorStatusCode: failure.statusCode,
            errorEventId: state.errorEventId + 1,
          ),
        );
      },
      onSuccess: (lesson) {
        emit(
          state.copyWith(
            status: LessonDetailStatus.loaded,
            lesson: lesson,
            actionInProgress: false,
            successMessage: successMessage,
            successEventId: state.successEventId + 1,
            errorMessage: null,
            errorStatusCode: null,
          ),
        );
      },
    );
  }
}
