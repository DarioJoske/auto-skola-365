import 'package:bloc/bloc.dart';

import '../../../../core/api/result.dart';
import '../../../../core/api/result_extensions.dart';
import '../../domain/entities/instructor_lesson.dart';
import '../../domain/entities/instructor_lesson_filters.dart';
import '../../domain/usecases/cancel_instructor_lesson.dart';
import '../../domain/usecases/confirm_instructor_lesson.dart';
import '../../domain/usecases/list_instructor_lessons.dart';
import 'schedule_state.dart';

class ScheduleCubit extends Cubit<ScheduleState> {
  ScheduleCubit({
    required ListInstructorLessons listInstructorLessons,
    required ConfirmInstructorLesson confirmInstructorLesson,
    required CancelInstructorLesson cancelInstructorLesson,
    required String schoolId,
    required String accessToken,
  }) : _listInstructorLessons = listInstructorLessons,
       _confirmInstructorLesson = confirmInstructorLesson,
       _cancelInstructorLesson = cancelInstructorLesson,
       _schoolId = schoolId,
       _accessToken = accessToken,
       super(ScheduleState.initial());

  final ListInstructorLessons _listInstructorLessons;
  final ConfirmInstructorLesson _confirmInstructorLesson;
  final CancelInstructorLesson _cancelInstructorLesson;
  final String _schoolId;
  final String _accessToken;

  int _loadRequestId = 0;

  Future<void> load() async {
    if (isClosed || state.actionLessonId != null) return;
    final requestId = ++_loadRequestId;
    emit(
      state.copyWith(
        status: ScheduleStatus.loading,
        errorMessage: null,
        errorStatusCode: null,
      ),
    );

    final result = await _listInstructorLessons(
      schoolId: _schoolId,
      accessToken: _accessToken,
      filters: state.filters,
    );

    if (isClosed || requestId != _loadRequestId) return;

    result.resolveWithFailure(
      onFailure: (failure) {
        emit(
          state.copyWith(
            status: ScheduleStatus.failure,
            lessons: [401, 403].contains(failure.statusCode)
                ? const []
                : state.lessons,
            errorMessage: failure.message,
            errorStatusCode: failure.statusCode,
            errorEventId: state.errorEventId + 1,
          ),
        );
      },
      onSuccess: (lessons) {
        final sorted = [...lessons]
          ..sort((a, b) => a.startAt.compareTo(b.startAt));
        emit(
          state.copyWith(
            status: ScheduleStatus.loaded,
            lessons: List.unmodifiable(sorted),
            errorMessage: null,
            errorStatusCode: null,
          ),
        );
      },
    );
  }

  Future<void> selectDate(DateTime date) async {
    final selectedDate = DateTime(date.year, date.month, date.day);
    emit(
      state.copyWith(
        selectedDate: selectedDate,
        filters: _filtersFor(selectedDate, state.rangeMode),
      ),
    );
    await load();
  }

  Future<void> moveByDays(int days) {
    final step = state.rangeMode == ScheduleRangeMode.week ? days * 7 : days;
    final date = state.selectedDate;
    return selectDate(DateTime(date.year, date.month, date.day + step));
  }

  Future<void> setRangeMode(ScheduleRangeMode rangeMode) async {
    if (state.rangeMode == rangeMode) {
      return;
    }

    emit(
      state.copyWith(
        rangeMode: rangeMode,
        filters: _filtersFor(state.selectedDate, rangeMode),
      ),
    );
    await load();
  }

  Future<void> filterStatus(String? status) async {
    emit(
      state.copyWith(
        filters: state.filters.copyWith(
          status: status,
          clearStatus: status == null,
        ),
      ),
    );
    await load();
  }

  Future<void> confirmLesson(String lessonId) {
    return _runLessonAction(
      lessonId: lessonId,
      successMessage: 'Termin je potvrden.',
      action: () => _confirmInstructorLesson(
        schoolId: _schoolId,
        accessToken: _accessToken,
        lessonId: lessonId,
      ),
    );
  }

  Future<void> cancelLesson(String lessonId) {
    return _runLessonAction(
      lessonId: lessonId,
      successMessage: 'Termin je otkazan.',
      action: () => _cancelInstructorLesson(
        schoolId: _schoolId,
        accessToken: _accessToken,
        lessonId: lessonId,
      ),
    );
  }

  Future<void> _runLessonAction({
    required String lessonId,
    required String successMessage,
    required FutureEither<InstructorLesson> Function() action,
  }) async {
    if (isClosed || state.actionLessonId != null) return;
    ++_loadRequestId;
    emit(
      state.copyWith(
        actionLessonId: lessonId,
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
            status: ScheduleStatus.loaded,
            clearActionLessonId: true,
            lessons: [401, 403].contains(failure.statusCode)
                ? const []
                : state.lessons,
            errorMessage: failure.message,
            errorStatusCode: failure.statusCode,
            errorEventId: state.errorEventId + 1,
          ),
        );
      },
      onSuccess: (lesson) {
        final lessons = _replaceLesson(state.lessons, lesson);
        emit(
          state.copyWith(
            lessons: lessons,
            status: ScheduleStatus.loaded,
            clearActionLessonId: true,
            successMessage: successMessage,
            successEventId: state.successEventId + 1,
            errorMessage: null,
            errorStatusCode: null,
          ),
        );
      },
    );
  }

  List<InstructorLesson> _replaceLesson(
    List<InstructorLesson> lessons,
    InstructorLesson updated,
  ) {
    final next = [
      for (final lesson in lessons)
        if (lesson.id == updated.id) updated else lesson,
    ]..sort((a, b) => a.startAt.compareTo(b.startAt));

    return List.unmodifiable(
      next
          .where(
            (lesson) =>
                state.filters.status == null ||
                lesson.status == state.filters.status,
          )
          .toList(),
    );
  }

  InstructorLessonFilters _filtersFor(
    DateTime selectedDate,
    ScheduleRangeMode rangeMode,
  ) {
    final from = switch (rangeMode) {
      ScheduleRangeMode.day => selectedDate,
      ScheduleRangeMode.week => DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day - selectedDate.weekday + DateTime.monday,
      ),
    };
    final to = switch (rangeMode) {
      ScheduleRangeMode.day => DateTime(from.year, from.month, from.day + 1),
      ScheduleRangeMode.week => DateTime(from.year, from.month, from.day + 7),
    };

    return state.filters.copyWith(from: from, to: to);
  }
}
