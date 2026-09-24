import 'dart:async';
import 'package:auto_skola_365_instructor_app/src/core/api/failure.dart';
import 'package:auto_skola_365_instructor_app/src/core/api/result.dart';
import 'package:auto_skola_365_instructor_app/src/features/candidates/data/models/instructor_candidate_model.dart';
import 'package:auto_skola_365_instructor_app/src/features/candidates/domain/entities/instructor_candidate.dart';
import 'package:auto_skola_365_instructor_app/src/features/candidates/domain/repositories/instructor_candidates_repository.dart';
import 'package:auto_skola_365_instructor_app/src/features/candidates/domain/usecases/get_instructor_candidate.dart';
import 'package:auto_skola_365_instructor_app/src/features/candidates/presentation/cubit/candidate_profile_cubit.dart';
import 'package:auto_skola_365_instructor_app/src/features/schedule/data/models/instructor_lesson_model.dart';
import 'package:auto_skola_365_instructor_app/src/features/schedule/domain/entities/instructor_lesson.dart';
import 'package:auto_skola_365_instructor_app/src/features/schedule/domain/repositories/instructor_lessons_repository.dart';
import 'package:auto_skola_365_instructor_app/src/features/schedule/domain/usecases/list_instructor_lessons.dart';
import 'package:auto_skola_365_instructor_app/src/features/schedule/domain/usecases/load_candidate_lessons.dart';
import 'package:auto_skola_365_instructor_app/src/features/schedule/presentation/cubit/daily_schedule_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'src/features/schedule/presentation/cubit/schedule_cubit_test.dart'
    show PendingLessonsRepository;
import 'support/instructor_workflow_fixture.dart';

class CandidateRepository extends Fake
    implements InstructorCandidatesRepository {
  final pending = <Completer<Either<Failure, InstructorCandidate>>>[];
  @override
  FutureEither<InstructorCandidate> get({
    required String schoolId,
    required String accessToken,
    required String candidateId,
  }) {
    final result = Completer<Either<Failure, InstructorCandidate>>();
    pending.add(result);
    return result.future;
  }
}

class HistoryRepository extends Fake implements InstructorLessonsRepository {
  List<InstructorLesson> lessons = [];
  Failure? failure;
  @override
  FutureEither<List<InstructorLesson>> history({
    required String schoolId,
    required String accessToken,
    required String candidateId,
  }) async => failure == null ? Right(lessons) : Left(failure!);
}

