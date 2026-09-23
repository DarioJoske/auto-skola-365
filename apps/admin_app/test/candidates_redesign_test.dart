import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auto_skola_365_admin_app/src/core/api/result.dart';
import 'package:auto_skola_365_admin_app/src/core/api/failure.dart';
import 'package:auto_skola_365_admin_app/src/features/candidates/domain/entities/candidate.dart';
import 'package:auto_skola_365_admin_app/src/features/candidates/domain/entities/candidate_filters.dart';
import 'package:auto_skola_365_admin_app/src/features/candidates/domain/entities/create_candidate.dart';
import 'package:auto_skola_365_admin_app/src/features/candidates/domain/entities/update_candidate.dart';
import 'package:auto_skola_365_admin_app/src/features/candidates/domain/repositories/candidates_repository.dart';
import 'package:auto_skola_365_admin_app/src/features/candidates/domain/usecases/create_candidate.dart';
import 'package:auto_skola_365_admin_app/src/features/candidates/domain/usecases/update_candidate.dart';
import 'package:auto_skola_365_admin_app/src/features/candidates/domain/usecases/load_candidate.dart';
import 'package:auto_skola_365_admin_app/src/features/candidates/domain/usecases/list_candidates.dart';
import 'package:auto_skola_365_admin_app/src/features/candidates/presentation/cubit/candidates_cubit.dart';
import 'package:auto_skola_365_admin_app/src/features/candidates/presentation/cubit/candidates_state.dart';
import 'package:auto_skola_365_admin_app/src/features/candidates/presentation/cubit/candidate_profile_cubit.dart';
import 'package:auto_skola_365_admin_app/src/features/instructors/domain/usecases/list_instructors.dart';
import 'package:auto_skola_365_admin_app/src/features/lessons/domain/usecases/list_lessons.dart';
import 'package:auto_skola_365_admin_app/src/features/lessons/domain/entities/lesson.dart';
import 'overview_schedule_test.dart' show InstructorsLookup, ScheduleRepository;
import 'lesson_mutations_test.dart' show lessonFixture;

Candidate candidateFixture({
  String id = 'Ana',
  int? completed = 37,
  int? target = 35,
}) => Candidate(
  id: id,
  schoolId: 'school',
  firstName: id,
  lastName: 'Horvat',
  email: 'kontakt@example.com',
  phone: '+385 91 555 0100',
  oib: null,
  status: 'IN_DRIVING',
  categoryCode: 'B',
  categoryName: 'B',
  assignedInstructorId: 'Ivan',
  assignedInstructorName: 'Ivan Ivić',
  notes: 'Interna napomena',
  requiredDrivingHours: target,
  completedDrivingHours: completed,
  hasLogin: true,
  loginEmail: 'prijava@example.com',
);
final candidateDraft = CreateCandidate(
  firstName: 'Ana',
  lastName: 'Horvat',
  email: null,
  phone: null,
  oib: null,
  status: 'ENROLLED',
  categoryCode: 'B',
  assignedInstructorId: null,
  notes: null,
  requiredDrivingHours: 35,
);

class CandidateRepositoryFake extends Fake implements CandidatesRepository {
  Failure? loadFailure;
  Failure? saveFailure;
  Completer<Result<Candidate>>? pendingSave;
  final pendingLists = <Completer<Result<List<Candidate>>>>[];
  bool delayLists = false;
  int saves = 0;
  CreateCandidate? created;
  UpdateCandidate? updated;
  @override
  FutureResult<Candidate> get({
    required String schoolId,
    required String accessToken,
    required String candidateId,
  }) async => loadFailure == null
      ? success(candidateFixture(id: candidateId))
      : failure(loadFailure!);
  @override
  FutureResult<List<Candidate>> list({
    required String schoolId,
    required String accessToken,
    CandidateFilters filters = const CandidateFilters(),
  }) async {
    if (delayLists) {
      final pending = Completer<Result<List<Candidate>>>();
      pendingLists.add(pending);
      return pending.future;
    }
    return loadFailure == null
        ? success([candidateFixture()])
        : failure(loadFailure!);
  }

  FutureResult<Candidate> _save() async {
    saves++;
    return pendingSave?.future ??
        (saveFailure == null
            ? success(candidateFixture())
            : failure(saveFailure!));
  }

