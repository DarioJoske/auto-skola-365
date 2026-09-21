import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:auto_skola_365_admin_app/src/core/api/result.dart';
import 'package:auto_skola_365_admin_app/src/core/api/failure.dart';
import 'package:auto_skola_365_admin_app/src/features/lessons/domain/entities/lesson.dart';
import 'package:auto_skola_365_admin_app/src/features/lessons/domain/entities/lesson_filters.dart';
import 'package:auto_skola_365_admin_app/src/features/lessons/domain/entities/save_lesson.dart';
import 'package:auto_skola_365_admin_app/src/features/lessons/domain/repositories/lessons_repository.dart';
import 'package:auto_skola_365_admin_app/src/features/lessons/domain/usecases/list_lessons.dart';
import 'package:auto_skola_365_admin_app/src/features/lessons/domain/usecases/create_lesson.dart';
import 'package:auto_skola_365_admin_app/src/features/lessons/domain/usecases/update_lesson.dart';
import 'package:auto_skola_365_admin_app/src/features/lessons/domain/usecases/confirm_lesson.dart';
import 'package:auto_skola_365_admin_app/src/features/lessons/domain/usecases/cancel_lesson.dart';
import 'package:auto_skola_365_admin_app/src/features/lessons/presentation/cubit/lessons_cubit.dart';
import 'package:auto_skola_365_admin_app/src/features/lessons/presentation/cubit/lessons_state.dart';
import 'package:auto_skola_365_admin_app/src/features/candidates/domain/usecases/list_candidates.dart';
import 'package:auto_skola_365_admin_app/src/features/instructors/domain/usecases/list_instructors.dart';
import 'overview_schedule_test.dart' show CandidatesLookup, InstructorsLookup;

Lesson lessonFixture({String status = 'CONFIRMED', DateTime? startAt}) =>
    Lesson(
      id: 'lesson',
      schoolId: 'school',
      candidateId: 'Ana',
      candidateName: 'Ana Kandidat',
      instructorId: 'Ivan',
      instructorName: 'Ivan Instruktor',
      categoryCode: 'B',
      categoryName: 'B',
      branchId: null,
      branchName: null,
      lessonType: 'DRIVING',
      status: status,
      startAt: startAt ?? DateTime(2030, 1, 7, 10),
      endAt: (startAt ?? DateTime(2030, 1, 7, 10)).add(
        const Duration(hours: 1),
      ),
      confirmedAt: null,
      cancelledAt: null,
      notes: 'Sačuvaj bilješku',
      createdByRole: 'ADMIN',
    );
final draft = SaveLesson(
  candidateId: 'Ana',
  instructorId: 'Ivan',
  lessonType: 'DRIVING',
  status: 'CONFIRMED',
  startAt: DateTime(2030, 1, 7, 10),
  endAt: DateTime(2030, 1, 7, 11),
  notes: 'Sačuvaj bilješku',
);

class MutationRepository extends Fake implements LessonsRepository {
  Result<Lesson>? mutationResult;
  Completer<Result<Lesson>>? pendingMutation;
  Completer<Result<List<Lesson>>>? pendingLoad;
  bool failRefresh = false;
  int mutations = 0;
  LessonFilters? lastFilters;
  FutureResult<Lesson> mutate() {
    mutations++;
    return pendingMutation?.future ??
        Future.value(mutationResult ?? success(lessonFixture()));
  }

  @override
  FutureResult<List<Lesson>> list({
    required String schoolId,
    required String accessToken,
    required LessonFilters filters,
  }) async {
    lastFilters = filters;
    if (pendingLoad != null) return pendingLoad!.future;
    return failRefresh
        ? failure(const Failure('Osvježavanje nije uspjelo.', statusCode: 503))
        : success([lessonFixture()]);
  }

  @override
  FutureResult<Lesson> create({
    required String schoolId,
    required String accessToken,
    required SaveLesson lesson,
  }) => mutate();
  @override
  FutureResult<Lesson> update({
    required String schoolId,
    required String accessToken,
    required String lessonId,
    required SaveLesson lesson,
  }) => mutate();
  @override
  FutureResult<Lesson> confirm({
    required String schoolId,
    required String accessToken,
    required String lessonId,
  }) => mutate();
  @override
  FutureResult<Lesson> cancel({
    required String schoolId,
    required String accessToken,
    required String lessonId,
  }) => mutate();
}