void main() {
  late PendingLessonsRepository lessons;
  late DailyScheduleCubit daily;
  final now = DateTime(2026, 9, 23, 12);
  final fixture = WorkflowAdapter()..start = DateTime(2026, 9, 23, 14);
  final next = InstructorLessonModel.fromJson(fixture.lesson).toEntity();
  final candidate = InstructorCandidateModel.fromJson(
    fixture.candidate,
  ).toEntity();
  setUp(() {
    lessons = PendingLessonsRepository();
    daily = DailyScheduleCubit(
      listLessons: ListInstructorLessons(lessons),
      schoolId: 'school',
      accessToken: 'token',
      clock: () => now,
    );
  });
  tearDown(() async {
    if (!daily.isClosed) await daily.close();
  });
  test('daily initial state has no fabricated lessons', () {
    expect(daily.state.loading, isFalse);
    expect(daily.state.lessons, isEmpty);
    expect(daily.state.nextLesson, isNull);
  });
  blocTest<DailyScheduleCubit, DailyScheduleState>(
    'daily refresh failure preserves rows, retry applies new status',
    build: () => daily,
    act: (cubit) async {
      final first = cubit.load();
      lessons.requests[0].complete(Right([next]));
      await first;
      final second = cubit.load();
      lessons.requests[1].complete(
        const Left(Failure('Usluga nije dostupna.', statusCode: 503)),
      );
      await second;
      final third = cubit.load();
      lessons.requests[2].complete(const Right([]));
      await third;
    },
    expect: () => [
      isA<DailyScheduleState>().having((s) => s.loading, 'loading', true),
      isA<DailyScheduleState>().having(
        (s) => s.nextLesson?.id,
        'next',
        'lesson',
      ),
      isA<DailyScheduleState>()
          .having((s) => s.today.length, 'retained', 1)
          .having((s) => s.loading, 'loading', true),
      isA<DailyScheduleState>()
          .having((s) => s.failure?.statusCode, 'failure', 503)
          .having((s) => s.today.length, 'retained', 1),
      isA<DailyScheduleState>().having((s) => s.loading, 'retrying', true),
      isA<DailyScheduleState>()
          .having((s) => s.lessons, 'empty', isEmpty)
          .having((s) => s.failure, 'failure', isNull),
    ],
  );
  test(
    'daily newer load wins and closed cubit ignores pending responses',
    () async {
      final a = daily.load();
      final b = daily.load();
      lessons.requests[1].complete(Right([next]));
      await b;
      lessons.requests[0].complete(const Right([]));
      await a;
      expect(daily.state.nextLesson?.id, 'lesson');
      expect(() => daily.state.lessons.clear(), throwsUnsupportedError);
      final c = daily.load();
      await daily.close();
      lessons.requests[2].complete(const Right([]));
      await c;
    },
  );
  late CandidateRepository candidates;
  late HistoryRepository history;
  late CandidateProfileCubit profile;
  setUp(() {
    candidates = CandidateRepository();
    history = HistoryRepository()..lessons = [next];
    profile = CandidateProfileCubit(
      getCandidate: GetInstructorCandidate(candidates),
      loadLessons: LoadCandidateLessons(history),
      schoolId: 'school',
      accessToken: 'token',
      candidateId: 'candidate',
    );
  });
  tearDown(() async {
    if (!profile.isClosed) await profile.close();
  });
  test('profile initial state has no candidate or history', () {
    expect(profile.state.candidate, isNull);
    expect(profile.state.lessons, isEmpty);
    expect(profile.state.loading, isFalse);
  });
  blocTest<CandidateProfileCubit, CandidateProfileState>(
    'profile retains data on history failure and clears it on revoked assignment',
    build: () => profile,
    act: (cubit) async {
      final a = cubit.load();
      candidates.pending[0].complete(Right(candidate));
      await a;
      history.failure = const Failure(
        'Povijest nije dostupna.',
        statusCode: 503,
      );
      final b = cubit.load();
      candidates.pending[1].complete(Right(candidate));
      await b;
      final c = cubit.load();
      candidates.pending[2].complete(
        const Left(Failure('Pristup nije dopušten.', statusCode: 403)),
      );
      await c;
    },
    expect: () => [
      isA<CandidateProfileState>().having((s) => s.loading, 'loading', true),
      isA<CandidateProfileState>()
          .having((s) => s.candidate?.fullName, 'name', 'Ana Horvat')
          .having((s) => s.lessons.length, 'history', 1),
      isA<CandidateProfileState>().having(
        (s) => s.lessons.length,
        'retained',
        1,
      ),
      isA<CandidateProfileState>()
          .having((s) => s.failure?.statusCode, 'failure', 503)
          .having((s) => s.lessons.length, 'retained', 1),
      isA<CandidateProfileState>().having((s) => s.loading, 'retry', true),
      isA<CandidateProfileState>()
          .having((s) => s.failure?.statusCode, 'failure', 403)
          .having((s) => s.candidate, 'candidate', isNull)
          .having((s) => s.lessons, 'history', isEmpty),
    ],
  );
  test(
    'profile ignores superseded reads and responses after disposal',
    () async {
      final a = profile.load();
      final b = profile.load();
      candidates.pending[1].complete(Right(candidate));
      await b;
      candidates.pending[0].complete(const Left(Failure('old')));
      await a;
      expect(profile.state.candidate?.id, candidate.id);
      expect(profile.state.failure, isNull);
      final c = profile.load();
      await profile.close();
      candidates.pending[2].complete(Right(candidate));
      await c;
    },
  );
}