  @override
  FutureResult<Candidate> create({
    required String schoolId,
    required String accessToken,
    required CreateCandidate candidate,
  }) {
    created = candidate;
    return _save();
  }

  @override
  FutureResult<Candidate> update({
    required String schoolId,
    required String accessToken,
    required String candidateId,
    required UpdateCandidate candidate,
  }) {
    updated = candidate;
    return _save();
  }
}

CandidatesCubit candidatesCubit(CandidateRepositoryFake repo) =>
    CandidatesCubit(
      listCandidates: ListCandidates(repo),
      listInstructors: ListInstructors(InstructorsLookup()),
      createCandidate: CreateCandidateUseCase(repo),
      updateCandidate: UpdateCandidateUseCase(repo),
      schoolId: 'school',
      accessToken: 'token',
    );
CandidateProfileCubit profileCubit(
  CandidateRepositoryFake repo,
  ScheduleRepository lessons,
) => CandidateProfileCubit(
  loadCandidate: LoadCandidate(repo),
  listLessons: ListLessons(lessons),
  schoolId: 'school',
  accessToken: 'token',
  candidateId: 'Ana',
  month: DateTime(2030, 1),
);

void main() {
  late CandidateRepositoryFake repo;
  setUp(() => repo = CandidateRepositoryFake());
  test('candidate list and profile start idle without invented data', () async {
    final cubit = candidatesCubit(repo);
    final profile = profileCubit(repo, ScheduleRepository());
    expect(cubit.state.status, CandidatesStatus.initial);
    expect(cubit.state.savedCandidate, isNull);
    expect(cubit.state.isSubmitting, isFalse);
    expect(profile.state.candidate, isNull);
    expect(profile.state.lessons, isEmpty);
    expect(profile.state.loading, isFalse);
    await cubit.close();
    await profile.close();
  });
  blocTest<CandidatesCubit, CandidatesState>(
    'save failure keeps results and retry emits one success',
    build: () => candidatesCubit(repo),
    seed: () => CandidatesState(
      status: CandidatesStatus.loaded,
      candidates: [candidateFixture()],
      filters: const CandidateFilters(query: 'Ana'),
    ),
    act: (cubit) async {
      repo.saveFailure = const Failure('OIB već postoji.', statusCode: 409);
      await cubit.create(candidateDraft);
      repo.saveFailure = null;
      await cubit.create(candidateDraft);
    },
    expect: () => [
      isA<CandidatesState>().having((s) => s.isSubmitting, 'saving', true),
      isA<CandidatesState>()
          .having((s) => s.errorMessage, 'error', 'OIB već postoji.')
          .having((s) => s.candidates.length, 'retained', 1)
          .having((s) => s.isSubmitting, 'retry enabled', false),
      isA<CandidatesState>().having(
        (s) => s.errorMessage,
        'error cleared',
        null,
      ),
      isA<CandidatesState>()
          .having((s) => s.savedCandidate?.id, 'saved', 'Ana')
          .having((s) => s.saveEventId, 'one effect', 1)
          .having((s) => s.filters.query, 'filter', 'Ana'),
    ],
  );
  blocTest<CandidatesCubit, CandidatesState>(
    'latest filter response wins',
    build: () => candidatesCubit(repo),
    act: (cubit) async {
      repo.delayLists = true;
      final old = cubit.load();
      final latest = cubit.applyFilters(const CandidateFilters(query: 'Mia'));
      repo.pendingLists[1].complete(success([candidateFixture(id: 'Mia')]));
      await latest;
      repo.pendingLists[0].complete(failure(const Failure('Old failure')));
      await old;
    },
    expect: () => [
      isA<CandidatesState>().having(
        (s) => s.status,
        'loading',
        CandidatesStatus.loading,
      ),
      isA<CandidatesState>().having((s) => s.filters.query, 'query', 'Mia'),
      isA<CandidatesState>().having(
        (s) => s.status,
        'loading',
        CandidatesStatus.loading,
      ),
      isA<CandidatesState>()
          .having((s) => s.candidates.single.id, 'latest', 'Mia')
          .having((s) => s.errorMessage, 'no old failure', null),
    ],
  );
  blocTest<CandidatesCubit, CandidatesState>(
    'refresh failure retains list and retry recovers',
    build: () => candidatesCubit(repo),
    seed: () => CandidatesState(
      status: CandidatesStatus.loaded,
      candidates: [candidateFixture()],
    ),
    act: (cubit) async {
      repo.loadFailure = const Failure('Nema veze.');
      await cubit.load();
      repo.loadFailure = null;
      await cubit.load();
    },
    expect: () => [
      isA<CandidatesState>().having(
        (s) => s.candidates.length,
        'retained while loading',
        1,
      ),
      isA<CandidatesState>()
          .having((s) => s.status, 'failed', CandidatesStatus.failure)
          .having((s) => s.candidates.length, 'retained on failure', 1),
      isA<CandidatesState>().having(
        (s) => s.status,
        'retry',
        CandidatesStatus.loading,
      ),
      isA<CandidatesState>().having(
        (s) => s.status,
        'recovered',
        CandidatesStatus.loaded,
      ),
    ],
  );
  test('duplicate saves ignored and closure during request is safe', () async {
    final cubit = candidatesCubit(repo);
    repo.pendingSave = Completer();
    final save = cubit.create(candidateDraft);
    await cubit.create(candidateDraft);
    expect(repo.saves, 1);
    await cubit.close();
    repo.pendingSave!.complete(success(candidateFixture()));
    await save;
  });
  test('stale list cannot overwrite save', () async {
    final cubit = candidatesCubit(repo);
    repo.delayLists = true;
    final load = cubit.load();
    await cubit.create(candidateDraft);
    repo.pendingLists.single.complete(failure(const Failure('Old')));
    await load;
    expect(cubit.state.saveEventId, 1);
    expect(cubit.state.errorMessage, isNull);
    await cubit.close();
  });
  blocTest<CandidateProfileCubit, CandidateProfileState>(
    'profile renders backend hours and monthly history',
    build: () => profileCubit(repo, lessons = ScheduleRepository()),
    act: (cubit) async {
      final load = cubit.load();
      await Future<void>.delayed(Duration.zero);
      lessons.requests.single.complete(
        success([lessonFixture(status: 'COMPLETED')]),
      );
      await load;
    },
    expect: () => [
      isA<CandidateProfileState>().having((s) => s.loading, 'loading', true),
      isA<CandidateProfileState>().having(
        (s) => s.candidate?.completedDrivingHours,
        'actual total',
        37,
      ),
      isA<CandidateProfileState>()
          .having((s) => s.lessons.length, 'history', 1)
          .having((s) => s.loading, 'loaded', false),
    ],
    verify: (cubit) {
      expect(lessons.filters.single.candidateId, 'Ana');
      expect(lessons.filters.single.from, DateTime(2030, 1));
      expect(lessons.filters.single.to, DateTime(2030, 2));
      expect(() => cubit.state.lessons.clear(), throwsUnsupportedError);
    },
  );
  test(
    'month switch drops stale history response and retains current on retry failure',
    () async {
      final history = ScheduleRepository();
      final cubit = profileCubit(repo, history);
      final old = cubit.load();
      await Future<void>.delayed(Duration.zero);
      final current = cubit.load(month: DateTime(2030, 2));
      await Future<void>.delayed(Duration.zero);
      history.requests[1].complete(
        success([lessonFixture(startAt: DateTime(2030, 2, 7))]),
      );
      await current;
      history.requests[0].complete(
        failure(const Failure('Old history failure')),
      );
      await old;
      expect(cubit.state.month, DateTime(2030, 2));
      expect(cubit.state.lessons.single.startAt, DateTime(2030, 2, 7));
      expect(cubit.state.failure, isNull);
      final retry = cubit.load();
      await Future<void>.delayed(Duration.zero);
      history.requests[2].complete(
        failure(const Failure('History unavailable')),
      );
      await retry;
      expect(cubit.state.lessons.length, 1);
      expect(cubit.state.candidate?.completedDrivingHours, 37);
      expect(cubit.state.failure?.message, 'History unavailable');
      repo.loadFailure = const Failure('Forbidden', statusCode: 403);
      await cubit.load();
      expect(cubit.state.candidate, isNull);
      expect(cubit.state.lessons, isEmpty);
      await cubit.close();
    },
  );
  test('profile closing during history request emits nothing late', () async {
    final history = ScheduleRepository();
    final cubit = profileCubit(repo, history);
    final load = cubit.load();
    await Future<void>.delayed(Duration.zero);
    await cubit.close();
    history.requests.single.complete(success(<Lesson>[]));
    await load;
  });
}

late ScheduleRepository lessons;