LessonsCubit mutationCubit(MutationRepository repo) => LessonsCubit(
  listLessons: ListLessons(repo),
  createLesson: CreateLessonUseCase(repo),
  updateLesson: UpdateLessonUseCase(repo),
  confirmLesson: ConfirmLessonUseCase(repo),
  cancelLesson: CancelLessonUseCase(repo),
  listCandidates: ListCandidates(CandidatesLookup()),
  listInstructors: ListInstructors(InstructorsLookup()),
  schoolId: 'school',
  accessToken: 'token',
  initialFilters: LessonFilters(
    from: DateTime(2030, 1, 7),
    to: DateTime(2030, 1, 14),
    instructorId: 'Ivan',
    status: 'CONFIRMED',
  ),
);

void main() {
  late MutationRepository repo;
  setUp(() => repo = MutationRepository());
  test('initial mutation state is idle with no success event', () async {
    final cubit = mutationCubit(repo);
    expect(cubit.state.isSubmitting, false);
    expect(cubit.state.savedEventId, 0);
    await cubit.close();
  });
  for (final action in ['create', 'update', 'confirm', 'cancel']) {
    blocTest<LessonsCubit, LessonsState>(
      '$action reports save before refresh failure and retains data and filters',
      build: () => mutationCubit(repo),
      seed: () => LessonsState(
        status: LessonsStatus.loaded,
        filters: LessonFilters(
          from: DateTime(2030, 1, 7),
          to: DateTime(2030, 1, 14),
          instructorId: 'Ivan',
          status: 'CONFIRMED',
        ),
        lessons: [lessonFixture()],
      ),
      act: (cubit) async {
        repo.failRefresh = true;
        switch (action) {
          case 'create':
            await cubit.create(draft);
          case 'update':
            await cubit.update('lesson', draft);
          case 'confirm':
            await cubit.confirm('lesson');
          case 'cancel':
            await cubit.cancel('lesson');
        }
      },
      expect: () => [
        isA<LessonsState>().having((s) => s.isSubmitting, 'submitting', true),
        isA<LessonsState>()
            .having((s) => s.savedEventId, 'saved', 1)
            .having((s) => s.isSubmitting, 'idle', false),
        isA<LessonsState>().having(
          (s) => s.status,
          'refreshing',
          LessonsStatus.loading,
        ),
        isA<LessonsState>()
            .having((s) => s.status, 'refresh failed', LessonsStatus.failure)
            .having((s) => s.lessons.length, 'preserved data', 1)
            .having((s) => s.isSubmitting, 'not stuck', false)
            .having((s) => s.filters.instructorId, 'preserved filter', 'Ivan'),
      ],
    );
  }
  blocTest<LessonsCubit, LessonsState>(
    'repeated conflicts are visible and retry can save',
    build: () => mutationCubit(repo),
    act: (cubit) async {
      repo.mutationResult = failure(
        const Failure('Instruktor već ima termin.', statusCode: 409),
      );
      await cubit.create(draft);
      await cubit.create(draft);
      repo.mutationResult = success(lessonFixture());
      await cubit.create(draft);
    },
    expect: () => [
      isA<LessonsState>().having((s) => s.isSubmitting, 'submitting', true),
      isA<LessonsState>()
          .having((s) => s.errorEventId, 'error', 1)
          .having((s) => s.errorStatusCode, 'conflict', 409),
      isA<LessonsState>().having((s) => s.isSubmitting, 'retry', true),
      isA<LessonsState>().having((s) => s.errorEventId, 'repeat error', 2),
      isA<LessonsState>().having((s) => s.isSubmitting, 'retry', true),
      isA<LessonsState>().having((s) => s.savedEventId, 'saved', 1),
      isA<LessonsState>().having(
        (s) => s.status,
        'refresh',
        LessonsStatus.loading,
      ),
      isA<LessonsState>()
          .having((s) => s.status, 'loaded', LessonsStatus.loaded)
          .having((s) => s.savedEventId, 'retained success', 1),
    ],
  );
  test(
    'duplicate submissions and late reads cannot replace a mutation failure',
    () async {
      final cubit = mutationCubit(repo);
      repo.pendingLoad = Completer();
      final oldLoad = cubit.load();
      repo.pendingMutation = Completer();
      final save = cubit.create(draft);
      await cubit.create(draft);
      expect(repo.mutations, 1);
      repo.pendingMutation!.complete(
        failure(const Failure('Konflikt', statusCode: 409)),
      );
      await save;
      repo.pendingLoad!.complete(success([]));
      await oldLoad;
      expect(cubit.state.errorMessage, 'Konflikt');
      expect(cubit.state.isSubmitting, false);
      await cubit.close();
    },
  );
  test('closing during a save safely ignores the response', () async {
    final cubit = mutationCubit(repo);
    repo.pendingMutation = Completer();
    final save = cubit.create(draft);
    await cubit.close();
    repo.pendingMutation!.complete(success(lessonFixture()));
    await save;
  });
}
