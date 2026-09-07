import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/api/failure.dart';
import '../../../../core/api/result.dart';
import '../../../../core/api/result_extensions.dart';
import '../../../candidates/domain/entities/candidate_filters.dart';
import '../../../candidates/domain/usecases/list_candidates.dart';
import '../../../instructors/domain/entities/instructor_filters.dart';
import '../../../instructors/domain/usecases/list_instructors.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/entities/save_lesson.dart';
import '../../domain/usecases/cancel_lesson.dart';
import '../../domain/usecases/confirm_lesson.dart';
import '../../domain/usecases/create_lesson.dart';
import '../../domain/usecases/list_lessons.dart';
import '../../domain/usecases/update_lesson.dart';
import 'lessons_state.dart';

class LessonsCubit extends Cubit<LessonsState> {
  LessonsCubit({
    required ListLessons listLessons,
    required CreateLessonUseCase createLesson,
    required UpdateLessonUseCase updateLesson,
    required ConfirmLessonUseCase confirmLesson,
    required CancelLessonUseCase cancelLesson,
    required ListCandidates listCandidates,
    required ListInstructors listInstructors,
    required String schoolId,
    required String accessToken,
  }) : _listLessons = listLessons,
       _createLesson = createLesson,
       _updateLesson = updateLesson,
       _confirmLesson = confirmLesson,
       _cancelLesson = cancelLesson,
       _listCandidates = listCandidates,
       _listInstructors = listInstructors,
       _schoolId = schoolId,
       _accessToken = accessToken,
       super(LessonsState.initial());

  final ListLessons _listLessons;
  final CreateLessonUseCase _createLesson;
  final UpdateLessonUseCase _updateLesson;
  final ConfirmLessonUseCase _confirmLesson;
  final CancelLessonUseCase _cancelLesson;
  final ListCandidates _listCandidates;
  final ListInstructors _listInstructors;
  final String _schoolId;
  final String _accessToken;

  Future<void> load() async {
    emit(
      state.copyWith(
        status: LessonsStatus.loading,
        errorMessage: null,
        errorStatusCode: null,
      ),
    );

    final lessonsResult = await _listLessons(
      schoolId: _schoolId,
      accessToken: _accessToken,
      filters: state.filters,
    );
    final candidatesResult = await _listCandidates(
      schoolId: _schoolId,
      accessToken: _accessToken,
      filters: const CandidateFilters(),
    );
    final instructorsResult = await _listInstructors(
      schoolId: _schoolId,
      accessToken: _accessToken,
      filters: const InstructorFilters(active: true),
    );

    final failure =
        lessonsResult.resolveWithFailure<Failure?>(
          onFailure: (failure) => failure,
          onSuccess: (_) => null,
        ) ??
        candidatesResult.resolveWithFailure<Failure?>(
          onFailure: (failure) => failure,
          onSuccess: (_) => null,
        ) ??
        instructorsResult.resolveWithFailure<Failure?>(
          onFailure: (failure) => failure,
          onSuccess: (_) => null,
        );
    if (failure != null) {
      emit(
        state.copyWith(
          status: LessonsStatus.failure,
          errorMessage: failure.message,
          errorStatusCode: failure.statusCode,
          errorEventId: state.errorEventId + 1,
        ),
      );
      return;
    }

    emit(
      LessonsState(
        status: LessonsStatus.loaded,
        filters: state.filters,
        lessons: lessonsResult.resolveWithFailure(
          onFailure: (_) => const <Lesson>[],
          onSuccess: (lessons) => lessons,
        ),
        candidates: candidatesResult.resolveWithFailure(
          onFailure: (_) => const [],
          onSuccess: (candidates) => candidates,
        ),
        instructors: instructorsResult.resolveWithFailure(
          onFailure: (_) => const [],
          onSuccess: (instructors) => instructors,
        ),
      ),
    );
  }

  Future<void> changeRange(DateTime from, DateTime to) async {
    emit(
      state.copyWith(
        filters: state.filters.copyWith(from: from, to: to),
      ),
    );
    await load();
  }

  Future<void> filterInstructor(String? instructorId) async {
    emit(
      state.copyWith(
        filters: state.filters.copyWith(
          instructorId: instructorId,
          clearInstructor: instructorId == null,
        ),
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

  Future<bool> create(SaveLesson lesson) async {
    emit(
      state.copyWith(
        isSubmitting: true,
        errorMessage: null,
        errorStatusCode: null,
      ),
    );
    final result = await _createLesson(
      schoolId: _schoolId,
      accessToken: _accessToken,
      lesson: lesson,
    );

    return _resolveMutation(result);
  }

  Future<bool> update(String lessonId, SaveLesson lesson) async {
    emit(
      state.copyWith(
        isSubmitting: true,
        errorMessage: null,
        errorStatusCode: null,
      ),
    );
    final result = await _updateLesson(
      schoolId: _schoolId,
      accessToken: _accessToken,
      lessonId: lessonId,
      lesson: lesson,
    );

    return _resolveMutation(result);
  }

  Future<bool> confirm(String lessonId) async {
    emit(
      state.copyWith(
        isSubmitting: true,
        errorMessage: null,
        errorStatusCode: null,
      ),
    );
    final result = await _confirmLesson(
      schoolId: _schoolId,
      accessToken: _accessToken,
      lessonId: lessonId,
    );

    return _resolveMutation(result);
  }

  Future<bool> cancel(String lessonId) async {
    emit(
      state.copyWith(
        isSubmitting: true,
        errorMessage: null,
        errorStatusCode: null,
      ),
    );
    final result = await _cancelLesson(
      schoolId: _schoolId,
      accessToken: _accessToken,
      lessonId: lessonId,
    );

    return _resolveMutation(result);
  }

  Future<bool> _resolveMutation(Result<Lesson> result) async {
    return result.resolveWithFailure(
      onFailure: (failure) {
        emit(
          state.copyWith(
            isSubmitting: false,
            errorMessage: failure.message,
            errorStatusCode: failure.statusCode,
            errorEventId: state.errorEventId + 1,
          ),
        );
        return false;
      },
      onSuccess: (_) async {
        await load();
        return true;
      },
    );
  }
}
