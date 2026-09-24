import 'package:bloc_test/bloc_test.dart';
import 'package:auto_skola_365_instructor_app/src/features/schedule/presentation/cubit/schedule_state.dart';
import 'package:auto_skola_365_instructor_app/src/features/schedule/domain/entities/reserve_lesson.dart';
import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auto_skola_365_instructor_app/src/core/api/failure.dart';
import 'package:auto_skola_365_instructor_app/src/core/api/result.dart';
import 'package:auto_skola_365_instructor_app/src/features/schedule/domain/entities/instructor_lesson.dart';
import 'package:auto_skola_365_instructor_app/src/features/schedule/domain/entities/instructor_lesson_filters.dart';
import 'package:auto_skola_365_instructor_app/src/features/schedule/domain/repositories/instructor_lessons_repository.dart';
import 'package:auto_skola_365_instructor_app/src/features/schedule/domain/usecases/list_instructor_lessons.dart';
import 'package:auto_skola_365_instructor_app/src/features/schedule/domain/usecases/confirm_instructor_lesson.dart';
import 'package:auto_skola_365_instructor_app/src/features/schedule/domain/usecases/cancel_instructor_lesson.dart';
import 'package:auto_skola_365_instructor_app/src/features/schedule/presentation/cubit/schedule_cubit.dart';

void main() {
  late PendingLessonsRepository repository;
  late ScheduleCubit cubit;

  setUp(() {
    repository = PendingLessonsRepository();
    cubit = ScheduleCubit(
      listInstructorLessons: ListInstructorLessons(repository),
      confirmInstructorLesson: ConfirmInstructorLesson(repository),
      cancelInstructorLesson: CancelInstructorLesson(repository),
      schoolId: 'school',
      accessToken: 'token',
    );
  });
  tearDown(() async {
    if (!cubit.isClosed) await cubit.close();
  });

  test('initial schedule state has no data or active mutation', () {
    expect(cubit.state.status, ScheduleStatus.initial);
    expect(cubit.state.lessons, isEmpty);
    expect(cubit.state.actionLessonId, isNull);
  });
  blocTest<ScheduleCubit, ScheduleState>(
    'confirmation invalidates an older load and always finishes loading',
    build: () => cubit,
    act: (cubit) async {
      final initial = cubit.load();
      repository.requests[0].complete(Right([lesson('one', 'REQUESTED')]));
      await initial;
      final stale = cubit.load();
      final confirm = cubit.confirmLesson('one');
      await cubit.load();
      repository.confirmation.complete(Right(lesson('one', 'CONFIRMED')));
      await confirm;
      repository.requests[1].complete(Right([lesson('one', 'REQUESTED')]));
      await stale;
    },
    expect: () => [
      isA<ScheduleState>().having(
        (s) => s.status,
        'loading',
        ScheduleStatus.loading,
      ),
      isA<ScheduleState>().having(
        (s) => s.lessons.single.status,
        'initial',
        'REQUESTED',
      ),
      isA<ScheduleState>().having(
        (s) => s.status,
        'refreshing',
        ScheduleStatus.loading,
      ),
      isA<ScheduleState>().having((s) => s.actionLessonId, 'action', 'one'),
      isA<ScheduleState>()
          .having((s) => s.status, 'loaded', ScheduleStatus.loaded)
          .having((s) => s.lessons.single.status, 'confirmed', 'CONFIRMED'),
    ],
    verify: (_) {
      expect(repository.confirmCalls, 1);
      expect(repository.requests.length, 2);
    },
  );

  test('a late response cannot overwrite a newer status filter', () async {
    final first = cubit.load();
    final second = cubit.filterStatus('CONFIRMED');
    repository.requests[1].complete(Right([lesson('new', 'CONFIRMED')]));
    await second;
    repository.requests[0].complete(Right([lesson('old', 'REQUESTED')]));
    await first;
    expect(cubit.state.lessons.single.id, 'new');
    expect(cubit.state.filters.status, 'CONFIRMED');
  });

  test(
    'a response after leaving the screen does not emit to a closed cubit',
    () async {
      final pending = cubit.load();
      await cubit.close();
      repository.requests.single.complete(const Right([]));
      await expectLater(pending, completes);
    },
  );

  test(
    'confirm removes a lesson from the requested filter and prevents duplicate requests',
    () async {
      final load = cubit.filterStatus('REQUESTED');
      repository.requests.single.complete(Right([lesson('one', 'REQUESTED')]));
      await load;
      final confirmation = cubit.confirmLesson('one');
      await cubit.confirmLesson('one');
      expect(repository.confirmCalls, 1);
      repository.confirmation.complete(Right(lesson('one', 'CONFIRMED')));
      await confirmation;
      expect(cubit.state.lessons, isEmpty);
      expect(cubit.state.actionLessonId, isNull);
    },
  );

  test(
    'mutation failure retains the lesson and surfaces the backend error',
    () async {
      final load = cubit.load();
      repository.requests.single.complete(Right([lesson('one', 'REQUESTED')]));
      await load;
      final confirmation = cubit.confirmLesson('one');
      repository.confirmation.complete(
        const Left(Failure('Termin se preklapa.', statusCode: 409)),
      );
      await confirmation;
      expect(cubit.state.lessons.single.status, 'REQUESTED');
      expect(cubit.state.errorMessage, 'Termin se preklapa.');
      expect(cubit.state.errorStatusCode, 409);
      expect(cubit.state.actionLessonId, isNull);
    },
  );
}

class PendingLessonsRepository extends Fake
    implements InstructorLessonsRepository {
  @override
  FutureEither<InstructorLesson> reserve({
    required String schoolId,
    required String accessToken,
    required ReserveLesson reservation,
  }) => throw UnimplementedError();

  final requests = <Completer<Either<Failure, List<InstructorLesson>>>>[];
  final confirmation = Completer<Either<Failure, InstructorLesson>>();
  int confirmCalls = 0;

  @override
  FutureEither<List<InstructorLesson>> list({
    required String schoolId,
    required String accessToken,
    required InstructorLessonFilters filters,
  }) {
    final request = Completer<Either<Failure, List<InstructorLesson>>>();
    requests.add(request);
    return request.future;
  }

  @override
  FutureEither<InstructorLesson> complete({
    required String schoolId,
    required String accessToken,
    required String lessonId,
    String? note,
  }) => throw UnimplementedError();

  @override
  FutureEither<InstructorLesson> confirm({
    required String schoolId,
    required String accessToken,
    required String lessonId,
  }) {
    confirmCalls++;
    return confirmation.future;
  }

  @override
  FutureEither<InstructorLesson> get({
    required String schoolId,
    required String accessToken,
    required String lessonId,
  }) => throw UnimplementedError();

  @override
  FutureEither<InstructorLesson> cancel({
    required String schoolId,
    required String accessToken,
    required String lessonId,
  }) => throw UnimplementedError();
}

InstructorLesson lesson(String id, String status) => InstructorLesson(
  id: id,
  schoolId: 'school',
  candidateId: 'candidate',
  candidateName: 'Ana',
  instructorId: 'instructor',
  instructorName: 'Ivan',
  categoryCode: 'B',
  categoryName: 'B',
  branchId: null,
  branchName: null,
  lessonType: 'DRIVING',
  status: status,
  startAt: DateTime(2020, 9, 15, 10),
  endAt: DateTime(2020, 9, 15, 11),
  confirmedAt: null,
  cancelledAt: null,
  notes: null,
  createdByRole: 'ADMIN',
);
